---
title: "7. Sécurité : permissions, secrets, épinglage, OIDC"
description: GITHUB_TOKEN au moindre privilège, ce que le masquage fait et ne fait pas, actions épinglées sur un SHA de commit, tokens OIDC au lieu de secrets cloud, et une injection de script exécutée pour de vrai.
sidebar:
  order: 7
---

## Ce qu'un workflow peut faire

Un workflow exécute du code — le tien et celui des actions — avec un token qui peut agir sur le dépôt, parfois des secrets, et parfois des identifiants cloud. Quatre questions structurent cette leçon :

| Question | Outil | Azure Pipelines |
|---|---|---|
| Que peut faire le token automatique ? | `permissions:` | portée d'autorisation des jobs, permissions du projet |
| Où vont les secrets, et qui les voit ? | `secrets`, masquage | variables secrètes, groupes de variables |
| L'action que j'exécute est-elle celle que j'ai relue ? | épinglage sur un SHA de commit | versions des tâches |
| Comment atteindre un cloud sans mot de passe stocké ? | OpenID Connect (`id-token: write`) | connexions de service par fédération d'identité de charge de travail |

Tout ce qui suit vient de [`.github/workflows/gha-07-security.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-07-security.yml). Ses premières lignes :

```yaml
permissions:
  contents: read
```

## Permissions du `GITHUB_TOKEN`

Chaque job reçoit un `GITHUB_TOKEN`, valable pour ce job seulement. Ses permissions par défaut dépendent d'un paramètre du dépôt (ou de l'organisation) ; le step *Set up job* de chaque exécution de la [leçon 1](../01-first-workflow/) les a listées pour ce dépôt : `Contents: read`, `Metadata: read`, `Packages: read`. Ne compte pas sur ce paramètre : déclare ce dont le workflow a besoin, comme ci-dessus, et ajoute le reste par job.

Deux jobs appellent la même API — créer une étiquette au nom **vide**, pour que rien ne puisse être créé — l'un sans `issues: write`, l'autre avec :

```yaml
  token-with-issues-write:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
    steps:
      - name: Create a label with an empty name, token with issues:write
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh api --method POST "repos/$GITHUB_REPOSITORY/labels" -f name= || echo "gh exit code: $?"
```

```text
token-without-issues-write | Contents: read
token-without-issues-write | Metadata: read
token-without-issues-write | gh: Resource not accessible by integration (HTTP 403)

token-with-issues-write    | Contents: read
token-with-issues-write    | Issues: write
token-with-issues-write    | Metadata: read
token-with-issues-write    | gh: Validation Failed (HTTP 422)
```

- 403, *Resource not accessible by integration* : le token n'a pas le droit. C'est le message à reconnaître quand il manque soudain une permission à un workflow.
- 422, *Validation Failed* : la permission a été accordée, seule la requête était fausse.
- Ma première tentative utilisait `gh run list`, qui demande `actions: read`, depuis un job avec seulement `contents: read`. Elle a **fonctionné** : sur un dépôt public, lire des données publiques ne demande pas la permission. Teste les permissions avec un appel en écriture.

La règle à retenir, d'après la référence de la syntaxe des workflows : « Si tu spécifies l'accès pour l'une de ces permissions, toutes celles qui ne sont pas spécifiées sont définies à `none` » — exercice 1.

## Secrets et masquage

Les secrets sont stockés dans les paramètres du dépôt, de l'environnement ou de l'organisation, et se lisent avec `${{ secrets.NAME }}`. La [leçon 4](../04-expressions-and-outputs/) a montré que leurs valeurs sont remplacées par `***` dans les logs. Deux faits de plus, testés dans le job `masking` :

```text
echo "value=''"
value=''
```

Un secret qui n'existe pas est une **chaîne vide**, sans erreur ni avertissement — « Si un secret n'a pas été défini, la valeur de retour d'une expression qui référence ce secret … sera une chaîne vide ». Une faute de frappe dans le nom d'un secret produit un job qui tourne avec un mot de passe vide ; vérifie-le au début du job (`test -n "$TOKEN"`).

Une valeur **dérivée** d'un secret n'est pas masquée. Enregistre-la avec la commande de workflow `add-mask` :

```text
before add-mask: 849f6dc993e40726
after add-mask:  ***
```

La première ligne est déjà dans le log pour de bon : le masquage ne s'applique qu'à ce qui est affiché après la commande.

Et les forks : « À l'exception du `GITHUB_TOKEN`, les secrets ne sont pas transmis au runner quand un workflow est déclenché depuis un dépôt forké. Le `GITHUB_TOKEN` a des permissions en lecture seule dans les pull requests provenant de dépôts forkés. » C'est pour ça qu'une pull request venant d'un fork ne peut pas déployer — et pour ça que l'événement `pull_request_target`, qui s'exécute avec les secrets du dépôt de base et un token en lecture/écriture, ne doit jamais récupérer le code de la pull request ni l'exécuter.

## L'injection de script, pour de vrai

La [leçon 4](../04-expressions-and-outputs/) a expliqué pourquoi `${{ }}` ne doit pas coller de texte non fiable dans un script. Voici ce que ça donne sur un runner. Le job `injection` :

```yaml
  injection:
    runs-on: ubuntu-latest
    steps:
      - name: Unsafe, the expression is pasted into the script
        run: |
          echo "Title: ${{ inputs.title }}"
      - name: Safe, the value goes through the environment
        env:
          TITLE: ${{ inputs.title }}
        run: |
          echo "Title: $TITLE"
```

```powershell
gh workflow run gha-07-security.yml --field 'title=$(whoami)'
```

```text
Unsafe | echo "Title: $(whoami)"
Unsafe | Title: runner
Safe   | echo "Title: $TITLE"
Safe   |   TITLE: $(whoami)
Safe   | Title: $(whoami)
```

Le step non sûr a **exécuté** `whoami` : l'input est devenu une partie du script avant que bash ne le lise. Le step sûr a affiché le texte. Remplace `inputs.title` par un titre de pull request, un commentaire d'issue ou un nom de branche, et quiconque peut ouvrir une pull request exécute des commandes avec ton token.

## Épingler les actions

`uses: actions/checkout@v7` pointe vers un **tag**, et un tag peut être déplacé vers un autre commit par quiconque contrôle le dépôt de l'action. La documentation : « Épingler une action sur un SHA de commit complet est actuellement la seule façon d'utiliser une action comme une version immuable. »

Trouve le commit derrière un tag avec l'API :

```powershell
gh api repos/actions/checkout/commits/v7 --jq .sha
```

```text
3d3c42e5aac5ba805825da76410c181273ba90b1
```

```yaml
  pinned:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - run: git log -1 --format='%h %s'
```

```text
Download action repository 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1' (SHA:3d3c42e5aac5ba805825da76410c181273ba90b1)
```

Le step *Set up job* d'une exécution non épinglée journalise aussi le SHA qu'il a résolu — `Download action repository 'actions/checkout@v7' (SHA:3d3c42e5…)` dans les exécutions de la [leçon 5](../05-caches-and-artifacts/) — ce qui te dit ce qui a tourné, mais pas ce qui tournera la prochaine fois. Le commentaire `# v7.0.1` garde l'épinglage lisible, et des outils comme [Dependabot](https://docs.github.com/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot) mettent à jour le SHA et le commentaire ensemble. Les autres leçons gardent les tags pour que le YAML reste lisible ; pour les workflows qui détiennent des secrets ou qui déploient, épingle.

## OpenID Connect au lieu de secrets cloud

Pour déployer sur Azure, AWS ou Google Cloud, l'ancienne méthode stocke une clé à longue durée de vie dans un secret. Avec [OIDC](https://docs.github.com/actions/concepts/security/openid-connect), le job demande à GitHub un token signé qui décrit **qui** il est, et le cloud l'échange contre des identifiants à courte durée de vie si sa politique de confiance correspond. Le job a besoin d'une seule permission :

```yaml
  oidc:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
```

Le job `oidc` demande un token pour l'audience `learn-course` et affiche ses claims — jamais le token lui-même :

```text
iss: https://token.actions.githubusercontent.com
aud: learn-course
sub: repo:spareilleux@6644695/learn@1368550922:ref:refs/heads/main
repository: spareilleux/learn
ref: refs/heads/main
event_name: push
job_workflow_ref: spareilleux/learn/.github/workflows/gha-07-security.yml@refs/heads/main
runner_environment: github-hosted
lifetime: 300 s
```

- `sub` est ce qu'une politique de confiance cloud compare en général. Il contient les **ID** du propriétaire et du dépôt (`@6644695`, `@1368550922`) : « les dépôts créés après le 15 juillet 2026 utilisent désormais un format de sujet par défaut immuable qui inclut à la fois l'ID du propriétaire et l'ID du dépôt ». Ce dépôt a été créé le 2026-09-13. Les dépôts plus anciens gardent `repo:owner/repo:ref:…` sauf s'ils activent le nouveau format, et une politique de confiance écrite pour un format ne correspond pas à l'autre.
- Le token vit 5 minutes (`exp - iat`).
- Sans `id-token: write`, le job `no-oidc` a affiché `ACTIONS_ID_TOKEN_REQUEST_URL is not set` : aucun moyen de demander un token.

La configuration côté cloud (un identifiant fédéré Azure, par exemple) sort du cadre de ce cours ; *à vérifier* dans un cours sur le déploiement.

## À retenir

- Déclare `permissions:` en tête de chaque workflow, ajoute le reste par job ; un 403 *Resource not accessible by integration* signale une permission manquante.
- Un secret manquant est une chaîne vide ; les valeurs dérivées ont besoin de `::add-mask::` ; les forks ne reçoivent aucun secret.
- Ne colle jamais de `${{ }}` non fiable dans `run:` — l'injection a exécuté `whoami` sur un vrai runner.
- Un tag peut bouger, un SHA de commit non.
- OIDC remplace les clés cloud stockées : `id-token: write`, un token de 5 minutes, un claim `sub` auquel faire confiance — au format immuable pour les nouveaux dépôts.

## Exercices

1. Le workflow déclare `permissions: contents: read`. Un job déclare `permissions: actions: read` et exécute `actions/checkout`. Quelles permissions a le token du job, et le checkout fonctionne-t-il sur ce dépôt public ?

<details>
<summary>Solution</summary>

Le bloc au niveau du job **remplace** celui du niveau workflow ; les permissions non spécifiées passent à `none`. D'après [`gha-07-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-07-exercises.yml) :

```text
GITHUB_TOKEN Permissions
Actions: read
Metadata: read
93a0ea8 GitHub Actions course: lesson 7 workflows (permissions, masking, pinning, OIDC, injection)
```

Plus de `Contents`, et le checkout a quand même fonctionné : n'importe qui peut cloner un dépôt public. Sur un dépôt privé, le même job n'arriverait pas à récupérer le code — *à vérifier*. Répète chaque permission dont un job a besoin, `contents: read` compris.

</details>

2. Lance le job d'injection avec le titre `x"; echo INJECTED; echo "y`. Qu'affichent les deux steps ?

<details>
<summary>Solution</summary>

```text
Unsafe | echo "Title: x"; echo INJECTED; echo "y"
Unsafe | Title: x
Unsafe | INJECTED
Unsafe | y
Safe   | Title: x"; echo INJECTED; echo "y
```

Le guillemet de l'input a fermé la chaîne du step non sûr, et `echo INJECTED` est devenu une commande séparée. Le step sûr a affiché la valeur telle quelle, guillemets compris.

</details>

3. Épingle `actions/setup-dotnet@v6`. Quelle commande donne le SHA, et quelle ligne faut-il écrire ?

<details>
<summary>Solution</summary>

```powershell
gh api repos/actions/setup-dotnet/commits/v6 --jq .sha
```

```text
a98b56852c35b8e3190ac28c8c2271da59106c68
```

```yaml
      - uses: actions/setup-dotnet@a98b56852c35b8e3190ac28c8c2271da59106c68 # v6
```

C'est le SHA que le runner a journalisé pour `actions/setup-dotnet@v6` dans la leçon 5 : `Download action repository 'actions/setup-dotnet@v6' (SHA:a98b56852c35b8e3190ac28c8c2271da59106c68)`. Préfère le tag de version complet dans le commentaire (`# v6.x.y`) pour que l'outil de mise à jour connaisse la version exacte.

</details>

## Sources

- [Référence de l'utilisation sécurisée](https://docs.github.com/actions/reference/security/secure-use)
- [Syntaxe des workflows : `permissions`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#permissions)
- [Utiliser des secrets dans GitHub Actions](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
- [Injections de script](https://docs.github.com/actions/concepts/security/script-injections)
- [OpenID Connect](https://docs.github.com/actions/concepts/security/openid-connect) et la [référence OIDC](https://docs.github.com/actions/reference/security/oidc)
- [Événements qui déclenchent des workflows : `pull_request_target`](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request_target)
