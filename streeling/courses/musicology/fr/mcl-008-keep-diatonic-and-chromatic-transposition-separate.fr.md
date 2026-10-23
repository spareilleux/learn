---
module_id: mcl-008-keep-diatonic-and-chromatic-transposition-separate
department: musicology
course: "Distinguer transposition diatonique et transposition chromatique"
level: intermediate
prerequisites: ["mcl-005-preserve-written-and-sounding-pitch", "wml-005-declare-note-name-conventions"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer transposition diatonique et transposition chromatique

> **Périmètre du brouillon.** Calculs pédagogiques d’orthographe des notes par demi-tons entiers, contrôles inverses exacts et lecture du code et de documents primaires à des révisions fixées. Aucune nouvelle exécution d’analyseur, aucun adaptateur de transposition, aucune sortie MusicXML, aucune partition rendue ni aucune lecture sonore n’ont eu lieu. Les revues humaines techniques, musicales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants, ainsi que la vérification du HTML du cours déployé, restent à effectuer.

## La question du projet

Une partie importée doit sonner un demi-ton plus haut. Le C écrit doit-il devenir C# ou Db ? [MCL-005](mcl-005-preserve-written-and-sounding-pitch.md) distingue le registre encodé du registre sonore. Cette leçon ajoute la coordonnée de nom de note nécessaire pour préserver une orthographe enharmonique spécifiée.

Le [champ diatonique de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/diatonic/) compte les pas de hauteur entre l’écrit et le sonore. Son [champ chromatique](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/chromatic/) compte les demi-tons. Tous deux excluent la contribution distincte du changement d’octave. Nous utilisons ces définitions dans un modèle pédagogique en tempérament égal à douze sons, avec C4 égal à 60 et uniquement des altérations entières.

## 1. Suivre deux coordonnées

Indexons les lettres de C à B par les nombres de 0 à 6 et posons `j=7*octave+letter_index`. Si le décalage diatonique est `d`, le décalage chromatique `c` et le changement d’octave `o`, les coordonnées cibles sont `j_new=j+d+7*o` et `m_new=m+c+12*o`, où `m` est le numéro de note absolu.

La nouvelle coordonnée diatonique choisit une lettre et une octave écrite. L’altération nécessaire est la différence entre le numéro de note cible et celui de cette lettre naturelle. Le décalage en demi-tons ne choisit pas à lui seul la lettre.

### Exercice 1 : produire deux cibles enharmoniques

Partez de C4 à 60 et appliquez un décalage chromatique de 1 sans changement d’octave. Comparez un décalage diatonique de 0 à un décalage diatonique de 1. Donnez les deux orthographes et les numéros de notes.

> **Réponse:** Le décalage diatonique 0 conserve la lettre C ; l’altération +1 donne donc C#4. Le décalage diatonique 1 sélectionne D4, dont le numéro naturel est 62 ; l’altération -1 donne donc Db4. Les deux visent 61. Un numéro sonore identique n’implique pas une orthographe identique.

## 2. Propager les changements de lettre au-delà de la limite d’octave

B3 à 59, déplacé d’une lettre et d’un demi-ton vers le haut, devient C4 à 60. Déplacer C4 d’une lettre et d’un demi-ton vers le bas donne au contraire B3 à 59. Si cette seconde opération descend de deux demi-tons, la cible est Bb3 à 58.

L’octave écrite appartient à l’orthographe de la note. B#3 a le numéro de note 60, tandis que Cb4 a 59. Réduire une coordonnée de note naturelle modulo 12 avant d’en préserver l’octave peut masquer ces effets de frontière.

### Exercice 2 : examiner les cas limites

Calculez B3 plus une lettre et un demi-ton, puis C4 moins une lettre et deux demi-tons. Donnez les numéros de B#3 et Cb4, et expliquez pourquoi l’octave écrite seule ne peut pas déterminer le registre sonore.

> **Réponse:** Le premier résultat est C4 à 60 ; le second est Bb3 à 58. B#3 vaut 60 et Cb4 vaut 59, car leurs altérations franchissent la limite naturelle de C. La lettre, l’altération et l’octave déterminent ensemble le numéro ; un champ d’octave écrite isolé ne suffit pas.

## 3. Appliquer un changement d’octave dans les deux domaines

Pour C4 avec des décalages diatonique et chromatique nuls mais un changement d’octave de -1, soustrayez sept pas de lettre et douze demi-tons. La cible est C3 à 48. Ajouter seulement la contribution en demi-tons en conservant l’ancienne octave de la lettre exigerait au contraire une altération artificielle de -12 sur C4. Cela peut donner le bon numéro tout en échouant à préserver l’orthographe voulue.

### Exercice 3 : maintenir la représentation

Déduisez les deux coordonnées cibles pour cette octave descendante. Pourquoi C4 avec une altération de -12 n’est-il pas la sortie voulue, et un type entier impose-t-il à lui seul une petite plage d’altérations ?

> **Réponse:** L’indice diatonique diminue de 7 et le numéro de note de 12, donnant C3 à 48. Conserver C4 en lui attachant -12 modifie la représentation au lieu de répercuter le changement d’octave dans la coordonnée écrite. Un type entier n’impose à lui seul aucune plage d’altérations ; toute validation doit être inspectée séparément.

## 4. Préserver assez d’informations pour inverser la transformation

Déplacez C#4 et Db4 chacun d’une lettre et de deux demi-tons vers le haut. Ils deviennent respectivement D#4 et Eb4, tous deux à 63. Inverser les deux décalages sur les résultats orthographiés conservés retrouve les originaux distincts. Ne conserver que 63 fait perdre la distinction nécessaire pour retrouver l’orthographe fournie.

Le [relevé fixé des transpositions](../../../../code/streeling/evidence/capo-spelling-2026-10-22/spelled-transpositions.json) contient dix cas pédagogiques avec des contrôles inverses exacts. C’est un résultat arithmétique délimité, pas une implémentation générale de MusicXML, une preuve portant sur toutes les traditions de notation ou un test d’écoute.

### Exercice 4 : identifier la représentation réversible

Montrez les deux orthographes après transformation et leur même numéro projeté. Quelles données doivent être conservées pour que l’inverse démontré retrouve l’orthographe d’origine ? Ne conserver que le numéro projeté suffit-il ?

> **Réponse:** C#4 devient D#4 et Db4 devient Eb4 ; les deux se projettent sur 63. Préservez la lettre cible, l’altération et l’octave, ainsi que les décalages diatonique, chromatique et d’octave spécifiés. Prendre les opposés de ces décalages retrouve C#4 et Db4 dans ces cas. Le seul numéro projeté ne peut pas distinguer leurs origines.

## 5. Distinguer l’orthographe stockée de la transposition implémentée

Les [types MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L282-L295) à la révision fixée conservent le nom de note, une altération entière facultative et l’octave, puis fournissent une conversion en numéro de note entier. Les [attributs de l’analyseur](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L165-L180) sélectionnés ne contiennent aucun champ de transposition. Conserver une hauteur orthographiée ne prouve pas que cet utilitaire effectue notre transformation. Son commentaire sur l’altération n’impose pas non plus à lui seul une plage.

La [politique d’orthographe de CapoSkill](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs), distincte, choisit une préférence de notation en dièses ou en bémols pour une classe de hauteur. Cette politique n’est pas la transposition diatonique à deux coordonnées déduite ici.

### Exercice 5 : préparer une vérification d’importation avec l’aide des sources

Lisez les définitions et le code, puis proposez une comparaison délimitée avant d’ajouter un nouveau DSL de notation ou d’annoncer une importation réussie.

> **Réponse:** Conservez la hauteur orthographiée d’origine, les décalages déclarés entre l’écrit et le sonore, l’orthographe et le numéro cibles visés, la révision du code et la politique d’altérations prise en charge. Testez les deux branches enharmoniques, les limites d’octave et les inverses avec des résultats attendus indépendants ; conservez ou rejetez explicitement les contextes non pris en charge. Comparez une petite transformation typée avant d’ajouter un DSL. L’inspection du code et les calculs actuels n’établissent ni correction d’analyseur, ni importation dans une application, ni partition rendue, ni résultat de lecture sonore.
