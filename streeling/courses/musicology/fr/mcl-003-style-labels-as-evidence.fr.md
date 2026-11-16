---
module_id: mcl-003-style-labels-as-evidence
department: musicology
course: "Musicologie : les étiquettes de style comme preuves"
level: intermediate
alchemical_stage: albedo
prerequisites: [mcl-002-musical-form]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: musicology-2026-10-11-003
version: "0.1.0"
---

# Quand une étiquette de style constitue-t-elle une preuve ?

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de musicologie** | Niveau : intermédiaire | Étape : Albedo | Durée : 35 minutes | Brouillon français ; révision, notamment par une personne maîtrisant le français, en attente

## Objectifs

Après cette leçon, vous saurez distinguer une étiquette de catalogue d'une observation sur une interprétation, lire un enregistrement de progression sans ajouter implicitement des détails absents, comparer les entrées au bon niveau et rédiger pour Guitar Alchemist (GA) une légende de style précisant sa source. Vous saurez aussi définir ce qu'une future vérification à l'écoute doit consigner avant de justifier une affirmation sur un enregistrement réel.

## Question du projet et périmètre des preuves

GA possède un [catalogue de progressions](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/ChordProgressions.yaml) versionné avec des champs tels que `Name`, `RomanNumerals`, `Category`, `Chords`, `Structure` et `Examples`. Il possède aussi un [enregistrement du domaine](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Harmony/Progressions/ProgressionCorpusItem.cs) distinct déclarant `StyleLabel`, `Chords` et `Source`. Les deux liens figent le commit GA `dc2e74cbd992a298f67efb928b5b3754615e1924`. **Quand un écran GA peut-il afficher la `Category` d'une progression comme métadonnée du catalogue, et quelles preuves étayeraient une affirmation sur le style d'une interprétation enregistrée ?**

Le catalogue répond à la première partie : il indique ce qu'un éditeur a stocké à cette révision. Il ne peut pas répondre seul à la seconde. Une liste d'accords n'est ni de l'audio ni une transcription dont le placement temporel, l'instrumentation, l'articulation et le contexte ont été vérifiés indépendamment. Les exemples de chansons et listes `UsedBy` du catalogue sont aussi des affirmations de la source ; cette leçon ne les traite pas comme une histoire musicale vérifiée. La propriété obligatoire `Source` du code impose de transmettre l'attribution ; elle ne prouve pas que chaque instance a été auditée indépendamment. Le YAML et l'enregistrement C# sont des artefacts distincts ; cette leçon n'affirme pas qu'un chargeur ou une correspondance les relie.

[MCL-002](mcl-002-musical-form.md) présentait la forme. Ici, l'attention porte sur les preuves derrière une **étiquette de style**. Une catégorie de catalogue et une interprétation écoutée répondent à des questions différentes.

## 1. Lire l'unité qui porte l'étiquette

Commencez par l'enregistrement de premier niveau `ii-V-I`. Il contient `Category: "Jazz"`, `InKey: "C Major"`, les chiffres romains `ii7, V7, I` et les accords `Dm7, G7, Cmaj7`. Ce sont quatre champs distincts. L'étiquette appartient à l'entrée du catalogue ; ce n'est pas une propriété mesurée sur une forme d'onde particulière. La tonalité et l'écriture des accords expliquent comment cette instance figure dans le fichier. Elles n'établissent ni que chaque interprétation d'un ii–V–I utilise ces voicings, ni qu'il s'agit toujours de jazz, ni que les chansons citées utilisent cette séquence exacte à chaque occurrence.

Un écran GA peut dire : « `ii-V-I` — catégorie dans le catalogue GA : Jazz ; exemple en do majeur : Dm7–G7–Cmaj7. » Le mot *catalogue* donne sa provenance à l'étiquette. « Enregistrement de jazz » exigerait des preuves portant sur l'interprétation.

Le code `ProgressionCorpusItem` souligne le problème d'attribution. `StyleLabel` et `Source` sont des chaînes obligatoires, et `Chords` vaut par défaut une liste vide en lecture seule. Une valeur obligatoire peut provenir d'un éditeur, d'un interprète, d'un auditeur ou d'un classifieur. Une interface ou un export de données devrait indiquer la source et le type d'affirmation plutôt que de traiter `StyleLabel` comme une validation.

### Exercice 1 — Extraire sans renforcer l'affirmation

À partir du catalogue figé, donnez la catégorie, la tonalité, les chiffres romains et les noms d'accords de `ii-V-I`. Rédigez ensuite une légende permise et une légende non étayée pour un enregistrement que vous n'avez pas écouté.

> **Réponse :** Catégorie `Jazz` ; tonalité `C Major` ; chiffres romains `ii7, V7, I` ; accords `Dm7, G7, Cmaj7`. Permis : « Le catalogue GA classe `ii-V-I` dans Jazz et donne Dm7–G7–Cmaj7 en do majeur. » Non étayé : « Cet enregistrement non écouté est du jazz parce qu'il contient Dm7–G7–Cmaj7. » Le fichier fournit les champs de la première phrase ; il ne fournit aucune observation de l'enregistrement.

