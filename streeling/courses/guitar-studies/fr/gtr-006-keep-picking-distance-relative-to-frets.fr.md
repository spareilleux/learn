---
module_id: gtr-006-keep-picking-distance-relative-to-frets
department: guitar-studies
course: "Rapporter la distance de pincement aux frettes"
level: intermediate
prerequisites: ["gtr-001-the-fretboard-map", "gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Rapporter la distance de pincement aux frettes

> **Portée du brouillon.** Géométrie idéale des frettes et des longueurs conçue pour le cours, prédictions modales et inspection du code public à une révision précise. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun musicien, guitare, moteur natif/WASM, navigateur ou flux de travail [ComfyUI](https://docs.comfy.org/) n'ont fait l'objet d'un essai.

## La question du projet

Un guitariste maintient sa main de pincement à la même distance du chevalet en montant sur le manche. Le médiator est-il resté à la même fraction de la longueur de corde vibrante ? Cela compte pour formuler une consigne de pratique ou une future commande de synthèse de GA. Une distance en millimètres, une fraction de longueur vibrante et un indice de tampon de retard ont des sens différents.

Nous utilisons un diapason à vide de 650 mm conçu pour le cours, des frettes idéales en tempérament égal, une tension et une masse linéique inchangées, sans raideur, compensation ni allongement dû à la hauteur des cordes. Ce sont des hypothèses de modèle, et non des mesures d'un instrument particulier. [GAS-006](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md) définit le pincement triangulaire idéal utilisé pour les prédictions modales ci-dessous.

## 1. Raccourcir la longueur vibrante

Pour la frette k, la longueur vibrante idéale est `L_k=L_0*2^(-k/12)`. La fréquence augmente selon l'inverse du rapport des longueurs sous l'hypothèse déclarée d'une vitesse d'onde fixe. Cela découle de la relation entre longueur et fréquence d'une corde à extrémités fixes dans le [cours de Princeton sur le mouvement ondulatoire](https://kirkmcd.princeton.edu/examples/Ph205/ph205l21.pdf#page=5), combinée au rapport déclaré du demi-ton en tempérament égal. Cela ne modélise pas une guitare physique entière.

| Frette | Longueur vibrante, mm | Rapport de fréquence à la corde à vide |
| --- | --- | --- |
| 0 | 650 | 1 |
| 12 | 325 | 2 |
| 24 | 162.5 | 4 |

### Exercice 1 : calculer la longueur vibrante

Pour le diapason pédagogique, calculez la longueur vibrante à la frette 12 et son rapport de fréquence à la corde à vide. Ce facteur établit-il un résultat d'accordage mesuré sur un instrument ?

> **Réponse:** La longueur est `650/2=325` mm et le rapport de fréquence est 2 selon ce modèle. Aucun instrument n'a été mesuré ; la compensation, l'allongement et la justesse réelle restent donc hors du résultat.

## 2. Distinguer distance et fraction

Déclarez la distance de pincement au chevalet d en millimètres et la position normalisée `p=d/L_k`, avec `0<d<L_k`. Avec une distance fixe de la main de 65 mm, p change avec la longueur vibrante :

| Frette | Distance fixe, mm | Fraction p | Annulations modales idéales |
| --- | --- | --- | --- |
| 0 | 65 | `1/10` | multiples de 10 |
| 12 | 65 | `1/5` | multiples de 5 |
| 24 | 65 | `2/5` | multiples de 5 |

Les familles d'annulations proviennent du déplacement triangulaire idéal et de son facteur `sin(n*pi*p)`. Ce ne sont ni des creux spectraux mesurés ni des consignes pour toucher le nœud d'une harmonique naturelle. Un pincement suivi d'un relâchement ordinaire et un effleurement de la corde pour produire une harmonique sont des opérations initiales ou aux limites différentes.

### Exercice 2 : suivre une main immobile

La main reste à 65 mm du chevalet tandis que la main gauche passe de la frette 0 à la frette 12. Calculez les deux fractions. Quel cinquième mode idéal passe d'une valeur non nulle à zéro ?

> **Réponse:** Les fractions sont `65/650=1/10` et `65/325=1/5`. Le mode 5 est non nul pour le premier pincement triangulaire idéal et nul pour le second, car `5/10` n'est pas entier tandis que `5/5` l'est. C'est une prédiction du modèle, et non le spectre observé d'un musicien.

## 3. Déplacer la main pour préserver la fraction

Pour maintenir `p=1/10`, résolvez `d=p*L_k`. Les distances pédagogiques nécessaires sont de 65 mm à vide, 32.5 mm à la frette 12 et 16.25 mm à la frette 24. La main de pincement doit s'approcher du chevalet lorsque la longueur vibrante diminue. Une consigne de pratique peut donc préciser une distance fixe ou une fraction fixe ; elle devrait indiquer laquelle est visée.

Maintenir p constant préserve le motif normalisé des coefficients idéaux pour un déplacement maximal fixé. Cela ne garantit pas un timbre rayonné, une sonie, une sensation ou une force de médiator identiques. Les résonances de la caisse, la fabrication de la corde et le point d'observation acoustique ou par micro restent pertinents.

### Exercice 3 : préserver une position normalisée

Quelles distances au chevalet maintiennent `p=1/10` aux frettes 12 et 24 ? Laisser la distance à 65 mm satisferait-il cette demande ?

> **Réponse:** Utilisez respectivement 32.5 mm et 16.25 mm. Maintenir plutôt 65 mm donne `1/5` et `2/5` ; cela ne satisfait donc pas la demande de fraction fixe selon la géométrie déclarée.

## 4. Ne pas déduire une position unique de la main d'une seule annulation

Aux frettes 12 et 24 avec une distance fixe de 65 mm, les deux cas idéaux suppriment les multiples de 5, bien que leurs fractions diffèrent. Les amplitudes et les signes modaux ne sont pas nécessairement identiques. Plus généralement, d'autres causes peuvent atténuer un partiel observé, notamment la réponse du micro de guitare ou du microphone. Un partiel absent ne suffit pas à identifier la position physique de pincement.

Le [relevé de géométrie](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/fret-geometry.json) inclut aussi la frette 7 comme cas de transfert hors octave. Ses coordonnées proviennent de la même équation pédagogique. Aucune mesure en millimètres ni trace d'exécution musicale n'y est jointe.

### Exercice 4 : contester la déduction inverse

Un agent observe un cinquième partiel atténué et annonce une fraction unique de pincement de `1/5`. Donnez le contre-exemple pédagogique et expliquez pourquoi l'enregistrement observé exigerait davantage de preuves.

> **Réponse:** La fraction `2/5` supprime aussi le mode 5 dans ce modèle idéal. Une atténuation enregistrée pourrait en outre provenir d'autres chemins de transfert ; on ne peut donc pas déduire une position unique de ce seul partiel. Il faut davantage d'informations modales, un modèle d'observation déclaré et des preuves indépendantes de la position.

## 5. Traduire la demande en un futur contrat du moteur

Le [point d'entrée des notes de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L530-L537) à la révision fixée accepte une fréquence et une vélocité. Son [heuristique d'excitation](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L354-L379) dérive un décalage normalisé de tampon de retard à partir de la vélocité. Ces parcours examinés n'acceptent ni diapason physique, ni identité de frette, ni distance au chevalet. Une fréquence peut correspondre à plusieurs réalisations corde/frette ; elle ne fournit donc pas à elle seule ces coordonnées manquantes.

Une instruction DSL proposée pourrait porter une réalisation physique déclarée de la corde et soit une distance, soit une position normalisée, avec son repère de référence. C'est une conception candidate, et non une API implémentée ou une obligation pour tous les modèles d'utiliser des coordonnées physiques. L'alternative plus simple consiste à exposer et documenter une commande purement synthétique de forme du tampon. La tâche visée par le musicien détermine si la correspondance physique supplémentaire mérite d'être implémentée et validée.

### Exercice 5 : rendre le sens de la consigne exécutable

Reformulez « garder le médiator au même endroit » en deux demandes sans ambiguïté entre les frettes 0 et 12. Le point d'entrée fréquence/vélocité examiné peut-il représenter directement les deux demandes ?

> **Réponse:** Une demande maintient la distance au chevalet à 65 mm, produisant les fractions `1/10` et `1/5`. L'autre maintient la fraction `1/10`, exigeant les distances de 65 mm et 32.5 mm. Le point d'entrée examiné ne possède ni champ de distance physique ni champ de géométrie corde/frette ; il n'encode donc pas directement cette distinction. Implémenter et tester une correspondance, ou choisir une commande synthétique documentée, reste un travail futur.
