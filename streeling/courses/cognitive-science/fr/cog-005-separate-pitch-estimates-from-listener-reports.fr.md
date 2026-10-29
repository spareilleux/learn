---
module_id: cog-005-separate-pitch-estimates-from-listener-reports
department: cognitive-science
course: "Distinguer les estimations de hauteur des réponses des auditeurs"
level: intermediate
prerequisites: ["cog-004-score-a-pitch-discrimination-task", "gas-005-separate-a-partial-peak-from-a-period"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer les estimations de hauteur des réponses des auditeurs

> **Portée du brouillon.** Comparaisons originales de signaux mathématiques et préparation d’une tâche d’écoute. Les revues humaines technique, musicale ou perceptive et linguistique, les essais apprenants et la vérification du HTML déployé restent à faire. Aucun participant, stimulus diffusé, réponse perceptive ou résultat d’apprentissage n’a été observé.

## La question du projet

Un agent de guitare prédit une fréquence de répétition, puis considère qu’un auditeur qui rapporte une autre hauteur se trompe. Il a remplacé la question « qu’a entendu la personne ? » par « quelle réponse correspond à mon algorithme ? ». Un exercice utile de dogfooding garde ces deux résultats distincts.

Le [résumé indexé de la synthèse d’Oxenham de 2012](https://pubmed.ncbi.nlm.nih.gov/23015422/) présente la fréquence de répétition comme un corrélat physique majeur de la hauteur tout en soulignant des interactions qui compliquent la perception. Seul ce résumé a été lu pour cette leçon ; aucun protocole ou enregistrement de l’article complet n’a été reproduit. Les exemples originaux ci-dessous comparent des prédictions numériques explicites. Ils n’établissent ni perception universelle ni classement d’un auditeur individuel.

## 1. Définir la réponse avant de choisir son corrigé

Une tâche technique peut demander la période fondamentale d’un signal fourni. Sa réponse découle des mathématiques déclarées. Une tâche perceptive peut demander au participant lequel de deux sons lui paraît plus aigu, ou lui demander d’ajuster un son de référence. Le résultat est alors une réponse enregistrée, avec ses propres unités et sa propre procédure. Ce n’est pas automatiquement la même variable qu’un pic spectral, un décalage de récurrence, une préférence de réalisme ou un score d’apprentissage.

Si l’objectif est l’exactitude algorithmique par rapport à une fréquence construite connue, déclarez cette référence et la règle de notation. Si l’objectif est d’étudier la perception, conservez la réponse du participant avant de l’interpréter. « Différent du détecteur » peut être une observation ; « faux » exige un critère justifié propre à la tâche.

### Exercice 1 : séparer les résultats

Un évaluateur demande « Quel son paraît plus aigu ? », mais ne note que l’accord avec un résultat d’autocorrélation. Quelle distinction a disparu et que faut-il conserver ?

> **Réponse:** L’évaluateur a substitué une référence technique définie par le modèle à une réponse perceptive. Conservez la question réelle, les conditions des stimuli, le choix ou l’ajustement du participant, ainsi que la prédiction distincte de l’algorithme. L’accord peut être analysé sous une hypothèse explicite, mais il ne définit pas rétroactivement ce que le participant a entendu et ne mesure ni le réalisme ni l’apprentissage.

## 2. Construire des prédictions numériques opposées

Les [contrôles originaux](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/synthetic-periods.json) utilisent des sommes de cosinus de phase nulle d’une seconde, d’amplitudes 0.3, 0.2 et 0.1 à une fréquence d’échantillonnage de 48000 Hz :

| Complexe | Composantes fournies, Hz | Composante la plus forte, Hz | Fréquence fondamentale de répétition, Hz |
| --- | --- | --- | --- |
| A | 1000, 1200, 1400 | 1000 | 200 |
| B | 1050, 1200, 1350 | 1050 | 150 |

La composante la plus forte monte de 50 Hz de A à B, tandis que la fréquence de répétition baisse de 50 Hz. Leurs variations en cents sont respectivement d’environ +84.467193470 et -498.044999135. Ce sont deux comparaisons numériques opposées, pas une prédiction selon laquelle chaque auditeur devrait suivre l’une d’elles ou même percevoir une seule hauteur non ambiguë.

### Exercice 2 : conserver le conflit

Quel complexe est plus haut selon la comparaison des composantes les plus fortes, et lequel selon la comparaison des fréquences fondamentales de répétition ? Ce tableau peut-il déterminer à lui seul le choix d’un véritable participant ?

> **Réponse:** B est plus haut selon la comparaison des composantes les plus fortes, 1050 contre 1000 Hz. A est plus haut selon la répétition fondamentale, 200 contre 150 Hz. Le conflit mathématique motive une tâche de réponse ; il ne fournit aucun choix observé chez un participant et ne prouve pas que toute perception suit une seule règle.

## 3. L’égalisation mathématique des niveaux ne certifie pas la lecture audio

Pour les contrôles cohérents sans fondu, la moyenne des carrés vaut `(0.3²+0.2²+0.1²)/2 = 0.07` ; les deux valeurs RMS valent donc environ 0.264575131. Leurs crêtes à phase nulle sont de 0.6. Ces égalités concernent les tableaux d’origine. L’analyse n’a généré aucun WAV d’écoute et n’a rien diffusé.

Un véritable essai exige des fichiers audio préparés, un traitement des attaques et des fins, un niveau et un format vérifiés, une chaîne de lecture documentée et une procédure qui ne révèle pas la réponse attendue. L’application de fondus modifie les tableaux ; mesurez à nouveau les fichiers réels au lieu de recopier leur valeur RMS sans fondu dans leurs métadonnées. L’égalité numérique des RMS n’établit pas non plus une sonie perçue égale et ne supprime pas tous les indices spectraux.

### Exercice 3 : distinguer un jeu de contrôle d’un essai prêt à mener

Calculez la moyenne des carrés et la valeur RMS mathématiques. Un agent ajoute ensuite des fondus et affirme que les stimuli finaux sont déjà égalisés et testés. Quelles preuves manquent ?

> **Réponse:** La moyenne des carrés vaut 0.07 et la valeur RMS environ 0.264575131 pour chaque tableau cohérent sans fondu. Les fichiers réels après fondu et encodage exigent des empreintes, de nouvelles mesures de niveau et de crête, les conditions de lecture et un essai de présentation documenté. L’égalité du calcul sans fondu ne constitue ni un test de lecture exécuté ni une sonie perçue égale. Aucun fichier d’écoute n’a été produit et aucun participant n’a été recruté ici.

## 4. Garder indépendants l’ordre, les consignes et l’interprétation

Avant un futur essai, définissez la réponse du participant, les consignes, la familiarisation autorisée, l’ordre de présentation et l’analyse. Contrebalancez les présentations A/B et B/A sans dévoiler les étiquettes mathématiques. Enregistrez l’identité réelle des stimuli, leur ordre, la réponse et les exclusions éventuelles. N’entraînez pas les participants à choisir la réponse du détecteur tout en prétendant étudier une perception spontanée.

Un contrôle par sons purs non ambigu peut vérifier si le participant a compris le sens de comparaison demandé dans les conditions indiquées. Il n’établit pas qu’un complexe ambigu doive être jugé à partir du même indice. Une tâche d’ajustement de son peut révéler d’autres informations qu’une comparaison forcée ; changer la tâche change le résultat étudié. [COG-004](cog-004-score-a-pitch-discrimination-task.md) traite séparément les clés de réponse et le calcul exact des résultats dus au hasard.

### Exercice 4 : corriger une procédure biaisée

L’interface étiquette A « 200 Hz, correct » avant de demander quel son semble plus aigu. L’évaluateur qualifie ensuite tout désaccord d’erreur auditive. Proposez une meilleure procédure et une interprétation limitée à ce qu’elle permet d’établir.

> **Réponse:** Masquez les étiquettes du modèle pendant la tâche perceptive, déclarez la question et l’ordre contrebalancé, conservez les réponses réelles et utilisez des contrôles de compréhension adaptés. Comparez ensuite les réponses aux prédictions distinctes de l’algorithme sous une hypothèse déclarée. Un désaccord seul ne diagnostique pas un problème auditif et ne prouve pas que le participant a mal compris un complexe ambigu. Aucun test de ce type avec des participants n’a eu lieu ici.

## 5. Fournir des preuves différentes pour des décisions différentes

Pour étalonner un détecteur, utilisez les périodes construites connues et des tolérances définies explicitement. Pour une tâche d’accordage du moteur, conservez la référence de l’estimateur, son incertitude et les entrées réellement rendues. Pour une affirmation de perception ou de préférence, exigez la procédure correspondante avec participants et ses observations. Pour l’apprentissage, exigez une évaluation appropriée des apprenants. Renommer un score numérique ne fournit aucune de ces preuves.

L’[analyse de guitare conservée](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json) contient quatre estimations de récurrence à score élevé qui échouent à son contrôle déclaré de proximité à la référence nominale. C’est un avertissement concret sur l’interprétation des scores, pas une preuve de ce qu’un guitariste a entendu. La tâche préparée dans ce dossier reste inexécutée et aucun de ses résultats n’est encore renseigné.

### Exercice 5 : rédiger la conclusion de l’agent

Un agent affirme : « Une forte confiance en la périodicité prouve que les auditeurs préfèrent la guitare corrigée. » Remplacez cette phrase par des affirmations étayées et indiquez les preuves manquantes.

> **Réponse:** Le score de récurrence décrit l’accord entre formes d’onde selon l’estimateur déclaré ; ce n’est pas une confiance perceptive étalonnée. Les contrôles construits vérifient certaines prédictions mathématiques, et les résultats des fenêtres conservées échouent au contrôle déclaré par rapport à la référence nominale. La hauteur perçue par les auditeurs, leur préférence pour la guitare et tout bénéfice d’une correction exigent leurs propres stimuli réels, protocole de comparaison et réponses. Aucune correction, préférence ou observation d’écoute n’a été constatée ici.