## 2. Compter ce qui est encodé ; distinguer les descriptions

L'entrée `12-Bar Blues` fournit un indice structurel plus fort qu'un nom seul. Sa liste `RomanNumerals` possède douze positions : `I, I, I, I, IV, IV, I, I, V, IV, I, V`. Sa liste `Chords` en possède aussi douze : `E, E, E, E, A, A, E, E, B, A, E, B`. L'entrée indique `InKey: "E Major"` et `Category: "Blues"`. Si chaque position représente une mesure dans le modèle prévu par l'entrée, les positions 5 et 6 sont `IV`/`A` ; la position 9 est `V`/`B` ; la position 12 est `V`/`B`, un turnaround possible vers le premier `I`/`E`. Le calcul des positions se vérifie dans le fichier. Le tempo réel, la durée des mesures, les reprises, les omissions et les qualités d'accords jouées restent inconnus.

Le champ `Structure` du même enregistrement indique « forme lyrique AAB sur 12 mesures ». Ses tableaux d'accords ne contiennent ni paroles ni audio et ne peuvent donc pas démontrer indépendamment une organisation des paroles en AAB. Nous pouvons rapporter la description du catalogue, mais pas affirmer que ses accords prouvent qu'un chanteur particulier a chanté des phrases AAB. Une prise donnée demanderait une vérification directe.

### Exercice 2 — Compter et situer

Combien de positions d'accords contient la liste `Chords` de premier niveau de `12-Bar Blues` figée ? Quelles sont les positions 5, 6, 9 et 12 ? Cette seule liste vérifie-t-elle la description lyrique AAB de l'entrée ?

> **Réponse :** Il y a douze positions. En numérotant à partir de un, 5 = `A`, 6 = `A`, 9 = `B` et 12 = `B`. Non : le tableau `Chords` contient des symboles d'accords, pas des mots ni une structure vocale enregistrée. AAB est une description supplémentaire du catalogue.

## 3. Une étiquette de forme n'est pas un arrangement interprété

`Rhythm Changes` illustre une autre structure d'enregistrement. Il contient `Category: "Jazz"` et `Structure: "AABA form with specific harmonic rhythm"`. Au lieu d'une liste `Chords` ou `RomanNumerals` de premier niveau, il possède une `ASection` et une `BSection`. La section A énumère `I, vi, ii, V` sur `Bb, Gm, Cm, F` ; la section B énumère `III, VI, ii, V` sur `D, G, Cm, F`. On peut comparer ces modèles de sections, mais pas les aplatir en une interprétation complète affirmée. La source ne précise ni le nombre de reprises de chaque segment de quatre accords, ni la durée des accords, ni le rythme harmonique réel, ni ce qu'un groupe particulier a joué.

« AABA » nomme un ordre de sections au-dessus des événements d'accords individuels. Esquisser A–A–B–A à partir des deux tableaux interprète le catalogue ; cela ne documente pas une prise. Une annotation d'interprétation exigerait les limites de sections, des horodatages et une référence d'enregistrement ou de partition. Cet enregistrement n'encode pas un nombre total de mesures.

### Exercice 3 — Identifier le premier niveau absent

Donnez le premier accord des `ASection` et `BSection` de `Rhythm Changes` et indiquez si l'enregistrement possède un tableau `Chords` de premier niveau. Qu'est-ce qui reste non vérifié concernant une interprétation ?

> **Réponse :** `ASection` commence par `Bb` ; `BSection` commence par `D`. L'enregistrement n'a pas de tableau `Chords` de premier niveau. Sa `Structure` AABA et ses tableaux de sections ne vérifient ni le placement temporel des sections, ni les reprises, ni la durée, ni l'instrumentation d'une interprétation particulière, ni même le respect du modèle par l'interprète.

## 4. La répétition d'un texte de catalogue n'est pas une corroboration indépendante

L'enregistrement `I-vi-IV-V` contient au premier niveau `Category: "Pop"`, un exemple en do majeur `C, Am, F, G` et un élément imbriqué `Variations` nommé `vi-IV-I-V`, avec `Am, F, C, G` et `Context: "Pop ballad version"`. La variation imbriquée ne déclare pas sa propre `Category` ; elle dépend d'un parent qui en possède une. Ailleurs, le même YAML contient une entrée distincte de premier niveau `vi–IV–I–V (Pop Loop)`, avec des tirets demi-cadratins dans son nom, `Category: "Pop"`, `InKey: "C Major"` et `Chords: ["Am", "F", "C", "G"]`.

Ces deux occurrences montrent le même ordre de quatre accords dans une variation imbriquée et une entrée autonome. Ce ne sont pas des études d'écoute indépendantes, ni des preuves que toute chanson utilisant ces accords est une ballade pop. Le `Context` de la variation est un texte éditorial, pas une caractéristique mesurée d'enregistrement. L'affichage devrait nommer la relation parent-enfant.

