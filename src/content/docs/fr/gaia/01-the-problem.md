---
title: "1. Le problème : ce que vaut un « terminé »"
description: "Pourquoi le message de fin d'un agent est de la prose et non une preuve, les quatre axes indépendants que Gaia refuse de réduire à un seul nombre, et la doctrine qui en découle : Design It Twice, les balles traçantes, la réversibilité comme propriété typée, et la vérification indépendante comme transition à part. Avec la liste des raccourcis que Gaia nomme et rejette."
sidebar:
  order: 1
---

Un agent termine et dit : *« J'ai implémenté le chemin d'annulation et ajouté un test. Les 2 075 tests passent tous. »*

Cette phrase contient une affirmation vérifiable et trois qui ne le sont pas. L'affirmation vérifiable, c'est le nombre. Les autres sont qu'un chemin d'annulation existe, qu'un test le couvre, et que la suite a bien été lancée : par cet agent, dans cet arbre, après cette modification. Tu peux aller les vérifier à la main, et pour une seule modification, tu le feras. La question de cette leçon, c'est ce qui se passe quand il y a quarante phrases de ce genre par jour, venant de quatre sessions que tu ne surveillais pas.

## Les marqueurs de fin ne sont pas des preuves

La doctrine d'ingénierie de Gaia contient une liste intitulée **Raccourcis rejetés**. Deux de ses entrées résument tout le problème, en une ligne chacune :

> assimiler l'activité, la consommation de tokens, le temps écoulé ou un marqueur de fin à un progrès ;
>
> accepter un rapport, un prototype, un test unitaire vert ou une publication sur GitHub comme une intégration effective.

Les deux décrivent des choses qui *ressemblent* à des preuves et n'en sont pas. Un marqueur de fin est un token que le modèle a émis parce que la conversation arrivait à son terme. Le temps écoulé mesure combien de temps un modèle a parlé. Un test unitaire vert prouve que l'unité fait ce que son auteur pensait, c'est-à-dire exactement la croyance qu'on est en train d'examiner. Et une pull request fusionnée prouve que quelqu'un a cliqué sur un bouton.

Le principe d'ingénierie sous-jacent est **ENG-08** :

> L'auteur d'une modification ne peut pas l'approuver. La vérification se lie à des entrées, des empreintes, des tests, des contrôles et un périmètre exacts. Un marqueur est la preuve que le travail s'est arrêté, pas la preuve que ses affirmations sont vraies.

Lis lentement la dernière proposition : *la preuve que le travail s'est arrêté*. C'est vraiment tout ce que t'apprend un marqueur de fin, et c'est utile à savoir : une session qui ne revient jamais est un autre problème qu'une session revenue avec un mauvais résultat. Ce n'est simplement pas ce que les gens y lisent.

### L'équivalent en C#

Tu refuses déjà cette substitution dans le code que tu écris. Imagine une méthode qui renvoie `Task<bool>` pour « le paiement est-il passé », dont l'implémentation attrape toutes les exceptions et renvoie `true` parce que la requête a été envoyée. Personne ne l'accepterait. « J'ai envoyé la requête » et « le paiement est réglé » sont deux faits différents, et le type qui les confond est le bug.

Le bus de Gaia applique exactement cette discipline aux mots que les agents emploient les uns à propos des autres. `send` ne renvoie pas « envoyé ». Il renvoie :

```text
accepted-for-delivery; not read, not agreed, not completed
```

La chaîne est longue exprès. C'est un type de retour qui refuse d'être mal lu.

## Les quatre axes

La deuxième idée est que les propriétés intéressantes d'un artefact sont indépendantes, et que les écraser en un seul score détruit l'information dont tu avais besoin. D'après la doctrine :

> La fraîcheur, la qualité, l'acceptation et l'autorité restent des axes indépendants. Un artefact frais peut être faux ; un artefact de grande qualité peut être périmé ; un artefact accepté peut n'accorder aucune autorité.

| Axe | La question à laquelle il répond | La forme réduite que tu as déjà vue |
|---|---|---|
| Fraîcheur | est-ce dérivé des entrées actuelles ? | « mis à jour il y a 2 jours » |
| Qualité | est-ce que ça fait ce que ça prétend, sous test ? | « build réussi » |
| Acceptation | un acteur indépendant l'a-t-il approuvé ? | « approuvé » |
| Autorité | un effet peut-il être réalisé sur cette base ? | encore « approuvé » |

