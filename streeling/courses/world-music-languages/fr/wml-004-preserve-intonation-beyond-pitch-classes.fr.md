---
module_id: wml-004-preserve-intonation-beyond-pitch-classes
department: world-music-languages
course: "Préserver l’intonation au-delà des classes de hauteur"
level: intermediate
prerequisites: ["wml-002-dadgad-layout-and-cultural-claims"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préserver l’intonation au-delà des classes de hauteur

> **Périmètre du brouillon.** Examen de sources publiques à une révision précise et calculs à partir de fréquences construites. La revue technique humaine, la revue par un musicien, la relecture linguistique, les essais par des apprenants et la vérification du HTML déployé restent à faire. Aucune pratique musicale interprétée, aucun rendu audio de GA ni aucun résultat d’écoute n’est mesuré ici.

## La question du projet

Un agent transmet une gamme d’un catalogue à un outil pour guitare et affirme que son intonation a été préservée. Quelles informations permettraient d’étayer cette affirmation ? Dans le [modèle des gammes du monde de Guitar Alchemist](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/WorldScalesConfig.fs), les intervalles sont documentés comme des nombres entiers de demi-tons, les classes de hauteur comme des valeurs dans un système à douze degrés, et l’accordage comme une annotation textuelle. Ces champs servent à rechercher dans le catalogue. Ils ne définissent pas de fréquence ni de valeur en cents structurée pour chaque degré.

Le champ d’accordage du modèle est une simple chaîne de caractères, pas une énumération imposée dans la définition examinée. La lecture d’un modèle ne permet pas d’établir que toutes les valeurs du catalogue sont validées, ni de déduire le comportement de tous les sous-systèmes de GA. Ce cours suit des interfaces précises au commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

## 1. Conserver l’indication d’approximation

L’[entrée Rast enregistrée](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/WorldScales/MaqamScales.yaml) contient les intervalles `[2,2,1,2,2,2,1]`, les classes de hauteur `[0,2,4,5,7,9,11]`, le masque 2741 et l’annotation d’accordage `approx-12tet`. La reconstruction du masque par la somme de `1 << p` pour ces classes de hauteur donne 2741. L’annotation doit accompagner le résultat : l’approximation enregistrée dans ce système à douze degrés ne constitue pas une description certifiée de l’intonation interprétée.

La [page Rast de MaqamWorld](https://maqamworld.com/en/maqam/rast.php), écrite par un musicien, présente les relations entre jins et des exemples du répertoire. Un même masque de classes de hauteur ne permet pas d’établir ces relations, le phrasé, la pratique ou l’identité musicale. Aucun enregistrement lié n’a été copié, écouté ou analysé dans ce dossier. Ne transformez pas un texte de catalogue non relu en autorité musicale.

### Exercice pratique 1 : interpréter un masque identique

Un agent trouve le masque 2741 à la fois dans cette entrée Rast et dans un ensemble de classes de hauteur d’une gamme majeure. Qu’est-ce qui coïncide, et quelle annotation doit rester visible ?

> **Réponse :** C’est l’ensemble sélectionné de classes de hauteur dans le système à douze degrés qui coïncide. Conservez `approx-12tet`, la tradition indiquée par l’entrée et l’identité de sa source. Cette correspondance n’établit ni une pratique d’interprétation équivalente, ni une intonation exacte, ni une signification musicale interchangeable.

## 2. Mesurer l’information perdue par une projection

Prenez A4 = 440 Hz et la formule de référence à douze degrés `f(m)=440*2^((m-69)/12)`. C4, associé au numéro MIDI 60 avec cette référence, vaut 261.625565301 Hz. Construisez un son à `f_a=(5/4)*f(60)` et un autre à `f_b=f(64)`. Leurs fréquences sont respectivement 327.031956626 Hz et 329.627556913 Hz.

Un [cent musical](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z) correspond à un rapport de fréquences de `2^(1/1200)`. Ainsi, `1200*log2(f_a/f(60))` donne 386.313713865 cents, tandis que le second son se situe 400 cents au-dessus de la tonique de référence. Le premier est 13.686286135 cents plus bas que le second. Cet exercice sur les rapports est une construction mathématique originale. **Il ne prescrit pas un degré au rapport 5:4 pour Rast ni pour aucune tradition.**

### Exercice pratique 2 : retrouver le décalage

Calculez la distance en cents entre la tonique de référence et la construction au rapport 5:4, puis son décalage signé par rapport au son situé à 400 cents. Ce calcul spécifie-t-il l’interprétation de Rast ?

> **Réponse :** `1200*log2(5/4)` donne 386.313713865 cents. En soustrayant 400, on obtient -13.686286135 cents. Le signe indique que le premier son construit est plus bas. Le calcul établit uniquement une relation de rapport ; il ne spécifie la pratique d’interprétation d’aucune tradition.

## 3. Distinguer une projection définie pour le cours d’un convertisseur observé

Définissez une projection pédagogique : calculez `u=69+12*log2(f/440)`, puis choisissez le degré entier le plus proche. Les deux sons construits donnent environ 63.863137139 et 64 ; cette règle les associe donc tous deux au numéro MIDI 64. Si seul cet entier est conservé, leur différence disparaît. Cette règle a été définie pour le cours ; aucun convertisseur de fréquence vers MIDI de GA n’a été exécuté ni certifié ici.

Deux possibilités de transmission, proposées à titre indicatif, préservent la cible construite : la fréquence 327.031956626 Hz avec la référence A4 = 440 Hz, ou MIDI 64 avec un décalage de -13.686286135 cents et la même référence. Ce sont des exemples pédagogiques, pas un schéma ratifié ni un contrat entre dépôts déjà implémenté. La référence, les unités, la provenance et le statut d’approximation doivent accompagner le sens que l’on souhaite transmettre.

### Exercice pratique 3 : corriger l’affirmation sur la transmission

Les deux sons arrivent sous la forme MIDI 64. Le destinataire peut-il retrouver leur différence initiale ? Proposez une valeur à conserver pour les distinguer, sans prétendre qu’un nouveau schéma de GA existe.

> **Réponse :** L’entier seul ne permet pas de retrouver cette différence. Conservez une fréquence et sa référence, ou MIDI 64 avec un décalage explicite en cents et une référence. Le décalage du premier son est de -13.686286135 cents ; celui du second est de 0. Présentez ces enregistrements comme des exemples indicatifs et conservez leur provenance. Leur présence dans ce cours ne prouve pas qu’ils sont pris en charge par une implémentation.

## 4. Suivre la représentation réelle de chaque interface

L’[objet valeur MidiNote](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/MidiNote.cs) représente un entier de 0 à 127, avec une classe de hauteur calculée modulo 12. Le [mapper de positions sur le manche](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Analysis/FretboardPositionMapper.cs) soustrait le numéro MIDI de la corde à vide du numéro MIDI cible, puis vérifie l’étendue des frettes. Ces interfaces précises sont discrètes.

À l’inverse, le [point d’entrée audio Rust](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) accepte `freq:f32` dans `engine_note_on` et transmet cette valeur à l’excitation. Un argument de fréquence en virgule flottante constitue une autre représentation. Sa signature seule ne prouve pas qu’un rendu produit fidèlement la hauteur demandée. Préservez la cible tout au long du parcours, puis mesurez le signal obtenu avant d’en affirmer la fidélité.

### Exercice pratique 4 : repérer le test restant

Un destinataire accepte une fréquence en virgule flottante. Cela prouve-t-il qu’un décalage a survécu à la recherche dans le catalogue, au placement sur le manche et à la synthèse audio ? Indiquez les preuves encore nécessaires.

> **Réponse :** Non. Suivez la cible conservée, sa référence et ses unités à travers chaque interface, repérez toute projection discrète, puis comparez la fréquence du rendu à la cible voulue. L’argument flottant montre qu’une valeur est acceptée à un point d’entrée ; il ne certifie ni la transmission en amont ni le son obtenu.

## 5. Adapter la conclusion à la sonde

La [sonde réelle des noms d’intervalles de GA](../../../../code/streeling/evidence/intonation-listening-2026-10-22/ga-intervals-probe.json), interrogée pour C, a renvoyé `P1, M3, P5`. Elle n’a renvoyé ni fréquence, ni cents, ni référence d’accordage, ni interprétation, ni révision des sources exécutées. Le [relevé de calcul](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json) contient séparément la construction définie pour le cours et les champs du catalogue. Ne les assemblez pas pour annoncer une réussite de bout en bout qui n’a pas été observée.

### Exercice pratique 5 : rédiger une conclusion délimitée pour l’agent

Un agent affirme : « La sonde d’intervalles confirme que le moteur de guitare préserve l’intonation de Rast. » Remplacez cette phrase par une conclusion étayée par le dossier.

> **Réponse :** La sonde pour C a renvoyé des noms d’intervalles. Les sources à la révision indiquée exposent une approximation de Rast à douze degrés et, séparément, un point d’entrée audio à fréquence flottante. Le calcul construit montre comment une projection vers un entier peut perdre une différence en cents. La préservation dans un pipeline réel, la validité musicale et les résultats d’écoute restent à vérifier.

## Preuves et prochaine expérience

Le [relevé des sources publiques](../../../../code/streeling/evidence/intonation-listening-2026-10-22/primary-readback.json) rattache huit fichiers au commit indiqué. [PHY-007](../../physics/en/phy-007-separate-beating-from-decay.md) utilise les mêmes fréquences construites pour étudier les interférences ; [COG-004](../../cognitive-science/en/cog-004-score-a-pitch-discrimination-task.md) distingue une séparation numérique d’un résultat d’écoute observé. Un futur cours consacré à une tradition devra faire l’objet d’une revue par un musicien et s’appuyer sur des interprétations pertinentes avant de formuler des affirmations sur la pratique.