Pour une future étude stylistique, sélectionnez de véritables interprétations et consignez l'intervalle analysé, les caractéristiques observées, l'auteur de l'étiquette et les désaccords. Une séquence d'accords est une clé de recherche ; l'interprétation, la production et le contexte culturel comptent aussi. Définissez les étiquettes avant d'évaluer les exemples.

### Exercice 4 — Comparer les niveaux

Où `vi-IV-I-V` apparaît-il sous `I-vi-IV-V`, quels quatre accords utilise-t-il et comment l'entrée distincte de premier niveau `vi–IV–I–V (Pop Loop)` diffère-t-elle comme enregistrement ? La duplication valide-t-elle indépendamment un genre ?

> **Réponse :** C'est un élément `Variations` imbriqué avec `Context: "Pop ballad version"` et les accords `Am, F, C, G` ; il ne possède pas son propre champ `Category`. L'entrée autonome `vi–IV–I–V (Pop Loop)` est un enregistrement de premier niveau avec sa propre `Category: "Pop"` et le même ordre d'accords. Les deux sont des affirmations d'un seul catalogue ; leur répétition ne vérifie donc pas indépendamment le genre d'un enregistrement.

## 5. Rédiger une légende et une prochaine étape testable

Une légende GA rigoureuse distingue trois couches. D'abord, identifier l'**objet stocké** : une entrée de progression nommée à une révision figée. Ensuite, identifier l'**affirmation stockée** : une étiquette de catégorie ou de forme et les exemples d'accords explicitement énumérés. Enfin, préciser l'**état de l'évaluation de l'interprétation** : aucun enregistrement n'a été évalué ici. Ce modèle est utile même si le catalogue est exact, car le lecteur voit ce qui est vérifiable et ce qui exigerait un travail supplémentaire. Un lien de révision permet à un autre apprenant de reproduire la recherche ; un lien non figé pourrait pointer silencieusement vers des données modifiées.

Supposons qu'un écran présente le modèle `12-Bar Blues` à côté d'un enregistrement téléversé. Avant analyse, il peut dire : « Modèle du catalogue GA : Blues ; exemple en mi majeur, douze positions d'accords énumérées. » Il ne devrait pas encore dire « le fichier est une interprétation de blues ». Une future vérification pourrait demander à deux auditeurs formés de marquer les limites de sections et les événements d'accords sur un intervalle horodaté précis, conserver la référence audio et les versions d'annotations, puis comparer leurs résultats selon une règle de correspondance déclarée. Par exemple, exiger qu'au moins dix des douze positions harmoniques attendues correspondent dans l'ordre, en rapportant écarts et désaccords. Ce seuil est une **règle d'étude proposée**, pas un critère de genre validé ni un test exécuté pour ce brouillon. L'atteindre étayerait une correspondance au modèle ; un jugement stylistique plus large exigerait encore une grille définie et des preuves pertinentes sur l'interprétation.

La chaîne obligatoire `Source` de `ProgressionCorpusItem` pourrait renvoyer à un catalogue, une partition, une annotation ou un fichier audio. Son interprétation doit être propre à l'affirmation. Une future correspondance YAML-vers-corpus devrait être vérifiée avant de supposer `Category` et `StyleLabel` synchronisés.

### Exercice 5 — Choisir un texte produit défendable

Rédigez une phrase pour un écran GA montrant l'entrée `12-Bar Blues` du catalogue à côté d'un fichier téléversé non écouté. Nommez ensuite deux observations ou enregistrements nécessaires avant d'affirmer quelque chose sur son style interprété.

> **Réponse :** « Le modèle `12-Bar Blues` du catalogue GA est classé Blues et énumère douze positions d'accords en mi majeur ; le fichier téléversé n'a pas été évalué. » Pour une affirmation ultérieure, conservez un intervalle audio identifié avec annotations horodatées d'accords/sections et une grille stylistique explicite appliquée par des réviseurs identifiés ou un classifieur validé. L'entrée du catalogue étaye seulement la légende du modèle, pas le genre du fichier.

## Limites et fondement de recherche

Il s'agit d'une leçon de lecture des sources, pas d'analyse audio. Aucun enregistrement, édition de partition, transcription horodatée, résultat de classifieur ou accord entre auditeurs n'a été testé. Les descriptions du catalogue, exemples de chansons, noms `UsedBy` et implications historiques restent non vérifiés dans ce cycle. Le seuil d'écoute proposé sert à concevoir une vérification réfutable ; il n'a pas été calibré. Le code figé montre les déclarations d'un enregistrement du domaine, pas des contrôles de provenance à l'exécution ni un chemin d'importation YAML démontré. Révision humaine disciplinaire, essais d'apprenants et publication restent en attente ; ce brouillon français attend une révision par une personne maîtrisant le français.

Les preuves primaires sont le [catalogue de progressions GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/ChordProgressions.yaml) figé et la [déclaration `ProgressionCorpusItem`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Harmony/Progressions/ProgressionCorpusItem.cs) figée. La confiance accordée à cette leçon porte sur l'extraction des champs et décomptes de cette révision exacte, pas sur la vérité indépendante de ses associations de genres ou de chansons.