Les deux dernières partagent le même mot dans tous les outils de revue de code du marché, et c'est la confusion qui fait le plus mal. Une revue approuvée signifie qu'un humain a lu un diff. Elle ne signifie pas que le diff peut être déployé en production à 17 h 55 un vendredi. Dans un système où les agents peuvent agir, traiter les deux comme un seul fait, c'est la façon dont un agent qui a reçu un gentil message de revue conclut qu'il peut pousser.

Gaia les garde séparées par la structure plutôt que par convention : l'acceptation est un verdict consigné dans un reçu, et l'autorité est une autorisation émise à part, à usage unique et confirmée par un humain, que la leçon 4 examine.

### L'incertitude n'est pas non plus un seul nombre

La moitié scientifique de la doctrine dit la même chose de la confiance, dans **SCI-05** :

> Rapporter les unités, la possibilité de valeurs nulles, l'incertitude épistémique et aléatoire le cas échéant, la taille de l'échantillon, l'étalonnage ou la couverture, la sensibilité aux hypothèses, et les insuffisances connues du modèle. Ne pas comprimer le conflit, l'ignorance, le risque, la fraîcheur et la confiance en un seul scalaire.

Si tu as déjà vu un tableau de bord d'agents avec un badge « confiance : 87 % », ce principe est l'objection qu'on lui oppose. Le conflit, quand deux sources se contredisent, et l'ignorance, quand aucune source n'existe, sont deux états différents, avec des remèdes différents, et un pourcentage unique ne peut pas les distinguer. Quand la provenance manque, la réponse de Gaia est la valeur `UNKNOWN`, jamais un succès déduit.

## Ce qui en découle : la doctrine

Dès qu'on décide que seul ce qui peut être rejoué compte comme preuve, une poignée de règles d'ingénierie cessent d'être une affaire de goût et deviennent obligatoires. Gaia en énonce neuf ; quatre comptent pour lire la suite de ce cours.

### ENG-02 — Design It Twice, seulement aux jointures porteuses

Avant de créer ou de modifier une interface publique, une jointure entre modules, un schéma persistant, une frontière d'autorité ou un contrat entre dépôts, produis **au moins deux conceptions réellement différentes**, normalement trois pour une porte à sens unique, en faisant varier délibérément la cible d'optimisation, et consigne celle qui est choisie dans un reçu de décision qui nomme ce qui a été rejeté.

