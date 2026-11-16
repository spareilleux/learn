---
module_id: inf-009-keep-level-when-normalizing-waveform-shape
department: information-theory
course: "Conserver le niveau lors de la normalisation de la forme d’onde"
level: intermediate
prerequisites: ["inf-005-quantization-and-indistinguishable-renders", "inf-008-keep-phase-when-waveform-identity-matters"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver le niveau lors de la normalisation de la forme d’onde

> **Périmètre du brouillon.** Vecteurs réels pédagogiques et lecture du code à une révision fixée. Les revues humaines techniques, musicales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants, ainsi que la vérification du HTML du cours déployé, restent à effectuer. Aucun nouveau rendu audio, résultat perceptif ou validation statistique n’a été produit.

## La question du projet

Un agent transmet une forme normalisée et un score de corrélation parfait. Un autre agent peut-il retrouver le niveau du signal ? [INF-005](inf-005-quantization-and-indistinguishable-renders.md) étudie la perte par quantification ; [INF-008](inf-008-keep-phase-when-waveform-identity-matters.md) préserve la phase. Ici, les changements d’échelle positifs et les décalages disparaissent lors d’une normalisation centrée.

## 1. Définir précisément le descripteur

Les [vecteurs fixés](../../../../code/streeling/evidence/audio-comparison-2026-10-23/normalized-shape.json) utilisent l’écart-type de population, en divisant la variance par le nombre de trames N plutôt que N-1 :

```text
x = [-.25, 0, .25, .5]
y = .5*x + .25 = [.125, .25, .375, .5]
mu_x = 1/8; sigma_x = sqrt(5)/8
mu_y = 5/16; sigma_y = sqrt(5)/16
z[n] = (sample[n] - mu)/sigma
z_x = z_y = [-3, -1, 1, 3]/sqrt(5)
```

La [définition de Pearson du NIST](https://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/correlat.htm) utilise des vecteurs centrés. Les facteurs de normalisation communs s’annulent dans son rapport. Ici, la corrélation vaut 1, alors que la valeur RMS de la différence brute est d’environ .233853587. La corrélation n’est pas la probabilité que deux signaux soient égaux.

### Exercice 1 — Identifier ce que le descripteur oublie

Vérifiez les moyennes, les écarts-types de population et l’égalité des vecteurs normalisés. Une corrélation de 1 implique-t-elle l’égalité brute ?

> **Réponse:** Les moyennes sont .125 et .3125. Le centrage donne des vecteurs proportionnels selon un facteur de .5 ; leurs écarts-types sont donc sqrt(5)/8 et sqrt(5)/16. La division produit le même vecteur normalisé. La différence brute est [.375, .25, .125, 0], avec une valeur RMS non nulle d’environ .233853587. Une corrélation positive parfaite n’implique donc ni égalité brute, ni niveau inchangé, ni verdict d’écoute.

## 2. Préserver les métadonnées de l’inverse

Pour tout vecteur non constant et tout a positif, centrer et normaliser a*x+b donne le même z que x. Un descripteur limité à la forme ne peut pas distinguer toute cette famille. Conserver chaque échantillon normalisé, la moyenne, l’écart-type et le nombre de trames permet l’inversion en arithmétique réelle :

```text
sample[n] = mu + sigma*z[n]
```

Cela ne prouve pas que l’arrondi, la sérialisation des flottants, la compression avec pertes ou un descripteur réduit préservent les octets d’origine.

### Exercice 2 — Réparer le transfert

Quelles valeurs supplémentaires distinguent x de y ? Conserver uniquement le vecteur normalisé commun et N suffit-il ?

> **Réponse:** Conservez la moyenne et l’écart-type de population correspondants, ainsi que N, chaque échantillon z et leur ordre. Les deux couples différents de moyenne et d’écart-type reconstruisent des vecteurs bruts différents. Les seuls z et N communs ne peuvent pas restaurer l’échelle positive et le décalage perdus. Un vecteur de caractéristiques réduit ou un stockage arrondi nécessiterait sa propre analyse de l’erreur de reconstruction et du format des octets.

## 3. La corrélation en valeur absolue peut aussi effacer la polarité

Posons le vecteur inversé -x. Son vecteur normalisé est -z_x ; la corrélation de Pearson signée avec x vaut donc -1. Prendre sa valeur absolue donne 1, comme pour y. Mathématiquement, x + (-x) est le vecteur nul. Aucune lecture sonore, aucun routage ni aucune annulation audible n’ont été observés.

### Exercice 3 — Choisir un score adapté à l’affirmation

Pourquoi la corrélation en valeur absolue ne constitue-t-elle pas une preuve fiable d’une polarité de forme d’onde inchangée ? Que faut-il conserver ?

> **Réponse:** Elle ramène à 1 les formes centrées parfaitement alignées comme celles parfaitement inversées. Conservez la corrélation signée, la politique de polarité, les échantillons d’origine ou une représentation réversible, et le résidu brut. Le contrôle d’annulation mathématique met en évidence l’information éliminée par le score absolu. Il n’établit ni équivalence perceptive, ni interférence mesurée dans une pièce, ni probabilité de correction.

## 4. Les signaux constants constituent un cas distinct

Pour [.25, .25, .25, .25], l’écart-type de population est nul. Le vecteur normalisé et la corrélation de Pearson avec lui sont indéfinis, tandis que la valeur RMS brute vaut .25. Une copie identique peut néanmoins satisfaire l’égalité brute. Un statut constant distinct, la moyenne et le nombre de trames peuvent décrire ce vecteur sans diviser par zéro.

### Exercice 4 — Éviter un score inventé

Un agent écrit une corrélation de 1 dès que les deux entrées sont constantes. Est-ce le résultat défini par Pearson ?

> **Réponse:** Non. Le dénominateur s’annule ; Pearson est donc indéfini. Renvoyez ce statut et comparez directement les constantes si la tâche porte sur l’égalité. Conservez la moyenne et N pour la reconstruction ; la valeur RMS brute reste valide. Une application peut définir une autre règle pour le cas constant, mais doit la nommer au lieu de la présenter comme une corrélation de Pearson.

## 5. Faire passer les métadonnées avant l’abstraction

Le [programme d’exécution de Learn](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/run.mjs) à la révision fixée sépare les comparaisons de flottants bruts et de PCM16. Son calcul RMS applique un plancher numérique avant les logarithmes. Il n’implémente pas ce nouveau descripteur de forme normalisée ou de Pearson. Le [relevé des sources](../../../../code/streeling/evidence/audio-comparison-2026-10-23/source-observations.json) distingue l’inspection du code, les calculs pédagogiques et les éléments historiques issus d’exécutions.

### Exercice 5 — Définir un transfert utile entre agents

Concevez un relevé minimal de comparaison en vous appuyant sur les emplacements dans le code. Comment décideriez-vous si un DSL plus abstrait est utile ?

> **Réponse:** Conservez les révisions du code, la frontière de signal, l’horloge d’échantillonnage, l’ordre des canaux, le format, N, la règle de normalisation, la moyenne, l’écart-type de population, le statut constant, la politique signée ou absolue et le niveau et le résidu bruts. Les présents vecteurs simplifiés n’ont ni horloge mesurée ni format audio ; n’en inventez pas. Repérez la sérialisation des flottants, la conversion PCM16 et les fenêtres RMS du programme d’exécution. Comparez des relevés explicites aux calculs directs sur les échantillons, en incluant des contrôles d’inversion et de constantes, avant d’ajouter un DSL. Mesurez les omissions, les erreurs et le coût sur des tâches réelles ; ni une nouvelle syntaxe ni un score de forme parfait ne prouvent une amélioration. Aucune étude utilisateur de ce type ni nouvelle implémentation n’existe ici.

## Travail à transmettre par l’apprenant

Utilisez la [tâche avec l’aide des sources](../../../../code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md) et la [grille préparée](../../../../code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json). Conservez les réponses réelles et l’assistance reçue ; l’acceptation par l’apprenant reste null. [AUD-009](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md) explicite le gain et le placement temporel retirés au lieu de les cacher dans un score.
