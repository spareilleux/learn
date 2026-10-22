---
module_id: mcl-004-model-timing-without-inventing-a-style
department: musicology
course: "Modéliser le placement temporel sans inventer un style"
level: intermediate
prerequisites: ["mcl-003-style-labels-as-evidence", "mus-004-rhythm-and-groove"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Modéliser le placement temporel sans inventer un style

> **Périmètre du brouillon.** Annotations inventées de partition et de pseudo-interprétation, calculs exacts et examen de sources à une révision fixe. Les revues techniques humaines, musicales, linguistiques et pédagogiques, ainsi que la vérification du HTML déployé du cours, restent à faire. Aucun enregistrement, auditeur ou style interprété n'a été évalué.

## La question du projet

Une leçon de GA demande à un agent d'expliquer un rythme. Doit-il décrire la grille écrite, ajuster un modèle temporel ou nommer un style musical ? Ce sont des affirmations différentes. Dans leur [résumé publié](https://online.ucpress.edu/mp/article-abstract/19/3/333/61900/Swing-Ratios-and-Ensemble-Timing-in-Jazz?redirectedFrom=fulltext), Friberg et Sundström rapportent des rapports temporels qui dépendent du tempo dans une sélection d'enregistrements de jazz. Leur [présentation hébergée par les auteurs](https://www.speech.kth.se/music/performance/Texts/ensemble_swing.htm) distingue aussi les rôles au sein de l'ensemble. Ces observations limitées invitent à ne pas traiter un rapport fixe comme une définition universelle du style. Seuls le résumé et la page des auteurs ont été lus ; aucun extrait audio associé n'a été écouté ou copié.

## 1. Séparer la partition et l'annotation dans deux colonnes

Utilisons les données pédagogiques originales suivantes. Les temps sont exprimés en unités absolues de noire ; les secondes sont des annotations créées pour l'exemple, pas des mesures extraites d'un enregistrement. C4 = MIDI 60 est notre convention de hauteur, mais ce tableau temporel ne contient ni hauteurs ni attribution instrumentale.

| Début écrit en temps | Début annoté en secondes |
| --- | --- |
| 0 | 0 |
| 0.5 | 0.34 |
| 1 | 0.52 |
| 1.5 | 0.84 |
| 2 | 1.04 |
| 2.5 | 1.37 |
| 3 | 1.56 |
| 3.5 | 1.88 |

La phrase se termine au temps 4 et à la seconde 2.08. Les intervalles entre les débuts de temps durent 0.52 seconde, ce qui correspond à environ 115.384615385 noires par minute. Cette cadence de référence ne place pas les contretemps écrits au milieu des intervalles annotés.

### Exercice 1 : situer un contretemps

Dans un modèle à subdivisions égales fondé sur l'espacement de 0.52 seconde entre débuts de temps, où tomberait le premier contretemps ? Quel écart le sépare du début annoté à 0.34 seconde, et cet écart constitue-t-il une erreur d'interprétation observée ?

> **Réponse:** La subdivision égale se situe à 0.26 seconde. Le début annoté arrive 0.08 seconde, soit 80 ms, plus tard. C'est un résidu par rapport au modèle choisi dans des données inventées. Ce n'est ni une faute observée, ni une étiquette de genre, ni une raison de demander à un interprète de changer.

## 2. Comparer les modèles avec un résidu défini

Un modèle régulier place chaque contretemps à mi-chemin dans son intervalle de temps. Un modèle fixe à 2:1 le place aux deux tiers de cet intervalle. Une fraction commune ajustée à partir de ces mêmes contretemps vaut `131/208`, soit un décalage de 0.3275 seconde dans chaque paire. Les débuts de temps restent aux points d'ancrage déclarés dans chaque modèle.

Sur les huit débuts de note, le résidu absolu moyen vaut 33.75 ms pour le modèle régulier, environ 9.583333333 ms pour le modèle fixe et 3.75 ms pour le modèle ajusté. Le [relevé temporel fixe](../../../../code/streeling/evidence/phrase-performance-2026-10-22/timing-models.json) conserve chaque prédiction et son résidu signé. Un résidu plus faible sur les données d'ajustement décrit l'adéquation à ces données ; il ne mesure pas la qualité musicale. Le modèle ajusté a utilisé les données mêmes sur lesquelles il est évalué : cette comparaison n'apporte donc aucune validation indépendante.

### Exercice 2 : retrouver la fraction ajustée

Les décalages de contretemps dans les paires valent 0.34, 0.32, 0.33 et 0.32 seconde. Calculez leur décalage commun par moindres carrés, puis sa fraction de la paire de 0.52 seconde. Quelle affirmation le plus petit résidu rapporté ne permettrait-il toujours pas de soutenir ?

> **Réponse:** Le décalage moyen vaut 0.3275 seconde ; en le divisant par 0.52, on obtient `131/208`. Le modèle obtenu a un résidu absolu moyen de 3.75 ms sur les huit débuts de note. Le plus petit résidu sur les données d'ajustement n'établit ni le genre, ni un groove préférable, ni le niveau d'un musicien, ni un bénéfice pour l'auditeur.

## 3. Une instruction de lecture n'est pas une annotation d'interprétation

L'[élément swing de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/swing/) peut spécifier un rapport pour la lecture concernée. Ses champs entiers strictement positifs `first` et `second` décrivent cette instruction ; ils n'identifient pas la provenance d'un tableau de débuts observés. Une instruction fixe à 2:1 donnerait un décalage d'environ 0.346666667 seconde dans chaque paire avec notre espacement de référence, sans reproduire les quatre décalages distincts de l'exemple.

Ne déduisez pas de la spécification qu'une chaîne complète d'importation, d'exportation ou de lecture est implémentée. Cette leçon n'en a exécuté aucune. Les conditions d'application, les types de notes et les modifications temporelles comptent pour réaliser une véritable conversion. [MUS-024](../../music/en/mus-024-preserve-attacks-and-harmonic-boundaries.md) traite séparément de la continuité des événements de note et des unités.

### Exercice 3 : limiter l'affirmation sur l'exportation

Un agent remplace le tableau par une seule instruction de lecture à 2:1 et promet une reproduction exacte. Quelles différences subsistent, et que faudrait-il pour affirmer une véritable fidélité ?

> **Réponse:** Un décalage commun proche de 0.346666667 seconde ne reproduit pas les décalages distincts de 0.34, 0.32, 0.33 et 0.32. L'instruction est un modèle, pas les annotations originales. Une reproduction exacte demanderait de conserver les détails temporels, de tester la conversion et d'observer le résultat selon les règles d'application pertinentes. Rien de cela n'a été exécuté ici.

## 4. Quantifier la perte d'une représentation précise du code source

Au commit GA `dc2e74cbd992a298f67efb928b5b3754615e1924`, l'[analyseur MIDI](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/MidiParser.fs) examiné convertit les microsecondes par noire en BPM entier avec `60000000 / microsecondsPerQuarter`. Pour 520000 microsecondes, la division entière donne 115, alors que la cadence de référence vaut environ 115.384615385.

Si un composant hypothétique en aval reconstruisait quatre noires à partir de 115 BPM, il obtiendrait environ 2.086956522 secondes au lieu de 2.08, soit une différence d'environ 6.956521739 ms. Il s'agit d'un calcul conditionnel appuyé sur le code source. Aucun analyseur, importateur ou parcours de lecture n'a été exécuté, et ce calcul n'établit ni une dérive réelle de GA ni une différence perceptible. Les [types MIDI](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs), dans un fichier distinct, déclarent aussi des deltas en ticks et un champ de division temporelle ; ces déclarations ne constituent pas à elles seules une chronologie d'interprétation cumulée.

### Exercice 4 : distinguer une conséquence modélisée d'un bogue observé

Calculez le BPM entier et la durée hypothétique de quatre noires à partir de la valeur donnée en microsecondes. L'agent peut-il qualifier la différence obtenue de défaillance de lecture observée ?

> **Réponse:** Le BPM entier vaut 115. La durée reconstruite vaut `240/115` secondes, soit environ 2.086956522, ce qui dépasse 2.08 d'environ 6.956521739 ms. Non : ce calcul caractérise un choix de représentation pour un composant hypothétique. Affirmer une défaillance réelle exige un parcours testé et une sortie capturée.

## 5. Préserver l'ordre en changeant de coordonnées temporelles

Reliez les points d'ancrage temps/secondes par une même fonction strictement croissante, linéaire par morceaux, et appliquez-la à chaque début et fin de note. Comme elle préserve l'ordre, deux intervalles de note semi-ouverts se chevauchent avant la conversion exactement lorsqu'ils se chevauchent après. L'[exemple d'occupation des cordes](../../guitar-studies/en/gtr-005-plan-which-string-keeps-ringing.md) reste donc irréalisable avec son chevauchement dû à l'entrée anticipée de D et sa limite de case après cette transformation commune.

Déplacer uniquement le début de D du temps 1.5 au temps 2 est une autre opération. Dans cette transformation créée pour l'exemple, il passe de 0.84 à 1.04 seconde, soit 200 ms, alors que sa fin reste fixe. Cela peut modifier le chevauchement et raccourcir la note. L'alternative de 250 ms présentée dans [GAA-005](../../guitar-alchemist-academy/en/gaa-005-repair-a-phrase-without-hiding-the-change.md) suppose, elle, une cadence constante de 120 noires par minute. Ne mélangez pas ces références.

### Exercice 5 : expliquer pourquoi la quantification n'est pas neutre

Appliquer la même fonction strictement croissante à toutes les limites résout-il un conflit d'occupation des cordes ? En quoi le déplacement d'un seul début diffère-t-il ?

> **Réponse:** La transformation commune préserve chaque chevauchement et donc la faisabilité de l'affectation dans ce modèle. Déplacer un seul début peut modifier le chevauchement, l'articulation et la durée par rapport à une fin inchangée. C'est une modification musicale qui demande une intention explicite, pas un simple changement d'unités temporelles ni la preuve d'un meilleur style.
