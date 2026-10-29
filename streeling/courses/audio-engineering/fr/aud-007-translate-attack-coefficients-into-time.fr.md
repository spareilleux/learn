---
module_id: aud-007-translate-attack-coefficients-into-time
department: audio-engineering
course: "Traduire les coefficients d'attaque en durées"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries", "gas-002-brightness-control-and-evaluation-gate"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Traduire les coefficients d'attaque en durées

> **Portée du brouillon.** Code public à une révision précise et calculs isolés d'enveloppe en arithmétique réelle. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun nouveau rendu natif/WASM, aucune capture de navigateur ni aucun traitement [ComfyUI](https://docs.comfy.org/) n'ont été réalisés.

## La question du projet

Un coefficient est copié d'une configuration audio à une autre. L'attaque dure-t-elle le même nombre de millisecondes ? La réponse dépend de ce que le code multiplie et de l'horloge qui fait avancer ce calcul. Nous examinons la révision de GA `76efbffd5af82b46c3146957a6bd4504008eeb89` ; les profils d'anciens jeux d'essai ne lui sont pas substitués silencieusement.

## 1. Retracer le coefficient effectif

Le [constructeur et la sélection de profil](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L184-L260) initialisent d'abord la décroissance de l'attaque à 0.988, puis appellent le profil 0, qui écrit 0.986. Le [parcours de rendu par voix](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L426-L478) calcule `r=clamp(base_attack_decay-0.004*f_norm,0.97,0.993)`. La normalisation de fréquence passe de 0 à 82 Hz à 1 à 330 Hz.

