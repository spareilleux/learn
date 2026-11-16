---
title: Tester un réglage de brillance dans le moteur de guitare GA
description: "Acoustique de la guitare : tester un réglage de brillance dans GA WASM — Acoustique de la guitare et synthèse sonore"
sidebar:
  label: GAS-002 · Tester un réglage de brillance dans le moteur de guitare GA
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-002-brightness-control-and-evaluation-gate.fr.md
---

:::note[Streeling University]
**GAS-002** · Acoustique de la guitare : tester un réglage de brillance dans GA WASM · intermédiaire · 35 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-002-brightness-control-and-evaluation-gate.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-audio-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'acoustique et de synthèse de guitare** | Niveau : intermédiaire | Étape : Albedo | Durée : 35 minutes | Traduction IA provisoire ; révision en attente

## Objectifs

À la fin de cette leçon, vous saurez repérer le réglage de brillance du moteur de guitare GA, calculer sa valeur effective pour deux notes et concevoir un test à un seul paramètre assorti de conditions explicites d'acceptation et d'échec. Vous distinguerez une modification de coefficient d'une variation spectrale mesurée, une fixture native du moteur d'une sortie AudioWorklet du navigateur, et un critique hors ligne existant d'un candidat ComfyUI proposé.

## Question du projet et sources

[GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/) a établi une paire pédagogique délibérément limitée : un mi2 à vide enregistré et un mi2 rendu par GA. La [fixture GAS-001 épinglée](https://github.com/GuitarAlchemist/Demerzel/tree/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001) possède un [relevé de mesures](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json) et des [notes de provenance](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md). Le WAV GA est un **rendu natif** du code Rust épinglé, avec le profil 0 par défaut et `engine_note_on(82.4069, 0.1)`, à 44,100 Hz. Ce n'est pas un enregistrement de l'AudioWorklet du navigateur. Le fichier externe est un enregistrement attribué séparément, étiqueté mi2 à vide par son jeu de données ; ses conditions d'enregistrement n'ont pas été observées indépendamment.

Le relevé de mesures indique un niveau du deuxième partiel par rapport au premier de **+7.0 dB** pour l'enregistrement et de **−16.9 dB** pour le rendu GA, dans une fenêtre spectrale d'une seconde définie par rapport à l'attaque. L'écart vaut 23.9 dB pour ce *rapport entre partiels au sein de chaque fichier*. Ce n'est pas un écart de sonie globale de 23.9 dB ; l'instrument enregistré, le microphone, la pièce et la force de jeu ne sont pas contrôlés par rapport à la source synthétique. **Modifier le réglage de brillance du moteur réduirait-il cet écart mesuré précis sans dégrader la hauteur, le niveau, la décroissance ou les autres notes ?** Il faut un nouveau rendu contrôlé pour répondre. Cette leçon déduit un test du code épinglé ; le candidat n'a pas été exécuté.

### Exercice 1 — Interpréter correctement l'écart

Soustrayez le rapport deuxième/premier partiel du rendu GA de celui du fichier enregistré. Précisez le signe et ce que mesure le résultat. Peut-on parler d'une préférence des auditeurs ?

> **Réponse :** `+7.0 − (−16.9) = +23.9 dB` : le deuxième partiel enregistré est 23.9 dB plus élevé *par rapport à son propre premier partiel* que ne l'est le deuxième partiel du rendu par rapport au premier partiel de ce rendu. Il s'agit d'une comparaison spectrale dans une fenêtre sélectionnée, pas d'un écart de sonie sur les fichiers entiers ni d'une préférence mesurée des auditeurs.

## 1. Suivre le paramètre avant de le modifier

Le [moteur Rust GA à la révision `dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) initialise un moteur et appelle `set_guitar_profile(0)`. Ce profil fixe la valeur de base `brightness = 0.80`, ainsi que la décroissance, la dispersion, la décroissance de l'attaque et la réverbération. La fonction exportée `engine_set_brightness` limite la valeur de base fournie à `[0, 1]`. Une expérience proposée peut comparer la valeur `0.80` de ce profil à `0.90`, en appliquant le setter **après** avoir choisi le profil. Choisir un profil ultérieurement réécrit une valeur de brillance de profil et peut remplacer la valeur testée. Cet ordre d'appels mérite de figurer dans le journal d'exécution.

Le [pont audio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/audioEngine.js) du navigateur envoie `set_brightness` avec le nombre fourni par l'appelant. L'[AudioWorklet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js) ne transmet ce message au setter Rust que lorsque `ready` vaut vrai. Son gestionnaire asynchrone `init` ne définit `ready` qu'après avoir créé le moteur WASM et envoie un statut d'initialisation. La fonction `initAudioEngine` du pont renvoie un nœud après avoir envoyé `init` ; ce retour ne prouve pas à lui seul que le worklet a atteint l'état `ready`. Pour un essai dans le navigateur, observez son statut d'initialisation réussie, choisissez le profil, réglez la brillance, puis déclenchez la note. Sinon, un message de brillance trop précoce peut être ignoré, ou un choix ultérieur de profil peut remplacer le réglage. Le WAV GAS-001 n'a pas emprunté ce chemin de messages du navigateur.

Ce paramètre est une valeur de base, pas le coefficient final de chaque note. Un test exploitable consigne l'ordre de sélection du profil, d'appel du setter et de déclenchement de la note, ainsi que la révision exacte du code. N'inscrire que « brillance 0.90 » serait ambigu si un autre appel avait réinitialisé la valeur.

### Exercice 2 — Préserver le réglage voulu

Dans un essai proposé pour le navigateur, une personne appelle `setEngineBrightness(node, 0.90)` immédiatement après le retour de `initAudioEngine`, puis choisit le profil de guitare 0. Donnez deux raisons pour lesquelles le `0.90` voulu pourrait ne pas régir la note. Quel ordre l'expérience doit-elle consigner ?

> **Réponse :** Le worklet peut ne pas être encore `ready` et ne transmet donc pas le message de brillance ; choisir ensuite le profil 0 remet la brillance de base à `0.80`. Consignez, dans cet ordre, l'initialisation réussie du worklet, la sélection du profil 0, l'appel du setter de brillance avec `0.90`, puis l'événement de note. Le setter limite les valeurs à `[0, 1]` ; aucune de ces lignes de code ne prouve que cet essai a été exécuté.

## 2. Calculer ce qu'utilise réellement la boucle DSP

Dans `excite`, le moteur limite la vélocité à `[0, 1]` et définit `pluck_mix = clamp(0.15 + 0.35 × velocity, 0.05, 0.7)`. Pendant le rendu, il calcule `f_norm = clamp((frequency − 82) / (330 − 82), 0, 1)`, puis utilise

`effective_brightness = clamp(base_brightness + 0.45 × f_norm + 0.30 × pluck_mix, 0, 1)`.

Ce coefficient mélange un chemin de rétroaction plus brillant avec un état de filtre passe-bas. Il ne règle pas directement l'amplitude du deuxième partiel. Le moteur façonne aussi l'excitation, le bruit d'attaque, la dispersion, la décroissance, la résonance de la caisse et la réverbération. Augmenter le coefficient constitue donc une **hypothèse** plausible de modification du spectre du mi2, pas une correction calculée de 23.9 dB. La mesure doit déterminer si ce rapport précis évolue, et d'autres contrôles doivent établir si le son reste utilisable.

Pour le mi2 nominal de la fixture, à `82.4069 Hz` et avec une vélocité de `0.1`, `pluck_mix = 0.185` et `f_norm = 0.4069 / 248 ≈ 0.001641`. Le coefficient effectif du profil par défaut vaut `0.80 + 0.45(0.001641) + 0.30(0.185) ≈ 0.85624` ; la valeur de base proposée de `0.90` donne `≈ 0.95624`. Ce sont des calculs tirés d'un chemin du code source, pas une nouvelle mesure audio. À `330 Hz`, avec la même vélocité, `f_norm = 1` et les deux sommes dépassent 1 : les deux coefficients effectifs sont donc plafonnés à `1`. Une modification qui agit sur ce coefficient pour mi2 n'agit pas nécessairement sur celui de cette note plus aiguë. Elle pourrait néanmoins avoir des effets sur d'autres chemins ou dans d'autres conditions ; seul un rendu permet d'établir le résultat audio.

### Exercice 3 — Calculer le plafonnement

Pour une vélocité de `0.1`, calculez `pluck_mix` et la brillance effective à `82.4069 Hz` pour les valeurs de base `0.80` et `0.90`. Quelles sont les deux valeurs effectives à `330 Hz`, et qu'en déduire sur l'extrapolation d'un test de mi2 ?

> **Réponse :** `pluck_mix = 0.15 + 0.35(0.1) = 0.185` ; `f_norm ≈ 0.001641`. La brillance effective du mi2 vaut environ `0.85624` avec la base `0.80` et `0.95624` avec la base `0.90`. À 330 Hz, `f_norm = 1`, ce qui donne les sommes `1.3055` et `1.4055` ; toutes deux sont plafonnées à `1`. Le coefficient de brillance du code ne démontre pas qu'une modification spectrale du mi2 se généralise à 330 Hz, ni que l'un des rendus sonne mieux.

## 3. Définir un critère d'acceptation avant d'écouter un candidat

Prenez la fixture native existante de mi2 comme référence de départ, et non comme mesure du navigateur. Un futur test natif à un seul réglage initialiserait le même moteur épinglé à 44,100 Hz, conserverait le profil 0, la fréquence mi2 de `82.4069 Hz`, la vélocité de `0.1`, la durée du rendu, les fenêtres d'analyse et les autres réglages, et ne ferait passer que la brillance de base de `0.80` à `0.90`, après le choix du profil. Utilisez un moteur neuf pour chaque bras afin de rendre comparables l'état d'initialisation et la graine de bruit fixe du code. Conservez les WAV de référence et candidat avec leurs empreintes et le journal des paramètres et de leur ordre d'application. Si la question porte sur la restitution dans le navigateur, répétez le test séparément via l'AudioWorklet et capturez sa sortie ; un résultat natif ne certifie pas le chemin du navigateur.

Un **critère pédagogique proposé** consiste à réduire d'au moins 3.0 dB l'erreur absolue du rapport du deuxième partiel par rapport à la référence enregistrée de +7.0 dB, depuis l'écart initial de 23.9 dB. L'erreur du candidat doit donc être au plus de **20.9 dB**, avec la même méthode de mesure relative à l'attaque. Il s'agit d'un seuil de test déclaré à l'avance, pas d'une norme GA établie empiriquement. Prévenez l'écrêtage en exigeant une crête mesurée inférieure à 0.95 en amplitude normalisée ; maintenez le contrôle de la fondamentale mi2, la comparaison de décroissance et les rendus d'autres notes et vélocités. Examinez le comportement tardif des partiels du candidat : un bon rapport FFT local peut masquer une attaque ou une décroissance peu naturelle. Si un garde-fou échoue, n'acceptez pas le changement de réglage au seul motif que le deuxième partiel a évolué dans le sens souhaité.

Ce critère ne tranche pas la question du réalisme perçu. Après les mesures, comparez en aveugle des copies d'écoute à niveau égalisé et aux attaques alignées, et conservez les jugements individuels. Une référence mi2 fixe issue d'un instrument enregistré est une sonde utile, pas une cible universelle pour toutes les guitares. Un candidat qui franchit ce seuil pédagogique numérique peut encore échouer à l'écoute ou aux contrôles sur plusieurs notes.

### Exercice 4 — Calculer le seuil proposé

Quelle erreur absolue maximale satisferait la règle d'amélioration proposée de 3.0 dB à partir de l'écart initial de 23.9 dB ? Si un futur candidat satisfaisait ce seul seuil spectral mais écrêtait, la proposition l'accepterait-elle ? Un tel candidat a-t-il été mesuré ici ?

> **Réponse :** `23.9 − 3.0 = 20.9 dB` d'erreur absolue maximale par rapport au rapport enregistré de +7.0 dB, avec la même méthode. Non : l'écrêtage enfreint un garde-fou distinct ; l'évolution d'un seul rapport de partiels ne suffit donc pas. Aucun candidat de brillance n'a été rendu ou mesuré pour cette leçon.

## 4. Garder un candidat hors ligne dans un bras distinct

La [boucle hors ligne](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/full-auto.ps1) épinglée de GA enregistre une itération, applique éventuellement une coloration DDSP lorsque `GA_USE_DDSP=1`, et appelle des critiques locaux et spectraux. Ce sont des étapes existantes inspectées ; elles ne constituent pas un transfert vers ComfyUI. Un mi2 **proposé**, généré ou traité par ComfyUI, relève d'un bras candidat hors ligne distinct, aux côtés de la référence enregistrée d'origine et du rendu GA de référence inchangé. Une comparaison reproductible exigerait l'empreinte du WAV source, le JSON du workflow, le modèle et sa version, la graine, les réglages, l'empreinte de sortie, le format et les droits d'utilisation. Vérifiez qu'il représente toujours un événement mi2 isolé avant de le mesurer par rapport à la même référence.

La sortie ComfyUI ne constitue ni une modification du moteur Rust/WASM ni un substitut à son rendu contrôlé. Elle pourrait suggérer un timbre cible ou soulever une question sur l'excitation, mais le paramètre du moteur doit être évalué sur une sortie réelle de ce moteur. Le critique spectral existant suggère des ajustements possibles à partir de caractéristiques résumées ; son score ne valide pas le réalisme de la guitare et n'identifie pas un réglage causal unique. L'acceptation dépend toujours de la procédure de mesure épinglée, des garde-fous, de contrôles sur plusieurs notes et de preuves d'écoute.

### Exercice 5 — Classer le troisième bras

Un agent propose un WAV ComfyUI brillant sans workflow, version de modèle, graine ni empreinte source. Peut-il servir de preuve que la brillance de base `0.90` a amélioré le moteur WASM de GA ? Nommez les éléments de provenance manquants et la comparaison requise du moteur.

> **Réponse :** Non. Le WAV est un candidat hors ligne non traçable, pas une sortie du moteur. Conservez les empreintes source et de sortie, le workflow, le modèle et sa version, la graine, les réglages, le format et les droits ; vérifiez qu'il s'agit d'un mi2 isolé. Produisez ensuite un rendu du moteur GA épinglé en ne changeant que la brillance, comparez-le à son propre rendu de référence avec la même méthode et les mêmes garde-fous, et recueillez séparément des jugements d'écoute à niveau égalisé. Aucune exécution ComfyUI ni comparaison de ce type n'a été réalisée ici.

## Limites et prochaine vérification

L'écart de 23.9 dB est une mesure sauvegardée pour un mi2 à vide enregistré et un mi2 rendu nativement, dans les fenêtres indiquées par rapport à l'attaque. Les valeurs de brillance effective sont calculées à partir du code épinglé ; ce ne sont pas des variations enregistrées d'énergie harmonique. Le candidat proposé de `0.90`, le seuil d'acceptation, la séquence de messages du navigateur, le balayage de plusieurs notes, le bras ComfyUI et le test d'écoute n'ont pas été exécutés. Avant de modifier GA, capturez un candidat contrôlé et vérifiez l'ordre de ses paramètres, l'identité du WAV, la hauteur, les rapports de partiels, l'attaque et la décroissance, les crêtes, le comportement du navigateur lorsque pertinent, et les jugements de musiciens. La revue humaine du contenu, les tests auprès d'apprenants, la validation linguistique, la synchronisation et la compilation Learn, la relecture anonyme et la publication restent en attente.
