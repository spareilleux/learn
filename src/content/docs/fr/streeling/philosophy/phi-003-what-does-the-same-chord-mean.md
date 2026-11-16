---
title: Que signifie « le même accord » dans la recherche GA ?
description: Que signifie le même accord dans la recherche GA ? — Philosophie
sidebar:
  label: PHI-003 · Que signifie « le même accord » dans la recherche GA ?
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-003-what-does-the-same-chord-mean.fr.md
---

:::note[Streeling University]
**PHI-003** · Que signifie le même accord dans la recherche GA ? · early-intermediate · 40 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-003-what-does-the-same-chord-mean.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHI-001](../../philosophy/phi-001-how-to-argue-well/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de philosophie** | Niveau début intermédiaire | 40 minutes | Brouillon français ; révision du contenu, essai par un apprenant et révision linguistique humaine en attente

## Objectifs et question du projet

Vous apprendrez à distinguer trois sens de l'identité pour les accords de guitare, à calculer un petit exemple de classes de hauteur et d'intervalles et à choisir les preuves d'une affirmation de recherche. **Question du projet :** lorsque GA dit à un guitariste que deux voicings sont « les mêmes » ou « similaires », quelle relation musicale a-t-il réellement testée ? Sans relation explicite, un algorithme correct peut tout de même répondre à la mauvaise question musicale.

[PHI-001](../../philosophy/phi-001-how-to-argue-well/) distingue une conclusion de ses prémisses. [PHI-002](../../philosophy/phi-002-when-is-an-advisory-decision-justified/) distingue un enregistrement de décision valide d'une action justifiée. Ici, nous appliquons cette discipline à un mot du produit. « Même » est une conclusion ; les notes MIDI, classes de hauteur, classes d'intervalles et scores de recherche sont des prémisses possibles différentes. Le [schéma de domaine](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/architecture/DOMAIN_SCHEMA.md) GA concerné distingue un `PitchClassSet` littéral, un `IntervalClassVector` (ICV) et une classe d'ensembles liée par transposition ou inversion. Nous devons nommer la relation demandée par le guitariste avant de choisir une méthode de recherche.

## 1. Quatre regards sur une comparaison d'accords

Un numéro de note MIDI comprend le registre : C3 vaut 48 et C4 vaut 60. Une **classe de hauteur** prend le numéro de note modulo 12 ; les deux donnent donc C (`0`). Un ensemble non ordonné de classes de hauteur oublie l'octave, les doublures et l'ordre des notes. Un ICV compte les classes d'intervalles non ordonnées entre classes de hauteur distinctes ; il oublie davantage encore. Le [schéma GA au commit `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) place le chroma littéral à 12 composantes de classes de hauteur, la cardinalité et un ICV à six composantes dans `STRUCTURE`, puis porte la classe de hauteur de fondamentale déclarée dans une partition `ROOT` distincte. Le schéma avertit explicitement que **la partition `STRUCTURE` entière n'est pas invariante par transposition**. Ses sous-dimensions ICV/cardinalité ont une invariance différente de son chroma.

| Question possible du guitariste | Relation opérationnelle | Ce qu'elle oublie |
|---|---|---|
| « S'agit-il exactement des mêmes notes jouées ? » | Même multiensemble de notes MIDI | Placement temporel et timbre de l'interprétation, mais pas l'octave |
| « S'agit-il des mêmes classes de hauteur à une autre position ? » | Même ensemble de classes de hauteur | Octave, doublures, ordre et registre |
| « Est-ce une version transposée ou inversée ? » | Une transposition ou inversion explicite transforme un ensemble en l'autre | Position absolue des classes de hauteur |
| « Ont-ils le même contenu intervallique ? » | Même ICV à six composantes | Classes de hauteur absolues, fondamentale et, éventuellement, distinctions entre classes d'ensembles différentes |

Ces relations répondent à des questions différentes. Des ensembles de classes de hauteur égaux ont des ICV égaux, mais la réciproque ne tient pas nécessairement. Une correspondance d'ICV ne doit pas devenir silencieusement « le même nom d'accord » ou « la même forme physique ». Un seuil de similarité est encore plus faible : il peut classer des candidats, mais ne définit pas à lui seul une classe d'équivalence mathématique.

La [fixture pédagogique figée au commit Demerzel `50c0d2f`](https://github.com/GuitarAlchemist/Demerzel/tree/50c0d2f5eb6684499c3bcf95d77f0481af2cc136/state/streeling/fixtures/philosophy/phi-003) fournit cinq courtes listes de notes MIDI et des étiquettes explicites de fondamentale. Son script sans dépendances calcule les ensembles de classes de hauteur, les six comptes de classes d'intervalles, un **cosinus simplifié de chroma binaire** et l'existence d'une transposition ou inversion exacte. Exécutez `python state/streeling/fixtures/philosophy/phi-003/compare_voicings.py` depuis la racine Demerzel. La fixture n'est ni un embedding GA, ni une trace de recherche active, ni un test de confort de doigté.

### Exercice pratique 1

La fixture compare `c_major_low = [48,52,55]` et `c_major_high = [60,64,67]`. Les multiensembles de notes MIDI sont-ils égaux ? Les ensembles de classes de hauteur et les ICV sont-ils égaux ? Que reste-t-il à prouver sur deux doigtés de guitare ?

> **Réponse :** Les multiensembles de notes MIDI diffèrent d'une octave. Tous deux donnent l'ensemble de classes de hauteur `{0,4,7}` et partagent donc l'ICV `[0,0,1,1,1,0]` ; leur cosinus simplifié de chroma binaire est `1`. La fixture ne dit rien du choix des cordes, de l'écartement de la main, du timbre, de la jouabilité ni de l'égalité des embeddings GA *complets* de dimension 240 et de leurs classements.

## 2. Une transposition n'est pas une identité littérale de classes de hauteur

`c_major_low` a pour classes de hauteur `{0,4,7}`. Monter chaque classe de deux demi-tons donne `d_major = {2,6,9}`. La fixture confirme une transposition exacte `+2` et le même ICV `[0,0,1,1,1,0]`. Leurs ensembles de chroma binaire ne se recouvrent pas ; leur **cosinus simplifié limité au chroma vaut donc zéro**. Ce zéro n'est pas le cosinus de la partition `STRUCTURE` complète de GA. Le [TheoryVectorService](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs) GA combine le chroma avec l'ICV, la cardinalité et d'autres valeurs ; son propre commentaire rapporte un cosinus `STRUCTURE` non nul pour une triade majeure transposée. L'[outil figé d'export d'invariance](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tools/GaStructureInvariance/Program.cs) existe précisément pour tester cette partition sur des classes d'ensembles et les 12 transpositions.

Cette distinction touche un véritable workflow utilisateur. « Montrez cet accord dans un autre registre » suggère de conserver les classes de hauteur tout en examinant doigté et registre. « Jouez cette forme en D » appelle une transposition. « Trouvez du matériau harmoniquement apparenté » peut appeler une recherche fondée sur l'ICV. Le [IcvNeighborsSkill](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs) GA figé utilise la distance ICV pour chercher des ensembles proches de classes de hauteur ; c'est une autre opération que de promettre l'invariance par transposition de tout l'embedding OPTIC-K. Une étiquette produit devrait exposer assez de la relation pour qu'un guitariste juge le résultat.

### Exercice pratique 2

Pour `c_major_low` et `d_major`, nommez une relation qui tient et deux qui ne tiennent pas. Pourquoi le cosinus chroma nul de la fixture serait-il la mauvaise réponse numérique à « quel est le cosinus STRUCTURE complet de GA ? »

> **Réponse :** La transposition exacte et l'égalité d'ICV tiennent. L'égalité littérale des multiensembles de notes MIDI et l'égalité des ensembles de classes de hauteur ne tiennent pas. La fixture ne calcule le cosinus que sur des bits de chroma binaire de même poids, tandis que `STRUCTURE` de GA comprend aussi des composantes ICV, de cardinalité et tonales. Un zéro dans cette projection simplifiée ne peut pas remplacer la partition complète de GA ou le score final pondéré de recherche.

## 3. Même la fondamentale et le contenu intervallique peuvent ne pas suffire

Comparez `c_major_low = {0,4,7}` et `c_minor = {0,3,7}`. Tous deux ont la fondamentale déclarée C (`0`) et l'ICV `[0,0,1,1,1,0]` ; la fixture trouve une **inversion au sens de la théorie des ensembles** `pc -> (-pc + 7) mod 12` qui transforme un ensemble en l'autre. C'est une transformation de classes de hauteur, pas un renversement d'accord de guitare obtenu en changeant la note de basse. Les ensembles diffèrent et leur cosinus chroma simplifié est `2/3`, car seuls C et G sont communs. La fondamentale déclarée et l'ICV ne déterminent pas ensemble si la tierce est E ou E bémol. Une étiquette de fondamentale dans la fixture est une **entrée fournie**, pas une fondamentale déduite par le script. Cela compte lorsqu'un accord admet plusieurs interprétations plausibles.

Pour `c_diminished = {0,3,6}`, l'ICV est `[0,0,2,0,0,1]` ; il diffère de celui de la triade majeure malgré la fondamentale C commune. Ces petites comparaisons constituent un contre-exemple utile à l'affirmation « une seule représentation capture toutes les notions d'identité ». Elles n'impliquent pas que le système GA complet confonde ces accords. L'embedding de GA contient plus que les deux champs examinés ici, et une véritable affirmation de recherche exige une requête, une révision d'index, un parcours de calcul de score et une sortie classée observée.

### Exercice pratique 3

Quelqu'un propose la clé `(root_pc, ICV)` comme identifiant unique d'accord. Testez-la avec `c_major_low` et `c_minor`. Quel champ supplémentaire de `STRUCTURE` de GA aide à distinguer ces exemples ?

> **Réponse :** Les deux exemples ont la fondamentale fournie `0` et le même ICV à six composantes ; la clé proposée entre donc en collision alors que `{0,4,7} != {0,3,7}`. Le chroma littéral de classes de hauteur distingue E d'E bémol. Ce contre-exemple rejette l'unicité de cette clé à deux champs ; il ne mesure pas la fiabilité du vecteur GA complet.

## 4. Décider de la portée d'une affirmation de similarité

L'égalité d'ensembles exacts de classes de hauteur est réflexive, symétrique et transitive. Une similarité à seuil peut ne pas être transitive : un tableau synthétique de scores pourrait donner `sim(A,B)=0.8`, `sim(B,C)=0.8` et `sim(A,C)=0.5`. Au seuil `0.75`, A est « similaire » à B et B à C, alors que A n'est pas « similaire » à C. Appeler ces éléments reliés par seuil « les mêmes » créerait une classe d'équivalence trompeuse. Une interface de recherche pratique peut classer par score, mais devrait préciser la portée de celui-ci et éviter une affirmation universelle d'identité.

Une petite proposition de conception **consultative** consiste à demander quelle comparaison l'utilisateur souhaite : ensemble exact de classes de hauteur, transposition explicite, voisinage ICV ou classement de voicings. Le contre-argument le plus fort est la complexité supplémentaire de l'interface : beaucoup de guitaristes veulent simplement une alternative jouable et ne veulent pas quatre contrôles techniques. Une solution plus simple est une recherche ordinaire avec une explication claire pour chaque résultat, par exemple « mêmes classes de hauteur ; autre registre » ou « même contenu intervallique après transposition ». Le critère de rejet du contrôle supplémentaire serait un test d'apprenant où il ajoute de la friction sans améliorer la réussite de la tâche ni réduire les choix erronés. Aucun test utilisateur de ce type n'a été effectué ici.

### Exercice pratique 4

À un seuil synthétique de `0.75`, les similarités sont A–B `0.8`, B–C `0.8` et A–C `0.5`. « Score au moins égal à 0.75 » peut-il être une relation d'équivalence ? Nommez la propriété violée.

> **Réponse :** Non. A est lié à B et B à C, mais A n'est pas lié à C ; la transitivité échoue donc. Un classement ou un voisinage peut rester utile ; cette seule règle ne permet pas de le décrire comme une classe mathématique d'accords identiques.

### Exercice pratique 5

Un guitariste demande « montrez les mêmes notes plus haut sur le manche », puis « transposez ceci en D ». Quelle relation un prototype devrait-il tester pour chaque demande, et quelle observation réfuterait l'affirmation qu'une recherche générique traite bien les deux ?

> **Réponse :** Pour la première demande, conserver l'ensemble de classes de hauteur et évaluer des alternatives d'octave ou de registre jouables ; pour la seconde, appliquer une transposition explicite dans la tonalité cible et vérifier les classes obtenues. Une tâche d'apprenant contrôlée où les utilisateurs choisissent régulièrement des résultats avec de mauvaises classes de hauteur, tonalités ou intentions de doigté réfuterait l'affirmation que l'étiquette générique des résultats suffit. Testez avec de véritables requêtes GA et sorties classées avant d'affirmer un comportement produit ; la fixture seule ne peut pas l'établir.

## Sources, limites et prochaine vérification

Les références d'implémentation liées aux sources sont [EmbeddingSchema](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs), [TheoryVectorService](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs), l'[outil d'export d'invariance](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tools/GaStructureInvariance/Program.cs), le [skill de voisinage ICV](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs) et le [schéma de domaine](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/architecture/DOMAIN_SCHEMA.md) GA, tous au commit `dc2e74cbd992a298f67efb928b5b3754615e1924`. La [fixture pédagogique déterministe](https://github.com/GuitarAlchemist/Demerzel/tree/50c0d2f5eb6684499c3bcf95d77f0481af2cc136/state/streeling/fixtures/philosophy/phi-003) ne calcule que les relations simples énoncées. Elle n'instancie pas le service de vecteurs GA, n'interroge pas un index OPTIC-K actuel, ne teste pas le doigté physique et n'interroge pas de guitariste. Révision humaine du contenu, essai à l'aveugle par un apprenant, révision linguistique humaine de ce brouillon français et relecture publique restent en attente.
