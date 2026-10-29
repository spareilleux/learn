---
module_id: gtr-005-plan-which-string-keeps-ringing
department: guitar-studies
course: "Prévoir quelle corde doit continuer à sonner"
level: intermediate
prerequisites: ["gtr-003-audit-voicing-playability"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prévoir quelle corde doit continuer à sonner

> **Périmètre du brouillon.** Nouvelle exécution autonome de fonctions F# de recherche de positions inchangées, examen de sources à une révision fixe et calculs créés pour des événements tenus. Les revues musicales, techniques humaines, linguistiques et pédagogiques, ainsi que la vérification du HTML déployé du cours, restent à faire. Aucune guitare n'a été jouée et aucun planificateur temporel de GA ni moteur audio n'a été exécuté.

## La question du projet

Une note peut se jouer à plusieurs endroits sur une guitare. Choisir indépendamment une position valide pour chaque note produit-il une phrase où toutes les notes demandées continuent à sonner ? Nous conservons l'identité de quatre événements et testons un modèle restreint : une seule note tenue indépendamment par corde à un instant donné, sans changement de corde pendant un événement tenu. Cela exclut les transferts, les nouvelles attaques et les techniques particulières ; ce n'est pas une description universelle des possibilités physiques de la guitare.

## 1. Réconcilier la numérotation des cordes avant de composer les fonctions

Les [fonctions MIDI de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) à la révision fixée utilisent l'accordage Standard `[40,45,50,55,59,64]`, avec la corde 1 du côté grave. Le [modèle d'accordage C#](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) examiné normalise sa valeur par défaut en plaçant la corde la plus aiguë en premier. Dans toute cette leçon, la numérotation conventionnelle de la guitare désigne par corde 1 le mi aigu E4 et par corde 6 le mi grave E2, avec C4 = MIDI 60.

Pour ce cas à six cordes, convertissez un indice F# s en indice conventionnel `7-s`. Le [relevé de la nouvelle exécution](../../../../code/streeling/evidence/phrase-performance-2026-10-22/native-execution.json) consigne le chargement du code source inchangé dans [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) avec le SDK 10.0.113. Seize cas d'entrée couvrent deux accordages, deux limites de case et quatre hauteurs. L'adaptation des coordonnées et la recherche temporelle sont des calculs créés pour l'exemple, pas une passerelle implémentée ni une exécution C#.

### Exercice 1 : convertir une position renvoyée

La fonction F# renvoie la corde 4, case 5, pour MIDI 60. De quelle corde conventionnelle s'agit-il, et quelle note à vide vérifie la hauteur ? Conserver le numéro de corde 4 sans le changer préserverait-il son sens entre les conventions examinées ?

> **Réponse:** `7-4=3`, la corde conventionnelle de sol G3, dont la hauteur à vide vaut MIDI 55. Ajouter la case 5 donne 60. Conserver le numéro 4 désignerait au contraire la corde conventionnelle de ré D3 : le sens de la coordonnée changerait. L'adaptation est propre à l'ordre à six cordes déclaré.

## 2. Conserver les positions candidates valides

Avec une case maximale de 5, les sorties réelles de la fonction donnent ces positions conventionnelles :

| Hauteur | Positions candidates corde/case conventionnelles |
| --- | --- |
| C4, MIDI 60 | corde 3 case 5 ; corde 2 case 1 |
| E4, MIDI 64 | corde 2 case 5 ; corde 1 case 0 |
| G4, MIDI 67 | corde 1 case 3 |
| D4, MIDI 62 | corde 2 case 3 |

Les appels indépendants de sélection de la meilleure position dans le code source choisissent respectivement les cordes 2, 1, 1 et 2. Chaque position produit la hauteur demandée. Les choix pour E et G utilisent la même corde : leurs durées décideront donc s'ils peuvent coexister. La fonction répond à une question statique ; ce n'est pas un solveur temporel en échec.

### Exercice 2 : identifier la contrainte manquante

Pourquoi E4 sur la corde 1 case 0 et G4 sur la corde 1 case 3, sélectionnés indépendamment, peuvent-ils entrer en conflit malgré la validité des deux positions ? Quelle observation faut-il ajouter à la liste de hauteurs ?

> **Réponse:** Dans le modèle déclaré, ces notes ne peuvent pas se maintenir indépendamment sur la même corde lorsqu'elles se chevauchent. Leurs débuts, fins et identités d'événement déterminent si ce chevauchement existe. Une liste de positions valides note par note ne suffit pas à répondre à la question temporelle.

## 3. Prévoir la note tenue avant l'attaque suivante

Utilisez ces événements créés pour l'exemple, exprimés en temps absolus de noire. Chaque intervalle inclut son début et exclut sa fin.

| Événement | Hauteur MIDI | Début | Fin |
| --- | --- | --- | --- |
| C | 60 | 0 | 4 |
| E | 64 | 0 | 2 |
| G | 67 | 1 | 2 |
| D | 62 | 2 | 3 |

C et E possèdent au départ trois affectations sur des cordes distinctes. Seuls C sur la corde 3 case 5 et E sur la corde 2 case 5 permettent d'accueillir l'attaque de G sur la corde 1 case 3 sans déplacer un événement tenu. Au temps 2, E et G sont terminés ; D peut réutiliser la corde 2 à la case 3. L'énumération exhaustive des affectations donne un seul plan complet avec ces candidats et ces hypothèses.

### Exercice 3 : préserver les événements tenus

Donnez le plan complet. Pourquoi le choix initial, localement valide, de C sur la corde 2 et de E sur la corde 1 peut-il échouer à l'arrivée de G ? Déplacer discrètement l'une des notes tenues vers une autre corde conserve-t-il la même réalisation de l'événement ?

> **Réponse:** C utilise la corde 3 case 5 ; E la corde 2 case 5 ; G la corde 1 case 3 ; D la corde 2 case 3. L'autre choix initial occupe la seule corde admissible de G alors que E doit continuer. Déplacer une note tenue demanderait un modèle de transfert ou de nouvelle attaque déclaré séparément ; ce problème d'affectation ne l'autorise pas implicitement.

## 4. Montrer le conflit au lieu d'inventer un doigté

Déplacez le début de D au temps 1.5 et conservez sa fin à 3. Entre les temps 1.5 et 2, les quatre événements sont actifs. Avec une limite de case de 5, l'ensemble de leurs cordes admissibles se réduit aux cordes 1, 2 et 3. Quatre événements simultanés indépendants ne peuvent pas être affectés de façon injective à ces trois cordes. Aucune affectation valide n'existe dans ce modèle, même si chaque événement possède au moins une position pour sa hauteur.

Le [mapper de positions C#](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Analysis/FretboardPositionMapper.cs) à la révision fixée filtre déjà les cordes en double dans une même forme d'accord simultané. Il ne conserve pas la corde d'un événement tenu au fil d'une phrase temporalisée. Ce sont des contraintes apparentées, mais de portées différentes ; ce cours n'exécute ni ne remplace ce mapper.

### Exercice 4 : énoncer précisément l'impossibilité

Quel témoin de chevauchement montre le conflit de D anticipé ? Prouve-t-il qu'aucun guitariste ne pourra jamais jouer ces hauteurs, ou que tous les parcours de GA sont défectueux ?

> **Réponse:** Sur l'intervalle semi-ouvert de 1.5 à 2, quatre événements actifs n'ont que trois cordes admissibles avec l'accordage Standard, la limite de case et l'hypothèse de monophonie par corde. Cela prouve l'infaisabilité dans ce modèle d'affectation déclaré. D'autres étendues, techniques ou modifications musicales sont des possibilités distinctes ; ce résultat n'établit ni une impossibilité physique universelle ni une panne générale du système.

## 5. Séparer une solution du modèle d'un résultat pour le musicien

En conservant le début anticipé, mais en portant la limite de case autorisée à 10, on obtient trois affectations complètes ; une limite de 9 n'en donne toujours aucune. Un plan élargi place C sur la corde 4 case 10, E sur la corde 1 à vide, G sur la corde 2 case 8 et D sur la corde 3 case 7. Son étendue entre cases strictement positives vaut 3. Cela vérifie les hauteurs et l'occupation dans le modèle, pas la portée de la main du musicien, l'étouffement des cordes, le timbre ou la propreté de l'exécution.

### Exercice 5 : préciser la prochaine vérification

Un agent qualifie ce plan élargi de « jouabilité prouvée ». Reformulez l'affirmation et indiquez les observations encore nécessaires à la décision du guitariste.

> **Réponse:** Le plan satisfait les contraintes déclarées de hauteur, de temps, d'occupation des cordes et d'étendue élargie. Le guitariste doit encore vérifier le doigté réel, la tenue indépendante des notes, l'étouffement, la propreté des transitions et le son en contexte. Aucun essai avec un musicien n'a eu lieu ici : ces résultats restent donc non vérifiés.

Le [relevé fixe d'occupation](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json) conserve les candidats, les plans et le témoin de chevauchement. [GAA-005](../../guitar-alchemist-academy/en/gaa-005-repair-a-phrase-without-hiding-the-change.md) compare les modifications possibles de la demande au lieu de les dissimuler dans une prétendue solution.
