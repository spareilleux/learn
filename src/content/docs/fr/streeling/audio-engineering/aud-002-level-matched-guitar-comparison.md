---
title: Comparer un rendu de guitare GA à niveau de lecture égalisé
description: Comparer un rendu de guitare GA à niveau de lecture égalisé — Ingénierie audio
sidebar:
  label: AUD-002 · Comparer un rendu de guitare GA à niveau de lecture égalisé
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-002-level-matched-guitar-comparison.fr.md
---

:::note[Streeling University]
**AUD-002** · Comparer un rendu de guitare GA à niveau de lecture égalisé · intermédiaire · 30 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-002-level-matched-guitar-comparison.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-audio-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d’ingénierie audio** | Niveau : intermédiaire | Durée estimée : 30 minutes | Statut : brouillon français ; validation du contenu, relecture linguistique par une personne maîtrisant le français, essais par des apprenants et publication en attente

## Objectifs

À la fin de cette leçon, vous saurez :

- Conserver l’identité et la provenance des WAV enregistré et synthétisé avant de créer des copies d’écoute.
- Aligner les premiers événements musicaux et calculer un ajustement approximatif du gain à partir de la même fenêtre RMS après le début de la note.
- Expliquer pourquoi égaliser le niveau initial ne rend pas deux enveloppes ou deux timbres identiques.
- Définir une comparaison audio réfutable et un protocole d’écoute en aveugle de portée limitée.

## La question du projet

Le moteur de guitare natif de GA, écrit en Rust, a synthétisé un mi grave à vide, E2. Un autre E2 à vide, enregistré, sert de référence pédagogique. Si les auditeurs entendent le fichier GA à un niveau beaucoup plus élevé, peuvent-ils juger équitablement son timbre par rapport à l’enregistrement ? Non : le niveau de lecture et le calage temporel font partie du protocole de comparaison. [GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/) présente le parcours général des preuves, de l’enregistrement à l’expérience sur le moteur. AUD-002 se concentre sur la **vérification d’ingénierie audio préalable à un jugement A/B** : figer les sources, aligner les premiers événements, égaliser le niveau dans une fenêtre déclarée et préserver les différences que cette égalisation ne contrôle pas. Cette leçon n’enseigne pas la théorie de la FFT, de la STFT ou des ondelettes sous-jacente aux mesures du jeu de référence.

