---
module_id: gas-008-separate-beating-from-a-change-in-damping
department: guitar-acoustics
course: "Distinguer les battements d’un changement d’amortissement"
level: intermediate
prerequisites: ["gas-004-run-open-e-decay-candidate", "gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer les battements d’un changement d’amortissement

> **Périmètre du brouillon.** Calculs pédagogiques et lecture du code à une révision fixée. Les revues humaines techniques, musicales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants, ainsi que la vérification du HTML du cours déployé, restent à effectuer. Aucun nouvel enregistrement, rendu du moteur ou workflow [ComfyUI](https://docs.comfy.org/) n’a été capturé.

## La question du projet

Le candidat de décroissance de guitare de [GAS-004](gas-004-run-open-e-decay-candidate.md) n’a pas satisfait au critère d’amélioration conservé. Une portion montante de l’enveloppe d’une forme d’onde pourrait inciter un agent à diagnostiquer un amortissement négatif. Cette leçon construit un contre-exemple ; elle ne pose pas de diagnostic sur cet ancien rendu. [GAS-007](gas-007-distinguish-body-poles-from-string-partials.md) distingue les partiels de corde des sections du corps de l’instrument. Ici, nous distinguons l’interférence de l’amortissement des composantes.

## 1. Deux composantes décroissantes peuvent produire une somme avec battements

Le [calcul fixé](../../../../code/streeling/evidence/audio-comparison-2026-10-23/beating-envelope.json) définit le temps en secondes :

```text
x(t) = .25*exp(-t)*(cos(2*pi*100*t) + cos(2*pi*102*t))
     = .5*exp(-t)*cos(2*pi*101*t)*cos(2*pi*t)
E(t) = .5*exp(-t)*abs(cos(2*pi*t))
```

L’identité de produit des cosinus donne une enveloppe de modulation algébrique E. Ce n’est ni une enveloppe mesurée ni une estimation par transformée de Hilbert. L’amplitude de chaque composante vaut .25 fois exp(-t), avec un taux d’amortissement de 1 par seconde. La [relation des battements](https://openstax.org/books/university-physics-volume-1/pages/17-6-beats) donne une fréquence de battement de 2 Hz : la modulation en valeur absolue se répète toutes les .5 secondes. La fréquence moyenne porteuse est de 101 Hz. Aucun seuil d’écoute ni corps de guitare réel n’est modélisé.

### Exercice 1 — Nommer les grandeurs

Déduisez le produit et expliquez pourquoi la fréquence de battement est de 2 Hz alors que le cosinus de modulation signé a une fréquence de 1 Hz.

> **Réponse:** Les fréquences moyenne et de demi-différence sont de 101 et 1 Hz. Le facteur de modulation non amorti en valeur absolue se répète deux fois par seconde ; E contient aussi l’exponentielle décroissante et n’est pas périodique. Les taux d’amortissement des deux composantes restent de 1 par seconde ; ni la fréquence porteuse ni celle des battements n’est un coefficient d’amortissement.

## 2. Une pente sur un court intervalle peut avoir le mauvais signe

Entre t = .2 et t = .4, le rapport calculé des enveloppes est d’environ 2.143464939. Un ajustement naïf sur les extrémités donne :

```text
alpha_apparent = -ln(E(.4)/E(.2))/.2
               = -3.812118251 per second
```

La modulation remonte après une interférence destructive. Cela ne fournit d’énergie à aucune des composantes et ne modifie pas leur amortissement positif.

### Exercice 2 — Rejeter un faux diagnostic

Le taux apparent négatif établit-il l’instabilité d’un résonateur ? Indiquez quelle hypothèse d’un ajustement exponentiel unique sur les extrémités n’est pas satisfaite.

> **Réponse:** Non. L’enveloppe totale de modulation n’est pas une seule exponentielle sur cet intervalle : son facteur cosinus varie lui aussi. Le rapport et le taux négatif ajusté sont corrects pour les extrémités choisies, mais rien ne justifie de les attribuer uniquement à l’amortissement des composantes. Les composantes pédagogiques ont toujours un taux d’amortissement positif de 1 par seconde.

## 3. Comparer à la même phase de battement

À t = 0 et t = .5, le facteur cosinus en valeur absolue est le même. Le rapport d’amplitude vaut exp(-.5), soit environ .606530660 ; le rapport des enveloppes au carré vaut exp(-1), soit environ .367879441. Le taux d’amortissement d’amplitude déduit est de 1 par seconde.

Ces deux instants ne sont pas présentés comme des maxima locaux de l’enveloppe. La multiplication par une exponentielle décroissante décale les maxima de l’enveloppe combinée par rapport aux extrema de la modulation non amortie.

### Exercice 3 — Distinguer amplitude et amplitude au carré

Retrouvez le taux d’amortissement à partir du rapport d’amplitude à phase identique sur .5 secondes. Que se passe-t-il si l’on utilise plutôt le rapport des enveloppes au carré ?

> **Réponse:** L’opposé du logarithme de exp(-.5), divisé par .5, vaut 1 par seconde. Appliquer la même formule d’amplitude à exp(-1) donne 2 par seconde. La mise au carré double le taux de décroissance logarithmique ; elle ne double pas l’amortissement d’amplitude des composantes. Une interprétation énergétique exigerait un modèle physique approprié, pas simplement la mise au carré d’une enveloppe.

## 4. Les zéros ne sont pas des observations logarithmiques

À t = .25 et .75, E est analytiquement nul. Le relevé distingue les zéros exacts de modulation du résidu d’évaluation en virgule flottante. Le logarithme n’y est pas défini. Un plancher numérique introduirait un choix d’analyse sans révéler un amortissement mesuré infini. La forme d’onde brute s’annule aussi lorsque le cosinus porteur s’annule ; tous ses zéros ne désignent pas des zéros d’enveloppe.

### Exercice 4 — Décider quoi conserver

Un agent remplace tous les zéros par une petite constante et annonce une pente de décroissance finie. Que doit préciser son rapport ?

> **Réponse:** Il doit conserver le statut de zéro, la valeur du plancher, les échantillons concernés et la règle d’ajustement. La pente obtenue dépend de cette règle et n’est pas un taux d’amortissement observé des composantes. Les passages par zéro de la porteuse et les zéros de modulation doivent rester distincts. Rejetez un logarithme d’extrémité pris à un zéro exact de l’enveloppe au lieu de traiter silencieusement l’arrondi comme du signal.

## 5. Revenir au moteur avec une comparaison réfutable

Le [moteur GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) à la révision fixée additionne les voix, traite des sections communes du corps de l’instrument et la réverbération, puis limite la sortie. Ses fréquences de corps et son étage de sortie non linéaire ne sont pas cette paire pédagogique de sons purs. Les [observations du code](../../../../code/streeling/evidence/audio-comparison-2026-10-23/source-observations.json) séparent cette lecture du code de l’ancienne exécution native/Wasm conservée. L’ancien critère de décroissance non satisfait le reste.

### Exercice 5 — Préparer une prochaine expérience réelle

À l’aide du code, proposez des éléments qui pourraient distinguer l’interférence d’un changement d’amortissement. Qu’est-ce qui invaliderait la conclusion ?

> **Réponse:** Conservez la révision du code, la fréquence d’échantillonnage, l’excitation, la frontière de signal sélectionnée, les fenêtres, la phase, les filtres, le statut d’écrêtage et l’incertitude. Comparez les composantes isolées ou un ajustement multicomposante validé au signal combiné avant d’attribuer une pente d’enveloppe à l’amortissement. Un mélange variable, une sortie écrêtée, des composantes non résolues ou un mauvais ajustement du modèle invalident cette attribution. Comparez d’abord une analyse directe à la procédure existante de décroissance ; un nouveau DSL ou agent n’améliore pas à lui seul les éléments probants. Aucune expérience de ce type n’a été exécutée ici.

## Travail à transmettre par l’apprenant

Effectuez la [tâche avec l’aide des sources](../../../../code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md) et conservez les calculs, les emplacements dans le code et l’assistance reçue. La [grille préparée](../../../../code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json) n’est pas un résultat d’apprenant réel. Poursuivez avec [AUD-009](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md) pour distinguer les transformations de comparaison de l’identité du signal d’origine.