La procédure est le [Design It Twice de Matt Pocock](https://github.com/mattpocock/skills/blob/c0d69015e0cc8b66715beb3f93f9e53256e20f30/skills/engineering/codebase-design/DESIGN-IT-TWICE.md) (« concevoir deux fois »), lui-même dérivé de la méthode de conception de modules de John Ousterhout. Gaia ajoute un avertissement qui compte quand c'est un agent qui génère les alternatives :

> La génération d'alternatives est consultative. Plusieurs variantes issues d'un même contexte ne sont pas une approbation indépendante, et un vote à la majorité n'établit pas la justesse.

Trois conceptions produites par un seul modèle dans une seule conversation sont trois tirages d'une même distribution. Elles ont l'air d'un jury et n'en sont pas un. Tu peux voir le principe appliqué dans le propre document de conception de l'usine, qui consigne trois interfaces candidates, un script monolithique, un lanceur de commandes arbitraires, et un cœur neutre vis-à-vis des fournisseurs avec des profils de fournisseur fermés, et explique pourquoi la troisième a été retenue.

Point essentiel, ENG-02 dit aussi quand *ne pas* le faire : « Ce n'est pas exigé pour les modifications triviales, locales et qui préservent le comportement. » Une doctrine qui exige trois conceptions pour corriger une faute de frappe est une doctrine que les gens contournent.

### ENG-05 — La plus petite balle traçante de bout en bout

> Pour un comportement non trivial, construis d'abord la plus petite tranche verticale qui traverse chaque jointure requise et qui peut échouer honnêtement. Un test unitaire vert, une couche isolée, un document généré ou un prototype local ne constituent pas, à eux seuls, une intégration.

« Qui peut échouer honnêtement » est l'expression porteuse. Une démo câblée pour réussir traverse les mêmes jointures et ne prouve rien, et c'est la même objection que **SCI-02** oppose aux expériences confirmatoires : *une démonstration qui ne peut que réussir n'est pas une expérience.*

### ENG-07 — La réversibilité est une propriété typée

Chaque modification est classée comme **librement réversible**, **compensable**, **migrable** ou **à sens unique**, en précisant le chemin de retour arrière et la preuve qui le déclenche. Les portes à sens unique exigent une autorité humaine explicite et une revue indépendante plus stricte.

C'est le même réflexe qu'une politique de migration de base de données, où tu traites déjà `DROP COLUMN` autrement que `ADD INDEX`, appliqué à chaque modification, y compris celles qu'un agent propose à 3 heures du matin.

### ENG-06 — Des transitions déterministes, idempotentes et rejouables

> Répéter la même requête acceptée doit soit produire le même résultat, soit renvoyer le résultat précédent sans dupliquer les effets. Le rejeu à partir de preuves immuables doit reconstruire l'état de décision matériel.

La leçon 3 rend ce principe concret : un journal qu'on peut rejouer deux fois en obtenant le même état, et un vérificateur qui contrôle exactement cela.

## Les artefacts, et la clause anti-bureaucratie

Une doctrine de ce genre a un mode de défaillance évident : elle devient un formulaire à remplir. Le tableau de Gaia des artefacts requis du graphe de travail est précédé d'une phrase qui la garde honnête : *« Le plus petit ensemble applicable est requis ; un travail trivial ne doit pas fabriquer de paperasse. »*

| Artefact | Étape qu'il éclaire |
|---|---|
| Mission Brief (note de mission) | la permission de concevoir |
| Design Alternatives (alternatives de conception) | le choix de la jointure |
| Decision Receipt (reçu de décision) | la permission d'implémenter |
| Experiment Plan (plan d'expérience) | la permission de mesurer |
| Evidence Manifest (manifeste des preuves) | la reproductibilité |
| Transition Receipt (reçu de transition) | l'acceptation de l'état |
| Independent Review (revue indépendante) | la promotion |

Lis la colonne de droite de haut en bas et la forme apparaît : chaque artefact achète exactement une permission. Rien dans la colonne de gauche *n'est* une autorité ; chacun est la condition préalable pour pouvoir demander l'étape suivante. C'est la même séparation que celle que trace le tableau de vocabulaire de la [mission](../) entre une revendication, une intention et un effet.

## Reproductibilité ou réplication

Une distinction de la moitié scientifique mérite d'être emportée dans l'ingénierie ordinaire, parce que les deux mots sont employés l'un pour l'autre partout ailleurs. **SCI-04** :

- **Reproductibilité** : un acteur indépendant obtient des résultats cohérents en utilisant *les mêmes* entrées, le même code, les mêmes méthodes et les mêmes conditions.
- **Réplication** : l'affirmation est testée avec de *nouvelles* preuves, ou dans des conditions recueillies de façon indépendante.

Gaia exige la reproductibilité avant la promotion, et la réplication ou des preuves mises de côté pour les affirmations destinées à se généraliser. En termes d'agents : relancer le même prompt avec la même graine et obtenir le même diff, c'est de la reproductibilité, et c'est bon marché et nécessaire. Cela ne dit rien sur le fait que l'approche fonctionne sur le dépôt suivant. La leçon 5 montre où Gaia s'applique cela à elle-même : le nombre de quatre voies est reproductible, et explicitement non répliqué avec de vraies voies Claude et Codex, et le document le dit.

## Exercices

1. Un collègue propose une tuile de tableau de bord : « Débit des agents : 14 tâches par heure, en hausse de 30 % cette semaine. » Nomme trois des raccourcis rejetés par Gaia qu'elle enfreint, et dis ce que la tuile devrait mesurer à la place.

<details>
<summary>Solution</summary>

Elle assimile l'activité et le temps écoulé à un progrès ; elle accepte les marqueurs de fin comme un progrès, puisque « tâches » veut presque certainement dire ici « sessions qui se sont terminées » ; et elle comprime la fraîcheur, la qualité et l'acceptation en un seul scalaire, auquel on ajoute ensuite une flèche de tendance. C'est peut-être aussi une comparaison sur l'échantillon même, sans référence (**SCI-06**).

Ce que Gaia mesure à la place, d'après la carte d'architecture : *« Les métriques de livraison mesurent les transitions acceptées et les reçus, pas les tokens, l'activité des voies ou les marqueurs de fin en prose. »* La tuile compterait donc les transitions arrivées à un état terminal avec un reçu, et il lui faudrait aussi le dénominateur, c'est-à-dire les transitions refusées et non réglées, parce que 14 acceptées sur 15 et 14 sur 60 ne font pas la même semaine.

</details>

2. Tu ajoutes une méthode à une classe utilitaire interne : tu renommes un champ privé et mets à jour ses trois sites d'appel dans le même fichier. ENG-02 s'applique-t-il ? Maintenant, tu modifies la forme du JSON que cette classe écrit sur disque. S'applique-t-il alors ?

<details>
<summary>Solution</summary>

Non, puis oui. Le premier cas est trivial, local et préserve le comportement : ENG-02 cite exactement ce cas comme hors de son champ, et fabriquer deux conceptions pour lui, c'est la paperasse contre laquelle la doctrine met en garde. Le second modifie un schéma persistant, qui figure explicitement dans la liste des déclencheurs d'ENG-02, parce que tout ce qui a déjà été écrit sous l'ancienne forme doit rester lisible ou être migré. C'est aussi là qu'arrive ENG-07 : un changement de schéma est au mieux migrable, pas librement réversible, donc la conception doit nommer le chemin de migration ou de compensation avant d'être implémentée.

</details>

3. Un agent rapporte : « Je n'ai pas pu joindre l'API GitHub, alors j'ai supposé que la pull request avait été créée et j'ai marqué l'opération comme terminée. » Quel principe cela viole-t-il, et quel aurait dû être l'état ?

<details>
<summary>Solution</summary>

**SCI-03** : *« Une provenance manquante ou invérifiable produit `UNKNOWN`, pas un succès déduit. »* La carte d'architecture donne la forme opérationnelle de la même règle : *« L'ambiguïté du transport est normalisée en une observation non réglée, et non en un succès ou un refus deviné à partir de la prose »*, et *« Les effets distants ambigus restent non terminaux jusqu'à leur rapprochement ; le temps écoulé et les nouvelles tentatives ne peuvent pas fabriquer la vérité. »*

L'état correct est `EFFECT_AMBIGUOUS` : non terminal, conservé, et réglé seulement en relisant plus tard le fournisseur qui fait autorité. Note que la mauvaise réponse ici n'est pas seulement « terminé » : « échoué » est tout aussi faux, et pour la même raison. L'effet a très bien pu avoir lieu.

</details>

4. La doctrine de Gaia dit que l'auteur d'une modification ne peut pas l'approuver. Un agent génère trois conceptions, en choisit une, l'implémente, puis lance une seconde session avec un prompt de relecteur qui l'approuve. Quelle partie d'ENG-08 est satisfaite, et laquelle ne l'est pas ?

<details>
<summary>Solution</summary>

Le *nombre* de sessions ne satisfait rien dans ENG-08. Le principe exige que la vérification « se lie à des entrées, des empreintes, des tests, des contrôles et un périmètre exacts » : un relecteur à qui l'on donne l'identité exacte du candidat, un arbre épinglé et les falsificateurs déclarés fait donc une vérification, et un relecteur à qui l'on donne un résumé aimable de la modification n'en fait pas.

Les trois conceptions sont disqualifiées séparément par l'avertissement d'ENG-02 : des variantes issues d'un même contexte ne sont pas une approbation indépendante. Et la leçon 4 montre la partie structurelle de la réponse : l'usine de Gaia lie l'arbre complet du candidat avant la revue, et refuse si quoi que ce soit a changé pendant celle-ci, de sorte que « le relecteur a approuvé » est une affirmation sur un arbre précis plutôt que sur une conversation.

</details>

## Sources

- Gaia : [principes d'ingénierie et de recherche](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/engineering-and-research-principles.md), [`ARCHITECTURE.md`](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/ARCHITECTURE.md), [conception de l'agent de l'usine](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/factory-agent-design.md)
- Matt Pocock, [Design It Twice](https://github.com/mattpocock/skills/blob/c0d69015e0cc8b66715beb3f93f9e53256e20f30/skills/engineering/codebase-design/DESIGN-IT-TWICE.md)
- John R. Platt, [Strong Inference](https://doi.org/10.1126/science.146.3642.347) : l'origine de l'idée de « test discriminant » dans SCI-02
- National Academies, [Reproducibility and Replicability in Science](https://doi.org/10.17226/25303) : les définitions qu'utilise SCI-04
- W3C, [PROV-DM: The PROV Data Model](https://www.w3.org/TR/prov-dm/) : le vocabulaire de provenance derrière SCI-03