Pour le point de référence pédagogique de 82 Hz, la vélocité 1 et le profil 0, le niveau initial d'attaque est 0.06 et r vaut 0.986. Ce point de référence est exactement à 82 Hz ; ce n'est pas la valeur E2 plus précise de 82.4069 Hz utilisée dans d'anciens jeux d'essai audio. Le [tableau d'enveloppe fixé](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/attack-clock.json) conserve les deux fréquences séparément.

### Exercice 1 : choisir la véritable valeur de départ

Un agent lit le 0.988 du constructeur et le présente comme le multiplicateur effectif d'attaque à 82 Hz du profil 0. Qu'est-ce qui l'écrase ? Donnez les bonnes valeurs de base et effective pour ce point de référence. Que vaut r à 330 Hz ?

> **Réponse:** La sélection du profil remplace le champ du constructeur par 0.986. Au point de référence de 82 Hz, la normalisation de fréquence vaut 0 ; les multiplicateurs de base et effectif valent donc tous deux 0.986. À 330 Hz, la normalisation vaut 1 et le multiplicateur effectif est 0.982 après soustraction de 0.004. Aucun de ces résultats n'est une décroissance audio observée.

## 2. Convertir les mises à jour en secondes

Tant que la voix est active et que le niveau d'attaque dépasse son seuil, le code le multiplie une fois par échantillon de sortie. Dans le modèle isolé en arithmétique réelle, `A[n]=A0*r^n`, où n compte les multiplications achevées et `A[0]` est l'état initial. Pour r positif et inférieur à 1, la constante de temps exacte du prolongement continu est `tau=-1/(Fs*ln(r))` secondes. Cela suit la [démonstration de la constante de temps d'un filtre à un pôle](https://www.dsprelated.com/freebooks/filters/Time_Constant_One_Pole.html).

Pour r à 0.986, tau vaut environ 1.6083309868956657 ms à 44100 échantillons par seconde et 1.4776540942103929 ms à 48000. Une constante de temps correspond à un facteur d'amplitude de `1/e` ; ce n'est ni le temps jusqu'au silence, ni une durée de décroissance de 60 dB, ni la durée du son entier de la guitare. Le signal de bruit, la rétroaction de la corde, la caisse et la réverbération possèdent d'autres états.

### Exercice 2 : comparer les horloges

Maintenez r à 0.986 et faites passer la fréquence d'échantillonnage de 44100 à 48000. Quelle constante de temps est la plus courte, et pourquoi ? Ce calcul prédit-il la durée de la note rendue entière ?

> **Réponse:** Le cas à 48000 est plus court : environ 1.4776540942103929 ms contre 1.6083309868956657 ms. Davantage de multiplications ont lieu par seconde avec le même multiplicateur par échantillon. Le calcul décrit seulement l'état d'attaque isolé ; il ne prédit donc pas la durée de la note complète, de la réponse de la caisse ou de la réverbération.

## 3. Respecter le seuil d'arrêt du code

La [branche d'attaque](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L467-L478) ne s'exécute que tant que l'état courant dépasse `1e-3`. Pour A0 à 0.06 et r à 0.986, le premier entier n vérifiant `A0*r^n<=1e-3` est 291. Après 290 mises à jour, l'état vaut environ 0.0010056725203252386 ; après 291, il vaut environ 0.0009915931050406854. Les contributions de cette trace isolée utilisent les états avant mise à jour d'indices 0 à 290, puis la branche s'arrête.

Ces 291 mises à jour par échantillon occupent environ 6.598639455782313 ms à 44100 et 6.0625 ms à 48000. Le code conserve l'état après le franchissement ; il ne continue pas à le multiplier vers zéro dans cette branche. Sa condition de désactivation de voix exige aussi un niveau d'attaque inférieur à `5e-5`, ce que cette valeur conservée ne satisfait pas. C'est un point de vigilance sur le cycle de vie déduit du code pour le parcours sélectionné, conservé dans le [relevé d'observation](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/source-observations.json). Aucune reproduction à l'exécution, conséquence sur le CPU ou correction de production n'est revendiquée.

### Exercice 3 : compter la dernière mise à jour

Combien de contributions d'attaque précèdent l'arrêt au seuil dans la trace isolée ? L'état conservé est-il nul ? Sa valeur conservée peut-elle satisfaire la partie portant sur le niveau d'attaque dans le contrôle de désactivation de voix examiné ?

> **Réponse:** Il y a 291 contributions utilisant les indices 0 à 290, chacune suivie d'une mise à jour. L'état conservé vaut environ 0.0009915931050406854, et non zéro. Il est supérieur à `5e-5` ; il ne satisfait donc pas cette partie de la condition de désactivation. Ce raisonnement fondé sur le code et le modèle n'est ni une défaillance reproduite à l'exécution ni une preuve concernant tous les parcours du cycle de vie.

## 4. Traduire délibérément une durée cible

Pour préserver cette constante de temps isolée, posez `r_new=r_old^(Fs_old/Fs_new)`. Transposer r effectif à 0.986 de 44100 à 48000 donne environ 0.9871301472688642. Cela modifie délibérément le multiplicateur pour préserver les millisecondes. Cela ne préserve pas automatiquement le même nombre entier de mises à jour jusqu'au seuil, car le franchissement final est arrondi aux mises à jour par échantillon.

La transposition concerne le coefficient effectif. Aux autres fréquences, le code soustrait son terme dépendant de la fréquence et borne à nouveau le résultat ; copier ce nombre dans un mutateur de base n'est pas automatiquement une compensation générale. La sélection de profil peut aussi écraser un réglage effectué par un mutateur. Une modification du moteur entier exigerait une politique définie, des tests à plusieurs fréquences et vélocités, ainsi que des contrôles de tous les autres états dépendant des échantillons.

### Exercice 4 : traduire le coefficient

Quel multiplicateur effectif préserve à 48000 la constante de temps de r à 0.986 pour la fréquence d'échantillonnage 44100 ? Ce calcul suffit-il à établir un moteur entièrement indépendant de la fréquence d'échantillonnage ou un correctif de production ?

> **Réponse:** Environ 0.9871301472688642. Il préserve la constante de temps isolée du prolongement continu selon la formule déclarée. La quantification du seuil, l'ajustement de fréquence, l'ordre des profils et les autres états de traitement numérique du signal exigent encore leurs propres politiques et tests ; aucune invariance du moteur entier ni aucun correctif de production n'ont été établis.

## 5. Suivre l'horloge de l'hôte jusque dans le test

Le [pont Web Audio](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/src/audio/audioEngine.js#L14-L35) transmet `audioContext.sampleRate` dans son message d'initialisation. Le [worklet](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js#L11-L30) transmet la fréquence numérique fournie à l'initialisation du moteur, avec un repli sur la fréquence de l'hôte. La [spécification Web Audio](https://www.w3.org/TR/webaudio/#dom-baseaudiocontext-samplerate) définit la propriété de fréquence d'échantillonnage du contexte. Ces lectures du code n'observent ni la fréquence actuelle ni une capture d'un navigateur en fonctionnement.

Un futur essai devrait consigner la fréquence réelle du contexte, l'état d'initialisation, le profil sélectionné, l'ordre des mutateurs, les réglages de note, le format brut des échantillons et l'identité de la sortie. Comparez les traces d'état d'attaque séparément de la forme d'onde complète ; le signal stochastique n'est pas une enveloppe exponentielle positive. Si un candidat ComfyUI hors ligne est rééchantillonné, conservez cette conversion et comparez les fenêtres de temps physique visées. Son existence ne change pas le sens des coefficients du moteur.

### Exercice 5 : rédiger la prochaine vérification

Un rapport indique « même réglage de décroissance, même durée d'attaque », mais omet la fréquence d'échantillonnage et l'ordre des profils. Nommez les preuves manquantes et un témoin négatif utile. Une comparaison de navigateur à deux fréquences a-t-elle été effectuée ici ?

> **Réponse:** Consignez la fréquence d'échantillonnage réelle de l'hôte, la réussite de l'initialisation, le profil et l'ordre des mutateurs, le coefficient effectif dépendant de la fréquence, la note et la vélocité, le format des échantillons et l'identité de la sortie. Un calcul d'enveloppe à r fixe et deux fréquences est un témoin négatif, car il doit modifier les millisecondes ; une transposition préservant la durée devrait conserver la constante de temps isolée déclarée. Aucune capture de navigateur à deux fréquences ni comparaison perceptive n'ont été réalisées ici.