Ce cas est fixé à la révision source de Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b`. Le [dossier du jeu de référence GAS-001](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) identifie les fichiers sources, la licence, les réglages de rendu, les empreintes, le script de mesure et les limites. Les deux WAV durent quatre secondes, sont mono et sont échantillonnés à 44 100 Hz. Le fichier enregistré est attribué à collegefishiesd sous licence CC BY-SA 4.0 ; le jeu de données l’étiquette `low_E`, corde à vide, E2. Le WAV GA est un rendu natif du code Rust fixé, **pas** une capture de la sortie AudioWorklet du navigateur. Un verdict d’écoute sur cette paire ne validerait donc pas la lecture dans le navigateur.

### Exercice pratique 1 : figer les entrées

Le README du jeu de référence donne pour `deb-low-e-open.wav` l’empreinte SHA-256 `03a1965f…7f38b248` et pour `ga-engine-e2-open-4s.wav` l’empreinte SHA-256 `a78a7024…7866c3f98`. Une personne exporte un MP3 plus fort et remplace le WAV GA dans le répertoire du jeu de référence. Peut-on encore utiliser les mesures et la provenance existantes sans les modifier ?

> **Réponse :** Non. Conservez les WAV d’origine et leurs empreintes complètes comme entrées immuables. Placez toute copie d’écoute dont le gain, le découpage ou l’encodage a changé à un nouveau chemin, avec sa transformation et son empreinte. Remplacer le fichier rompt le lien entre la mesure consignée, les réglages de rendu et les octets ; le MP3 avec perte modifie aussi le signal. Le README fournit les empreintes complètes et l’attribution.

## 1. Aligner l’événement plutôt que l’en-tête du fichier

Le [script de mesure](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measure-pair.py) utilise des débuts de première note approximatifs de **1,1 seconde** pour l’enregistrement et de **0,0 seconde** pour le rendu GA. Le fichier enregistré comporte une amorce silencieuse et une autre attaque vers **2,75 secondes**. Choisissez des extraits de même longueur commençant chacun au début de leur première note. Un extrait proposé de 1,5 seconde couvre les temps fichier **1,1–2,6 secondes** dans l’enregistrement et **0,0–1,5 secondes** dans le rendu ; il s’arrête avant la deuxième attaque enregistrée. Appliquez les mêmes fondus aux limites des copies d’écoute et consignez-les dans le journal de session. Les repères de début sont des estimations : inspectez la forme d’onde et répétez les mesures clés après un léger déplacement des repères avant de considérer une différence limite comme stable.

Pour les valeurs existantes du jeu de référence, la fenêtre RMS initiale se situe **0,2–0,4 seconde après chaque début de première note**. Cela correspond aux temps fichier **1,3–1,5 secondes** dans l’enregistrement et **0,2–0,4 seconde** dans le rendu. La vérification tardive se situe **1,0–1,2 seconde après le début**, soit aux temps fichier **2,1–2,3 secondes** dans l’enregistrement et **1,0–1,2 seconde** dans le rendu. Ces fenêtres précèdent la deuxième attaque de l’enregistrement. Ce sont des fenêtres de mesure ; elles ne prouvent pas que les deux interprétations ont un pincement identiquement calé dans le temps.

### Exercice pratique 2 : choisir les bonnes fenêtres

Un analyste compare les deux fichiers entre les temps fichier absolus 0,2 et 0,4 seconde et qualifie la référence de « silencieuse ». Donnez les fenêtres initiales et tardives corrigées, en temps fichier, pour chaque WAV.

> **Réponse :** Par rapport aux débuts approximatifs des premières notes, la fenêtre initiale est 1,3–1,5 secondes dans l’enregistrement et 0,2–0,4 seconde dans le rendu ; la fenêtre tardive est 2,1–2,3 secondes dans l’enregistrement et 1,0–1,2 seconde dans le rendu. Le segment 0,2–0,4 seconde du fichier de référence fait partie de son amorce : ce n’est donc pas la bonne fenêtre de comparaison.

## 2. Égaliser le niveau d’une fenêtre sans effacer le résultat

Le [JSON de mesures fixé](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json) indique un RMS initial de **−34,6 dBFS** pour l’enregistrement et de **−16,6 dBFS** pour le rendu GA. Le rendu est **18,0 dB plus fort** dans cette *fenêtre alignée précise*. Pour égaliser approximativement cette fenêtre, atténuez une **copie d’écoute** du rendu GA de 18,0 dB, soit un multiplicateur d’amplitude de `10^(-18/20) ≈ 0.126`. Conservez les WAV sources sans modification. Le jeu de référence consigne des pics absolus sur l’ensemble du fichier de 0,1297 pour l’enregistrement et de 0,4602 pour le rendu ; après cette atténuation uniforme, le pic de la copie du rendu serait d’environ `0.4602 × 0.126 ≈ 0.058`, avant tout autre traitement. C’est une prédiction fondée sur le gain seul, pas une mesure d’un nouveau fichier.

Ne vous contentez pas d’augmenter l’enregistrement de 18 dB : son pic de 0,1297 sur l’ensemble du fichier passerait à environ **1,03** en amplitude normalisée, avec un risque d’écrêtage lors d’un export en virgule fixe. Pour cette paire, atténuer la branche la plus forte est le choix simple et sûr. Consignez le gain, les unités, le traitement des canaux et de la fréquence d’échantillonnage, le découpage, les fondus et l’empreinte de sortie. Si un appareil de mesure indique un niveau différent après export, arrêtez-vous et cherchez la cause avant l’écoute.

Cette égalisation RMS de la fenêtre initiale est un **contrôle du protocole**, pas une égalité de sonie perçue. Un auditeur peut encore entendre des différences d’attaque, d’équilibre spectral, de coloration liée à la pièce ou au microphone et de décroissance. Un gain scalaire unique ne peut pas corriger ces différences. Pour un extrait plus long ou une autre tâche, choisissez et justifiez une méthode de sonie plus adaptée ; ne changez pas de méthode sans le signaler au milieu de la comparaison d’un candidat.

### Exercice pratique 3 : calculer le gain de lecture

À partir des RMS initiaux fixés de −34,6 et −16,6 dBFS, calculez le gain en dB de la copie d’écoute GA et son multiplicateur linéaire d’amplitude approximatif. Ce gain démontre-t-il que le moteur GA est désormais aussi réaliste que l’enregistrement ?

> **Réponse :** Il faut appliquer `−34.6 − (−16.6) = −18.0 dB` à la copie GA, soit multiplier les amplitudes de ses échantillons par `10^(−18/20) ≈ 0.126`. Cela égalise approximativement une fenêtre RMS mesurée. Cela n’égalise ni le timbre, ni l’attaque, ni la décroissance, ni la chaîne d’enregistrement, ni le réalisme perçu.

## 3. Vérifier l’écart restant et écouter en aveugle

Le même JSON de mesures indique un RMS tardif de **−38,5 dBFS** pour l’enregistrement et de **−17,7 dBFS** pour le rendu brut. L’application du même gain de −18,0 dB prédit **−35,7 dBFS** pour la fenêtre tardive du rendu, encore **2,8 dB au-dessus** du RMS tardif de l’enregistrement. Autrement dit, l’enregistrement baisse de **3,9 dB** entre les fenêtres initiale et tardive, tandis que le rendu baisse de **1,1 dB**. Un gain uniforme préserve l’évolution interne de chaque fichier. Cela ne prouve pas quelle note paraît la plus naturelle ; cela révèle une différence d’enveloppe pour le début approximatif et les fenêtres choisis dans ce jeu de référence.

Pour une vérification à l’écoute, préparez des copies sans perte de la première note à partir des WAV fixés. Appliquez le gain documenté ainsi qu’un découpage et des fondus identiques ; vérifiez les niveaux initiaux obtenus et l’absence d’écrêtage. Randomisez l’identité et l’ordre A/B, masquez les noms de fichiers et les formes d’onde, gardez la chaîne de lecture et le volume fixes, puis consignez la réponse de chaque auditeur avant de révéler les identités. Posez une question précise, par exemple quelle version ressemble le plus à un unique E2 joué à vide, et demandez une justification libre. Consignez le nombre d’auditeurs et d’essais, leur expérience, les conditions et les désaccords. Aucun résultat d’écoute en aveugle de ce type ne figure dans le jeu de référence. Même une préférence pour l’enregistrement mêlerait les différences d’interprétation, d’instrument, de microphone, de pièce, de traitement et de synthèse ; elle n’isolerait pas un paramètre du moteur GA.

### Exercice pratique 4 : tester ce que l’égalisation n’a pas corrigé

Après application de −18,0 dB à la copie GA, quel RMS tardif est prédit ? Quel est son écart par rapport à la fenêtre tardive de l’enregistrement et quelle affirmation est réfutée ?

> **Réponse :** La valeur tardive du rendu devient environ `−17.7 − 18.0 = −35.7 dBFS`, soit `−35.7 − (−38.5) = 2.8 dB` de plus que la fenêtre tardive enregistrée. L’affirmation « égaliser le RMS initial égalise aussi l’enveloppe tardive » échoue pour ces mesures arrondies. Ce n’est pas un verdict d’écoute.

## 4. Rendre la prochaine modification réfutable

L’écart initial-tardif de 2,8 dB de la référence de départ fournit un point de départ mesurable, sans en faire automatiquement une cible d’optimisation. Une modification proposée du moteur doit déclarer les paramètres modifiés, la révision source de GA, les réglages de rendu, la nouvelle empreinte WAV et une politique de fenêtres et de repérage des débuts définie à l’avance. Une règle **illustrative et non approuvée** pourrait exiger qu’un nouveau candidat ramène l’écart initial-tardif absolu sous **1,8 dB** (au moins 1,0 dB de moins que cette référence de départ), conserve un pic E2 selon la même méthode, évite l’écrêtage et passe une vérification de préférence en aveugle consignée séparément. Le seuil de 1,8 dB est un choix pédagogique, pas une norme d’acceptation GA ni un seuil perceptif. Un candidat qui manque l’une des conditions préétablies échoue à cette vérification proposée ; réussir sur cet unique E2 ne démontrerait toujours pas le réalisme général d’une guitare.

### Exercice pratique 5 : définir un critère de réfutation

Un agent affirme qu’un nouveau réglage de brillance de GA améliore la guitare synthétisée parce qu’une valeur spectrale s’est rapprochée de la référence. Proposez une prochaine comparaison réfutable avec ce jeu de référence et indiquez quel résultat ferait rejeter l’affirmation.

> **Réponse :** Figez les empreintes de la référence enregistrée et du rendu de départ, produisez un candidat documenté à partir d’une révision GA fixée, appliquez les mêmes méthodes de repérage du début, d’extraction et d’égalisation du niveau initial au rendu de départ et au candidat, puis comparez l’écart tardif déclaré, les vérifications du pic et de la hauteur, et les réponses d’écoute en aveugle. Selon la règle **illustrative** ci-dessus, un candidat présentant un écart de 1,8 dB ou plus, de l’écrêtage, un échec de la vérification E2 ou aucune préférence d’écoute étayée ne passe pas. Aucune exécution de candidat ni aucun résultat d’écoute n’est revendiqué ici ; le déplacement d’une seule caractéristique spectrale ne démontre pas une amélioration.

## À retenir

- Calculez les empreintes des WAV enregistré et synthétisé d’origine et conservez-les ; transformez de nouvelles copies pour l’écoute.
- Alignez les premiers débuts de note avant de choisir les mêmes fenêtres relatives.
- Un gain fixe peut égaliser une fenêtre RMS tout en laissant un écart mesuré de 2,8 dB dans la fenêtre tardive.
- Des étiquettes anonymisées réduisent le biais d’attente, mais n’éliminent pas les différences de source, d’interprétation, de microphone ou de pièce.
- Décidez des critères de mesure et d’écoute avant de tester un candidat, puis rapportez aussi bien les réussites que les échecs.

## Preuves du projet et limites

- Révision Demerzel fixée `5c4967454ddc740ed937c87719ca4d71a3522e4b` : [provenance et licence du jeu de référence](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md), [WAV enregistré](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/deb-low-e-open.wav), [WAV natif GA](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/ga-engine-e2-open-4s.wav), [code de mesure](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measure-pair.py) et [résultats de mesure](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json). Les empreintes des deux WAV ont été vérifiées par rapport au README et au JSON. Ce sont des entrées pédagogiques fixes, pas des captures WASM du navigateur.
- Tous les calculs de gain, de pic et de fenêtre tardive de cette leçon sont déduits des valeurs arrondies du jeu de référence. Aucun WAV avec gain appliqué ni aucune session d’écoute en aveugle n’a été produit pour AUD-002. Les positions de début sont approximatives et le RMS initial n’est qu’une règle possible d’égalisation du niveau.
- Ces liens WAV relatifs à la source se résolvent dans Demerzel ; une publication Learn doit inclure l’audio ou fournir des liens publics stables vers les ressources.
- Le brouillon anglais source n’a franchi aucune validation du contenu, relecture linguistique, essai par un apprenant, synchronisation ou compilation Learn, ni vérification publique anonyme. Ce texte français reste lui aussi un brouillon ; validation du contenu, relecture linguistique par une personne maîtrisant le français, essais par des apprenants et publication sont en attente.
