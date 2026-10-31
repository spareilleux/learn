// The Observatory page's install block, at the top of src/content/docs/observatory/index.md and its fr/
// and es/ mirrors. It reads the name the browser gives the graphics card (WebGL's
// WEBGL_debug_renderer_info) and the system the browser runs on, and offers first the version for that
// system: the RTX installer on a GeForce RTX card under Windows, the native package under Linux (x86_64)
// or on a Mac, the web version otherwise; then a line with the other platforms' downloads; then, in a
// table, every feature the card has and what the Observatory does with it. Nothing leaves the page.
// The RTX 5080's measured figures are in the pages themselves; here, only what follows from a card's name.
(function () {
  'use strict';

  var VERSION = '0.3.1';  // the Windows program
  var NATIVE = '0.2.1';   // the Linux and macOS packages: 0.2.2 changed only the Windows program's Streamline, 0.2.3 its glass, 0.2.4 its path-traced gardens, 0.2.5 its Capitole, scooter and toys, 0.3.0 its shelves and Streamline 2.14.16, 0.3.1 its updater
  var LINKS = {
    rtx: 'https://github.com/spareilleux/learn/releases/download/observatory-rtx-0.3.1/Observatory-RTX-0.3.1-win64.msi',
    linux: 'https://github.com/spareilleux/learn/releases/download/observatory-rtx-0.2.1/Observatory-0.2.1-linux-x86_64.tar.gz',
    mac: 'https://github.com/spareilleux/learn/releases/download/observatory-rtx-0.2.1/Observatory-0.2.1-macos.zip',
    release: 'https://github.com/spareilleux/learn/releases/tag/observatory-rtx-0.3.1',
    nvidia: 'https://www.nvidia.com/en-us/geforce/technologies/dlss/',
    web: '../demos/observatory/'  // the page's own link replaces it (data-web)
  };

  // "ANGLE (NVIDIA, NVIDIA GeForce RTX 5080 (0x00002C02) Direct3D11 vs_5_0 ps_5_0, D3D11)" -> "NVIDIA GeForce RTX 5080"
  function clean(raw) {
    var s = String(raw || '');
    var angle = /^ANGLE \((.*)\)$/.exec(s);
    if (angle) {
      var parts = angle[1].split(',');
      s = parts.length > 1 ? parts[1] : parts[0];
    }
    return s.replace(/ANGLE Metal Renderer:/i, '')
      .replace(/\(0x[0-9a-f]+\)/ig, '')
      .replace(/\s+(Direct3D|D3D|OpenGL|Vulkan|Metal).*$/i, '')
      .replace(/\/PCIe\/SSE2$/i, '')
      .replace(/\s+/g, ' ')
      .replace(/^\s+|\s+$/g, '');
  }

  // The system and the browser, from the user agent: which installs are open to the reader.
  function system(userAgent, touchPoints) {
    var ua = String(userAgent || '');
    var os = /Windows/i.test(ua) ? 'windows'
      : /Android/i.test(ua) ? 'android'
      : /iPhone|iPad|iPod/i.test(ua) || (/Macintosh/i.test(ua) && touchPoints > 1) ? 'ios'  // an iPad asks for the Mac site
      : /Macintosh|Mac OS X/i.test(ua) ? 'mac'
      : /CrOS/i.test(ua) ? 'chromeos'
      : /Linux|X11/i.test(ua) ? 'linux' : 'other';
    var browser = /Firefox|FxiOS/i.test(ua) ? 'firefox'
      : /Edg\/|Chrome\/|CriOS|Chromium/i.test(ua) ? 'chromium'
      : /Safari/i.test(ua) ? 'safari' : 'other';
    // An ARM processor, where the Linux package (x86_64) does not run. A Mac's browser says "Intel" even on
    // Apple silicon; the macOS package is universal.
    var arm = /aarch64|arm64|armv\d/i.test(ua);
    return { os: os, browser: browser, arm: arm };
  }

  // How to keep the web version as an app here (its manifest and service worker make it installable).
  function keep(sys) {
    if (sys.os === 'ios' || sys.os === 'android') {
      return sys.os;
    }
    if (sys.browser === 'chromium') {
      return 'chromium';
    }
    return sys.browser === 'safari' && sys.os === 'mac' ? 'safari' : '';
  }

  function classify(raw, userAgent, touchPoints) {
    var text = String(raw || '');
    var name = clean(text);
    var kind;
    if (/or similar/i.test(text)) {
      // Firefox names a family of cards, not this one: its name is not shown, its make is
      kind = /NVIDIA|GeForce/i.test(text) ? 'nvidia_masked' : 'unknown';
      name = '';
    } else if (/SwiftShader|llvmpipe|Basic Render|Software/i.test(text)) {
      kind = 'software';
      name = '';
    } else if (!name) {
      kind = 'unknown';
    } else if (/GeForce RTX 5080\b(?!\s*(Laptop|Ti|SUPER|Mobile|Max-Q))/i.test(name)) {
      kind = 'rtx5080';
    } else if (/GeForce RTX \d{4}/i.test(name)) {
      kind = 'geforce_rtx';
    } else if (/\bRTX\b/i.test(name) && /NVIDIA|Quadro/i.test(name)) {
      kind = 'nvidia_rtx';
    } else if (/NVIDIA|GeForce|Quadro/i.test(name)) {
      kind = 'nvidia_other';
    } else {
      kind = 'other';
    }
    var sys = system(userAgent, touchPoints);
    return { kind: kind, name: name, windows: sys.os === 'windows', os: sys.os, arm: sys.arm, keep: keep(sys) };
  }

  // Which button leads, whether the RTX one is offered at all, and the native package for this system
  // (native: 'linux', 'mac' or ''), which leads where there is one: the author, 2026-10-14, « proposer d'abord
  // l'OS détecté ».
  function offer(found) {
    var rtxCard = found.kind === 'rtx5080' || found.kind === 'geforce_rtx' || found.kind === 'nvidia_rtx';
    if (found.os === 'mac' || (found.os === 'linux' && !found.arm)) {
      return { first: found.os, rtx: false, native: found.os, notWindows: true };
    }
    if (!found.windows) {
      return { first: 'web', rtx: false, native: '', notWindows: found.os === 'linux' || rtxCard || found.kind === 'nvidia_masked' || found.kind === 'unknown' };
    }
    if (rtxCard || found.kind === 'nvidia_masked') {
      return { first: 'rtx', rtx: true, native: '' };
    }
    return { first: 'web', rtx: found.kind === 'nvidia_other' || found.kind === 'unknown', native: '' };
  }

  // The other platforms' downloads, for the line under the buttons: those not already a button.
  var PLATFORMS = ['rtx', 'linux', 'mac', 'web'];
  function others(o) {
    var shown = ['web'];
    if (o.rtx) {
      shown.push('rtx');
    }
    if (o.native) {
      shown.push(o.native);
    }
    return PLATFORMS.filter(function (k) { return shown.indexOf(k) < 0; });
  }

  // NVIDIA's "DLSS Supported Hardware" table (LINKS.nvidia, read on 2026-10-14): the GeForce RTX series that
  // have each feature. Ray tracing in hardware, which the path tracer needs, is every RTX card's.
  var SERIES = [50, 40, 30, 20];
  var NV = { pt: SERIES, rr: SERIES, sr: SERIES, dlaa: SERIES, fg: [50, 40], mfg: [50], dlss45: [50] };
  var NV_ROWS = ['pt', 'rr', 'sr', 'dlaa', 'fg', 'mfg', 'dlss45'];

  // "NVIDIA GeForce RTX 4060 Laptop GPU" -> 40. NVIDIA's table names GeForce cards only: a professional one
  // goes by its architecture, and is marked to verify.
  function series(name) {
    var s = String(name || '');
    var m = /GeForce RTX (\d)0\d\d/i.exec(s);
    if (m) {
      return { s: Number(m[1]) * 10, pro: false };
    }
    if (/RTX PRO \d{4}/i.test(s)) {
      return { s: 50, pro: true };  // Blackwell
    }
    if (/RTX \d{4} Ada/i.test(s)) {
      return { s: 40, pro: true };  // Ada Lovelace
    }
    if (/RTX A\d{3,4}/i.test(s)) {
      return { s: 30, pro: true };  // Ampere
    }
    if (/Quadro RTX/i.test(s)) {
      return { s: 20, pro: true };  // Turing
    }
    return null;
  }

  // Each feature, and whether this card has it: one value, or one per series when the browser hides the
  // model. web is what this browser reports: { webgl2: bool, webgpu: bool }.
  function features(found, web) {
    var ser = series(found.name);
    var rtx = found.kind === 'rtx5080' || found.kind === 'geforce_rtx' || found.kind === 'nvidia_rtx';
    var matrix = !ser && (found.kind === 'nvidia_masked' || found.kind === 'unknown');
    var rows = [];
    for (var i = 0; i < NV_ROWS.length; i++) {
      var has = [];
      for (var j = 0; j < (matrix ? SERIES.length : 1); j++) {
        var s = matrix ? SERIES[j] : ser && ser.s;
        has.push(!s ? (rtx ? 'verify' : 'no') : NV[NV_ROWS[i]].indexOf(s) < 0 ? 'no' : ser && ser.pro ? 'arch' : 'yes');
      }
      rows.push({ key: NV_ROWS[i], has: has });
    }
    rows.push({ key: 'raster', has: [found.kind === 'rtx5080' ? 'yes' : 'untested'] });
    rows.push({ key: 'webgl2', has: [web.webgl2 ? 'yes' : 'no'] });
    rows.push({ key: 'webgpu', has: [web.webgpu ? 'yes' : 'no'] });
    return { matrix: matrix, rows: rows };
  }

  var TEXT = {
    en: {
      detected: 'Your browser names this card: ',
      windows: ', under Windows',
      local: ' (read in this page; nothing is sent).',
      install: 'Install the RTX version',
      installSub: 'Windows installer · 156 MB · version ' + VERSION,
      play: 'Play in the browser',
      playSub: 'WebGL 2 · about 71 MB, computer or phone',
      after: 'Once it is downloaded:',
      started: 'The download has started. Once it is done:',
      steps: [
        'Open the file. It installs in a few seconds, for your Windows account only, without administrator rights. If Windows says it protected your PC (the installer is not signed): **More info**, then **Run anyway**.',
        'Start **Observatory RTX** from the Start menu.',
        'The first time, press **Enter** to fetch NVIDIA\'s DLSS files (276 MB, once).'
      ],
      notes: '[[What is new in ' + VERSION + ', and the installer\'s SHA-256|release]]',
      notWindows: 'The RTX version is a Windows program: NVIDIA\'s DLSS, through its Streamline library, runs on Windows only. On this device, the web version is the one.',
      armLinux: 'The Linux package is for x86_64 processors, and this one is ARM: here, the web version is the one. DLSS and path tracing are in the RTX version, a Windows program.',
      native: {
        linux: {
          say: 'Under Linux: the native version, rasterized, with Vulkan. DLSS and path tracing are in the RTX version, a Windows program: NVIDIA\'s DLSS, through its Streamline library, runs on Windows only.',
          install: 'Download for Linux',
          sub: 'x86_64 · 81 MB · version ' + NATIVE + ' · Vulkan',
          steps: [
            'Extract it, in a terminal: **tar xzf Observatory-' + NATIVE + '-linux-x86_64.tar.gz**',
            'Start **./Observatory-' + NATIVE + '-linux-x86_64/Observatory.x86_64**. It needs a Vulkan driver.',
            'Run so far under WSL2 only, on a renderer without a graphics card: on a Linux computer with its own, to verify.'
          ]
        },
        mac: {
          say: 'On a Mac: the native version, rasterized, with Metal. DLSS and path tracing need an NVIDIA card and Windows: they are in the RTX version, a Windows program.',
          install: 'Download for macOS',
          sub: 'Apple silicon and Intel · 119 MB · version ' + NATIVE,
          steps: [
            'Open the zip, then move **Observatory.app** to Applications.',
            'The first time, macOS will not open it, because the app is not notarized by Apple. Open **System Settings → Privacy & Security**, then click **Open Anyway**. On macOS 14 or earlier, Control-click the app and choose **Open**.',
            'Not yet run on a Mac: to verify.'
          ]
        },
        notes: '[[The release, its notes and the SHA-256 of each file|release]]'
      },
      others: 'Other platforms: ',
      platforms: { rtx: 'Windows, RTX version (.msi)', linux: 'Linux x86_64 (.tar.gz)', mac: 'macOS (.zip)', web: 'web version', release: 'every file' },
      keep: {
        chromium: 'To keep it as an app: once the observatory is open, the install button at the right of Chrome\'s or Edge\'s address bar.',
        safari: 'To keep it as an app: once the observatory is open, in Safari (macOS 14 or later), **File → Add to Dock**.',
        ios: 'To keep it as an app: once the observatory is open, **Share**, then **Add to Home Screen**.',
        android: 'To keep it as an app: once the observatory is open, the browser\'s menu, then **Install app** or **Add to Home screen**.'
      },
      feat: {
        summary: 'Everything this card can do here',
        cols: ['Feature', 'This card', 'In the Observatory'],
        yes: 'Yes',
        no: 'No',
        arch: 'Yes, by its architecture (to verify)',
        untested: 'Not tested',
        verify: 'To verify',
        masked: 'Your browser does not name the model: here is NVIDIA\'s table for each GeForce RTX series.',
        windowsOnly: 'In the RTX version, a Windows program.',
        nativeRaster: 'The Linux and macOS versions run so: rasterized, without DLSS.',
        notMeasured: ' Frame rate not measured on this card.',
        source: 'The card\'s DLSS features follow [[NVIDIA\'s table of supported hardware|nvidia]], read on 2026-10-14. The figures are measured on the author\'s RTX 5080, in a window of 3840 × 2054.',
        rows: {
          pt: ['Path tracing (ray tracing in hardware)', 'The program starts with it once NVIDIA\'s files are in place.'],
          rr: ['DLSS Ray Reconstruction', 'Denoises the path tracing; always on with it.'],
          sr: ['DLSS Super Resolution', 'F7: Quality, Balanced, Performance, Ultra Performance; the program picks the one that holds 60 frames a second. Ultra Performance since version 0.2.2: until then it found no DLSS mode in this program.'],
          dlaa: ['DLAA (DLSS at the full resolution)', 'F7.'],
          fg: ['DLSS Frame Generation, 2x', 'F8, with NVIDIA Reflex, which NVIDIA requires with it.'],
          mfg: ['DLSS Multi Frame Generation, 3x to 6x', 'F8 picks 2x to 6x: as many frames as the screen\'s refresh rate takes over the rendered ones (4x at most before version 0.2.2).'],
          dlss45: ['DLSS 4.5 and 5: Dynamic Multi Frame Generation, 3D-Guided Neural Rendering', 'Not in this program. Dynamic Multi Frame Generation is in Streamline 2.14.1 and later, which the program is built on since 0.2.2 (2.14.16 since 0.3.0), but on Direct3D 12 only, and the fork\'s path tracer runs on Vulkan; Streamline (2.14.1) has no kit for 3D-Guided Neural Rendering.'],
          raster: ['Without NVIDIA\'s files: rasterized, MSAA 4x + TAA', 'The program starts so when NVIDIA\'s files are missing.'],
          webgl2: ['WebGL 2, in this browser', 'What the web version needs.'],
          webgpu: ['WebGPU, in this browser', 'Not used by the Observatory.']
        },
        measured: {
          pt: ' Measured: 60 frames a second at DLSS Quality, 15.9 ms of GPU a frame in the hall (version 0.2.5).',
          dlaa: ' Measured, rasterized: 12.9 ms of GPU a frame (version 0.2.5).',
          raster: ' Measured: 60 frames a second, 10.0 ms (version 0.2.5).',
          fg: ' Measured: running at 2x, 53 frames rendered a second (Max out, version 0.2.2).',
          mfg: ' Measured: 3x at 27 frames rendered a second, on a 60 Hz screen (version 0.2.2). 4x to 6x, on a faster screen: to verify.'
        },
        glossary: 'What DLSS, DLAA, MSAA, TAA and the other names mean: [[the acronyms|acronyms]], further down this page.',
        anchor: '#the-acronyms'
      },
      kinds: {
        rtx5080: {
          say: 'This is the card the RTX version was measured on: the figures below are for it.'
        },
        geforce_rtx: {
          say: 'A GeForce RTX card: the RTX version should run on it, with DLSS and path tracing. It has only been run on an RTX 5080: what it allows here is expected, not measured.'
        },
        nvidia_rtx: {
          say: 'An NVIDIA RTX card: the RTX version should run on it, with DLSS and path tracing. It has only been run on a GeForce RTX 5080: what it allows here is expected, not measured.'
        },
        nvidia_masked: {
          say: 'An NVIDIA card, but your browser does not say which (Firefox names a family of cards). If it is a GeForce RTX, take the RTX version; otherwise, the web version.'
        },
        nvidia_other: {
          say: 'An NVIDIA card without RTX: the web version is the one for it.'
        },
        other: {
          say: 'Not an NVIDIA card: the web version is the one for it.'
        },
        software: {
          say: 'Your browser draws WebGL without a graphics card (software rendering): the web version will be slow here, and this page cannot tell which card the machine has.'
        },
        unknown: {
          say: 'Your browser does not say which card this is. With a GeForce RTX card under Windows, take the RTX version; otherwise, the web version.'
        }
      }
    },
    fr: {
      detected: 'Votre navigateur nomme cette carte : ',
      windows: ', sous Windows',
      local: ' (lu dans cette page ; rien n\'est envoyé).',
      install: 'Installer la version RTX',
      installSub: 'installateur Windows · 156 Mo · version ' + VERSION,
      play: 'Jouer dans le navigateur',
      playSub: 'WebGL 2 · environ 71 Mo, ordinateur ou téléphone',
      after: 'Une fois téléchargé :',
      started: 'Le téléchargement a commencé. Une fois terminé :',
      steps: [
        'Ouvrez le fichier. Il s\'installe en quelques secondes, pour votre compte Windows seulement, sans droits d\'administrateur. Si Windows dit avoir protégé votre PC (l\'installateur n\'est pas signé) : **Informations complémentaires**, puis **Exécuter quand même**.',
        'Lancez **Observatory RTX** depuis le menu Démarrer.',
        'La première fois, appuyez sur **Entrée** pour récupérer les fichiers DLSS de NVIDIA (276 Mo, une fois).'
      ],
      notes: '[[Les nouveautés de la ' + VERSION + ', et le SHA-256 de l\'installateur|release]]',
      notWindows: 'La version RTX est un programme Windows : le DLSS de NVIDIA, par sa bibliothèque Streamline, ne tourne que sous Windows. Sur cet appareil, c\'est la version web.',
      armLinux: 'Le paquet Linux est pour les processeurs x86_64, et celui-ci est ARM : ici, c\'est la version web. Le DLSS et le path tracing sont dans la version RTX, un programme Windows.',
      native: {
        linux: {
          say: 'Sous Linux : la version native, en rastérisation, avec Vulkan. Le DLSS et le path tracing sont dans la version RTX, un programme Windows : le DLSS de NVIDIA, par sa bibliothèque Streamline, ne tourne que sous Windows.',
          install: 'Télécharger pour Linux',
          sub: 'x86_64 · 81 Mo · version ' + NATIVE + ' · Vulkan',
          steps: [
            'Extrayez-le, dans un terminal : **tar xzf Observatory-' + NATIVE + '-linux-x86_64.tar.gz**',
            'Lancez **./Observatory-' + NATIVE + '-linux-x86_64/Observatory.x86_64**. Il faut un pilote Vulkan.',
            'Lancé jusqu\'ici sous WSL2 seulement, avec un rendu sans carte graphique : sur un ordinateur Linux qui a la sienne, à vérifier.'
          ]
        },
        mac: {
          say: 'Sur un Mac : la version native, en rastérisation, avec Metal. Le DLSS et le path tracing demandent une carte NVIDIA et Windows : ils sont dans la version RTX, un programme Windows.',
          install: 'Télécharger pour macOS',
          sub: 'puces Apple et Intel · 119 Mo · version ' + NATIVE,
          steps: [
            'Ouvrez le zip, puis déplacez **Observatory.app** dans Applications.',
            'La première fois, macOS refuse de l\'ouvrir, car l\'app n\'est pas notarisée par Apple. Ouvrez **Réglages Système → Confidentialité et sécurité**, puis cliquez sur **Ouvrir quand même**. Sous macOS 14 ou plus ancien, Contrôle-clic sur l\'app, puis **Ouvrir**.',
            'Pas encore lancé sur un Mac : à vérifier.'
          ]
        },
        notes: '[[La release, ses notes et le SHA-256 de chaque fichier|release]]'
      },
      others: 'Autres plateformes : ',
      platforms: { rtx: 'Windows, version RTX (.msi)', linux: 'Linux x86_64 (.tar.gz)', mac: 'macOS (.zip)', web: 'version web', release: 'tous les fichiers' },
      keep: {
        chromium: 'Pour la garder comme une application : une fois l\'observatoire ouvert, le bouton d\'installation à droite de la barre d\'adresse de Chrome ou d\'Edge.',
        safari: 'Pour la garder comme une application : une fois l\'observatoire ouvert, dans Safari (macOS 14 ou plus récent), **Fichier → Ajouter au Dock**.',
        ios: 'Pour la garder comme une application : une fois l\'observatoire ouvert, **Partager**, puis **Sur l\'écran d\'accueil**.',
        android: 'Pour la garder comme une application : une fois l\'observatoire ouvert, le menu du navigateur, puis **Installer l\'application** ou **Ajouter à l\'écran d\'accueil**.'
      },
      feat: {
        summary: 'Tout ce que cette carte permet ici',
        cols: ['Fonction', 'Cette carte', 'Dans l\'Observatoire'],
        yes: 'Oui',
        no: 'Non',
        arch: 'Oui, par son architecture (à vérifier)',
        untested: 'Non testé',
        verify: 'À vérifier',
        masked: 'Votre navigateur ne nomme pas le modèle : voici le tableau de NVIDIA pour chaque série GeForce RTX.',
        windowsOnly: 'Dans la version RTX, un programme Windows.',
        nativeRaster: 'Les versions Linux et macOS tournent ainsi : en rastérisation, sans DLSS.',
        notMeasured: ' Cadence pas mesurée sur cette carte.',
        source: 'Les fonctions DLSS de la carte suivent [[le tableau du matériel pris en charge de NVIDIA|nvidia]], lu le 2026-10-14. Les chiffres sont mesurés sur la RTX 5080 de l\'auteur, dans une fenêtre de 3840 × 2054.',
        rows: {
          pt: ['Path tracing (lancer de rayons matériel)', 'Le programme démarre avec, une fois les fichiers de NVIDIA en place.'],
          rr: ['DLSS Ray Reconstruction', 'Débruite le path tracing ; toujours actif avec lui.'],
          sr: ['DLSS Super Resolution', 'F7 : Quality, Balanced, Performance, Ultra Performance ; le programme choisit celui qui tient 60 images par seconde. Ultra Performance depuis la version 0.2.2 : jusque-là, il ne trouvait aucun mode DLSS dans ce programme.'],
          dlaa: ['DLAA (DLSS à la pleine résolution)', 'F7.'],
          fg: ['DLSS Frame Generation, 2x', 'F8, avec NVIDIA Reflex, que NVIDIA exige avec elle.'],
          mfg: ['DLSS Multi Frame Generation, de 3x à 6x', 'F8 choisit de 2x à 6x : autant d\'images que la fréquence de l\'écran en demande au-delà des images rendues (4x au plus avant la version 0.2.2).'],
          dlss45: ['DLSS 4.5 et 5 : Dynamic Multi Frame Generation, 3D-Guided Neural Rendering', 'Pas dans ce programme. Dynamic Multi Frame Generation est dans Streamline depuis la 2.14.1, sur lequel le programme repose depuis la 0.2.2 (2.14.16 depuis la 0.3.0), mais sous Direct3D 12 seulement, et le path tracer du fork tourne sous Vulkan ; Streamline (2.14.1) n\'a pas de kit pour 3D-Guided Neural Rendering.'],
          raster: ['Sans les fichiers de NVIDIA : rastérisation, MSAA 4x + TAA', 'Le programme démarre ainsi quand les fichiers de NVIDIA manquent.'],
          webgl2: ['WebGL 2, dans ce navigateur', 'Ce que demande la version web.'],
          webgpu: ['WebGPU, dans ce navigateur', 'Pas utilisé par l\'Observatoire.']
        },
        measured: {
          pt: ' Mesuré : 60 images par seconde en DLSS Quality, 15,9 ms de GPU par image dans la salle (version 0.2.5).',
          dlaa: ' Mesuré, en rastérisation : 12,9 ms de GPU par image (version 0.2.5).',
          raster: ' Mesuré : 60 images par seconde, 10,0 ms (version 0.2.5).',
          fg: ' Mesuré : active en 2x, 53 images rendues par seconde (Max out, version 0.2.2).',
          mfg: ' Mesuré : 3x à 27 images rendues par seconde, sur un écran à 60 Hz (version 0.2.2). De 4x à 6x, sur un écran plus rapide : à vérifier.'
        },
        glossary: 'Ce que veulent dire DLSS, DLAA, MSAA, TAA et les autres noms : [[les sigles|acronyms]], plus bas sur cette page.',
        anchor: '#les-sigles'
      },
      kinds: {
        rtx5080: {
          say: 'C\'est la carte sur laquelle la version RTX a été mesurée : les chiffres ci-dessous sont les siens.'
        },
        geforce_rtx: {
          say: 'Une carte GeForce RTX : la version RTX devrait y tourner, avec DLSS et le path tracing. Elle n\'a tourné que sur une RTX 5080 : ce qu\'elle permet ici est attendu, pas mesuré.'
        },
        nvidia_rtx: {
          say: 'Une carte NVIDIA RTX : la version RTX devrait y tourner, avec DLSS et le path tracing. Elle n\'a tourné que sur une GeForce RTX 5080 : ce qu\'elle permet ici est attendu, pas mesuré.'
        },
        nvidia_masked: {
          say: 'Une carte NVIDIA, mais votre navigateur ne dit pas laquelle (Firefox nomme une famille de cartes). Si c\'est une GeForce RTX, prenez la version RTX ; sinon, la version web.'
        },
        nvidia_other: {
          say: 'Une carte NVIDIA sans RTX : la version web est celle qu\'il lui faut.'
        },
        other: {
          say: 'Pas une carte NVIDIA : la version web est celle qu\'il lui faut.'
        },
        software: {
          say: 'Votre navigateur dessine WebGL sans carte graphique (rendu logiciel) : la version web sera lente ici, et cette page ne peut pas dire quelle carte a la machine.'
        },
        unknown: {
          say: 'Votre navigateur ne dit pas de quelle carte il s\'agit. Avec une carte GeForce RTX sous Windows, prenez la version RTX ; sinon, la version web.'
        }
      }
    },
    es: {
      detected: 'Su navegador nombra esta tarjeta: ',
      windows: ', en Windows',
      local: ' (leído en esta página; no se envía nada).',
      install: 'Instalar la versión RTX',
      installSub: 'instalador de Windows · 156 MB · versión ' + VERSION,
      play: 'Jugar en el navegador',
      playSub: 'WebGL 2 · unos 71 MB, ordenador o teléfono',
      after: 'Una vez descargado:',
      started: 'La descarga ha comenzado. Una vez terminada:',
      steps: [
        'Abra el archivo. Se instala en unos segundos, solo para su cuenta de Windows, sin derechos de administrador. Si Windows dice que protegió su PC (el instalador no está firmado): **Más información**, y luego **Ejecutar de todas formas**.',
        'Inicie **Observatory RTX** desde el menú Inicio.',
        'La primera vez, pulse **Intro** para obtener los archivos DLSS de NVIDIA (276 MB, una sola vez).'
      ],
      notes: '[[Las novedades de la ' + VERSION + ', y el SHA-256 del instalador|release]]',
      notWindows: 'La versión RTX es un programa de Windows: el DLSS de NVIDIA, mediante su biblioteca Streamline, solo funciona en Windows. En este dispositivo, la versión web es la que corresponde.',
      armLinux: 'El paquete de Linux es para procesadores x86_64, y este es ARM: aquí, la versión web es la que corresponde. El DLSS y el path tracing están en la versión RTX, un programa de Windows.',
      native: {
        linux: {
          say: 'En Linux: la versión nativa, rasterizada, con Vulkan. El DLSS y el path tracing están en la versión RTX, un programa de Windows: el DLSS de NVIDIA, mediante su biblioteca Streamline, solo funciona en Windows.',
          install: 'Descargar para Linux',
          sub: 'x86_64 · 81 MB · versión ' + NATIVE + ' · Vulkan',
          steps: [
            'Extráigalo, en una terminal: **tar xzf Observatory-' + NATIVE + '-linux-x86_64.tar.gz**',
            'Inicie **./Observatory-' + NATIVE + '-linux-x86_64/Observatory.x86_64**. Necesita un controlador Vulkan.',
            'Probado hasta ahora solo en WSL2, con un renderizado sin tarjeta gráfica: en un ordenador Linux que tenga la suya, por verificar.'
          ]
        },
        mac: {
          say: 'En un Mac: la versión nativa, rasterizada, con Metal. El DLSS y el path tracing requieren una tarjeta NVIDIA y Windows: están en la versión RTX, un programa de Windows.',
          install: 'Descargar para macOS',
          sub: 'chips de Apple e Intel · 119 MB · versión ' + NATIVE,
          steps: [
            'Abra el zip y mueva **Observatory.app** a Aplicaciones.',
            'La primera vez, macOS no la abre, porque la app no está notarizada por Apple. Abra **Ajustes del Sistema → Privacidad y seguridad** y haga clic en **Abrir igualmente**. En macOS 14 o anterior, Control-clic en la app y elija **Abrir**.',
            'Aún no probado en un Mac: por verificar.'
          ]
        },
        notes: '[[La release, sus notas y el SHA-256 de cada archivo|release]]'
      },
      others: 'Otras plataformas: ',
      platforms: { rtx: 'Windows, versión RTX (.msi)', linux: 'Linux x86_64 (.tar.gz)', mac: 'macOS (.zip)', web: 'versión web', release: 'todos los archivos' },
      keep: {
        chromium: 'Para conservarla como aplicación: una vez abierto el observatorio, el botón de instalar a la derecha de la barra de direcciones de Chrome o Edge.',
        safari: 'Para conservarla como aplicación: una vez abierto el observatorio, en Safari (macOS 14 o posterior), **Archivo → Añadir al Dock**.',
        ios: 'Para conservarla como aplicación: una vez abierto el observatorio, **Compartir** y luego **Añadir a pantalla de inicio**.',
        android: 'Para conservarla como aplicación: una vez abierto el observatorio, el menú del navegador y luego **Instalar aplicación** o **Añadir a pantalla de inicio**.'
      },
      feat: {
        summary: 'Todo lo que permite esta tarjeta aquí',
        cols: ['Función', 'Esta tarjeta', 'En el Observatorio'],
        yes: 'Sí',
        no: 'No',
        arch: 'Sí, por su arquitectura (por verificar)',
        untested: 'Sin probar',
        verify: 'Por verificar',
        masked: 'Su navegador no nombra el modelo: esta es la tabla de NVIDIA para cada serie GeForce RTX.',
        windowsOnly: 'En la versión RTX, un programa de Windows.',
        nativeRaster: 'Las versiones de Linux y macOS funcionan así: rasterizadas, sin DLSS.',
        notMeasured: ' Cadencia no medida en esta tarjeta.',
        source: 'Las funciones DLSS de la tarjeta siguen [[la tabla de hardware compatible de NVIDIA|nvidia]], leída el 2026-10-14. Las cifras se midieron en la RTX 5080 del autor, en una ventana de 3840 × 2054.',
        rows: {
          pt: ['Path tracing (trazado de rayos por hardware)', 'El programa se inicia con él, una vez instalados los archivos de NVIDIA.'],
          rr: ['DLSS Ray Reconstruction', 'Elimina el ruido del path tracing; siempre activo con él.'],
          sr: ['DLSS Super Resolution', 'F7: Quality, Balanced, Performance, Ultra Performance; el programa elige el que mantiene 60 imágenes por segundo. Ultra Performance desde la versión 0.2.2: hasta entonces no encontraba ningún modo DLSS en este programa.'],
          dlaa: ['DLAA (DLSS a la resolución completa)', 'F7.'],
          fg: ['DLSS Frame Generation, 2x', 'F8, con NVIDIA Reflex, que NVIDIA exige con ella.'],
          mfg: ['DLSS Multi Frame Generation, de 3x a 6x', 'F8 elige de 2x a 6x: tantas imágenes como la frecuencia de la pantalla pide además de las renderizadas (4x como máximo antes de la versión 0.2.2).'],
          dlss45: ['DLSS 4.5 y 5: Dynamic Multi Frame Generation, 3D-Guided Neural Rendering', 'No en este programa. Dynamic Multi Frame Generation está en Streamline desde la 2.14.1, sobre el que se basa el programa desde la 0.2.2 (2.14.16 desde la 0.3.0), pero solo con Direct3D 12, y el path tracer del fork funciona con Vulkan; Streamline (2.14.1) no tiene kit para 3D-Guided Neural Rendering.'],
          raster: ['Sin los archivos de NVIDIA: rasterizado, MSAA 4x + TAA', 'El programa se inicia así cuando faltan los archivos de NVIDIA.'],
          webgl2: ['WebGL 2, en este navegador', 'Lo que necesita la versión web.'],
          webgpu: ['WebGPU, en este navegador', 'El Observatorio no lo usa.']
        },
        measured: {
          pt: ' Medido: 60 imágenes por segundo en DLSS Quality, 15,9 ms de GPU por imagen en la sala (versión 0.2.5).',
          dlaa: ' Medido, rasterizado: 12,9 ms de GPU por imagen (versión 0.2.5).',
          raster: ' Medido: 60 imágenes por segundo, 10,0 ms (versión 0.2.5).',
          fg: ' Medido: activa en 2x, 53 imágenes renderizadas por segundo (Max out, versión 0.2.2).',
          mfg: ' Medido: 3x con 27 imágenes renderizadas por segundo, en una pantalla de 60 Hz (versión 0.2.2). De 4x a 6x, en una pantalla más rápida: por verificar.'
        },
        glossary: 'Lo que significan DLSS, DLAA, MSAA, TAA y los demás nombres: [[las siglas|acronyms]], más abajo en esta página.',
        anchor: '#las-siglas'
      },
      kinds: {
        rtx5080: {
          say: 'Es la tarjeta en la que se midió la versión RTX: las cifras de abajo son las suyas.'
        },
        geforce_rtx: {
          say: 'Una tarjeta GeForce RTX: la versión RTX debería funcionar en ella, con DLSS y path tracing. Solo se ha ejecutado en una RTX 5080: lo que permite aquí es lo esperado, no lo medido.'
        },
        nvidia_rtx: {
          say: 'Una tarjeta NVIDIA RTX: la versión RTX debería funcionar en ella, con DLSS y path tracing. Solo se ha ejecutado en una GeForce RTX 5080: lo que permite aquí es lo esperado, no lo medido.'
        },
        nvidia_masked: {
          say: 'Una tarjeta NVIDIA, pero su navegador no dice cuál (Firefox nombra una familia de tarjetas). Si es una GeForce RTX, use la versión RTX; si no, la versión web.'
        },
        nvidia_other: {
          say: 'Una tarjeta NVIDIA sin RTX: la versión web es la que le corresponde.'
        },
        other: {
          say: 'No es una tarjeta NVIDIA: la versión web es la que le corresponde.'
        },
        software: {
          say: 'Su navegador dibuja WebGL sin tarjeta gráfica (renderizado por software): la versión web irá lenta aquí, y esta página no puede saber qué tarjeta tiene el equipo.'
        },
        unknown: {
          say: 'Su navegador no dice qué tarjeta es. Con una tarjeta GeForce RTX en Windows, use la versión RTX; si no, la versión web.'
        }
      }
    }
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { clean: clean, system: system, keep: keep, classify: classify, offer: offer, others: others, series: series, features: features, TEXT: TEXT, LINKS: LINKS, VERSION: VERSION, NATIVE: NATIVE };
    return;
  }

  // Starlight's own colours, so that the block follows the light and dark themes.
  var STYLE = [
    '#obs-gpu{border:1px solid var(--sl-color-gray-5);border-radius:.75rem;background:var(--sl-color-gray-6);padding:1rem 1.25rem}',
    '#obs-gpu .obs-actions{display:flex;flex-wrap:wrap;gap:.75rem;margin:1rem 0}',
    '#obs-gpu .obs-btn{display:inline-flex;flex-direction:column;justify-content:center;gap:.15rem;min-height:3.25rem;',
    'padding:.6rem 1.25rem;border-radius:.6rem;border:1px solid var(--sl-color-gray-4);color:var(--sl-color-white);',
    'text-decoration:none;font-weight:600;line-height:1.25}',
    '#obs-gpu .obs-btn small{font-weight:400;font-size:var(--sl-text-xs);opacity:.85}',
    '#obs-gpu .obs-btn.first{background:var(--sl-color-text-accent);border-color:var(--sl-color-text-accent);color:var(--sl-color-black);font-size:var(--sl-text-lg)}',
    '#obs-gpu .obs-btn:hover{border-color:var(--sl-color-text-accent)}',
    '#obs-gpu .obs-btn.first:hover{filter:brightness(1.08)}',
    '#obs-gpu .obs-btn:focus-visible{outline:2px solid var(--sl-color-text-accent);outline-offset:2px}',
    '#obs-gpu .obs-steps.started .obs-after{color:var(--sl-color-text-accent);font-weight:600}',
    '#obs-gpu ol{margin-top:.25rem}',
    '#obs-gpu details{margin-top:1rem}',
    '#obs-gpu .obs-table{overflow-x:auto;margin-top:.5rem}',
    '#obs-gpu .obs-table table{display:table;width:100%;font-size:var(--sl-text-sm)}',
    '#obs-gpu .obs-table th[scope=row]{font-weight:600;text-align:start}',
    '#obs-gpu .obs-yes{color:var(--sl-color-text-accent);font-weight:600}',
    '#obs-gpu .obs-no{opacity:.7}',
    '@media (max-width:30rem){#obs-gpu .obs-btn{flex:1 1 100%}}'
  ].join('');

  // What this browser offers the web version, and WebGPU, which the Observatory does not use.
  function webSupport() {
    var gl2 = false;
    try {
      gl2 = !!document.createElement('canvas').getContext('webgl2');
    } catch (e) {
      gl2 = false;
    }
    return { webgl2: gl2, webgpu: !!navigator.gpu };
  }

  function renderer() {
    try {
      var canvas = document.createElement('canvas');
      var gl = canvas.getContext('webgl2') || canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
      if (!gl) {
        return '';
      }
      var ext = gl.getExtension('WEBGL_debug_renderer_info');
      return String((ext && gl.getParameter(ext.UNMASKED_RENDERER_WEBGL)) || gl.getParameter(gl.RENDERER) || '');
    } catch (e) {
      return '';
    }
  }

  // "see the [[web version|web]]" and "press **Enter**" -> text nodes, links and bold; the card's name never
  // passes through HTML.
  function fill(parent, text, links) {
    var re = /\[\[([^|\]]+)\|([a-z]+)\]\]|\*\*([^*]+)\*\*/g;
    var last = 0;
    var m;
    while ((m = re.exec(text))) {
      parent.appendChild(document.createTextNode(text.slice(last, m.index)));
      var el;
      if (m[3]) {
        el = document.createElement('strong');
        el.textContent = m[3];
      } else {
        el = document.createElement('a');
        el.href = links[m[2]];
        el.textContent = m[1];
      }
      parent.appendChild(el);
      last = re.lastIndex;
    }
    parent.appendChild(document.createTextNode(text.slice(last)));
  }

  // The features table, under the buttons: open on an NVIDIA card, what the reader came to look up; folded
  // on another make, where the NVIDIA rows are all "No".
  function table(box, t, found, links) {
    var f = features(found, webSupport());
    var more = document.createElement('details');
    more.open = found.kind === 'rtx5080' || found.kind === 'geforce_rtx' || found.kind === 'nvidia_rtx' || f.matrix;
    var summary = document.createElement('summary');
    summary.textContent = t.feat.summary;
    more.appendChild(summary);
    if (f.matrix) {
      var masked = document.createElement('p');
      fill(masked, t.feat.masked, links);
      more.appendChild(masked);
    }
    var wrap = document.createElement('div');
    wrap.className = 'obs-table';
    var tab = document.createElement('table');
    var head = tab.createTHead().insertRow();
    var cols = [t.feat.cols[0]].concat(f.matrix ? SERIES.map(function (n) { return 'RTX ' + n; }) : [t.feat.cols[1]], [t.feat.cols[2]]);
    for (var c = 0; c < cols.length; c++) {
      var th = document.createElement('th');
      th.textContent = cols[c];
      head.appendChild(th);
    }
    var body = tab.createTBody();
    for (var i = 0; i < f.rows.length; i++) {
      var r = f.rows[i];
      var tr = body.insertRow();
      var name = document.createElement('th');
      name.scope = 'row';
      name.textContent = t.feat.rows[r.key][0];
      tr.appendChild(name);
      for (var j = 0; j < r.has.length; j++) {
        var td = tr.insertCell();
        td.textContent = t.feat[r.has[j]];
        td.className = 'obs-' + r.has[j];
        if (f.matrix && r.has.length === 1) {
          td.colSpan = SERIES.length;
        }
      }
      var note = t.feat.rows[r.key][1];
      var card = NV_ROWS.indexOf(r.key) >= 0 || r.key === 'raster';
      if (r.key === 'raster' && (found.os === 'linux' || found.os === 'mac')) {
        note = t.feat.nativeRaster;
      } else if (card && !found.windows) {
        note = t.feat.windowsOnly;
      } else if (found.kind === 'rtx5080' && t.feat.measured[r.key]) {
        note += t.feat.measured[r.key];
      } else if (r.key === 'pt' && r.has[0] !== 'no' && !f.matrix) {
        note += t.feat.notMeasured;
      }
      tr.insertCell().textContent = note;
    }
    wrap.appendChild(tab);
    more.appendChild(wrap);
    var source = document.createElement('p');
    fill(source, t.feat.source, links);
    more.appendChild(source);
    var names = document.createElement('p');
    links.acronyms = t.feat.anchor;
    fill(names, t.feat.glossary, links);
    more.appendChild(names);
    box.appendChild(more);
  }

  function button(href, label, sub, first) {
    var a = document.createElement('a');
    a.className = 'obs-btn' + (first ? ' first' : '');
    a.href = href;
    a.appendChild(document.createTextNode(label));
    var small = document.createElement('small');
    small.textContent = sub;
    a.appendChild(small);
    return a;
  }

  function show() {
    var box = document.getElementById('obs-gpu');
    if (!box) {
      return;
    }
    var lang = (document.documentElement.lang || 'en').slice(0, 2).toLowerCase();
    var t = TEXT[lang] || TEXT.en;
    var links = { rtx: LINKS.rtx, linux: LINKS.linux, mac: LINKS.mac, release: LINKS.release, nvidia: LINKS.nvidia, web: box.getAttribute('data-web') || LINKS.web };
    var found = classify(renderer(), navigator.userAgent, navigator.maxTouchPoints || 0);
    var k = t.kinds[found.kind];
    var o = offer(found);
    if (!document.getElementById('obs-gpu-style')) {
      var style = document.createElement('style');
      style.id = 'obs-gpu-style';
      style.textContent = STYLE;
      document.head.appendChild(style);
    }
    while (box.firstChild) {
      box.removeChild(box.firstChild);
    }
    if (found.name) {
      var named = document.createElement('p');
      named.appendChild(document.createTextNode(t.detected));
      var strong = document.createElement('strong');
      strong.textContent = found.name;
      named.appendChild(strong);
      named.appendChild(document.createTextNode((found.windows ? t.windows : '') + t.local));
      box.appendChild(named);
    }
    var say = document.createElement('p');
    var native = o.native ? t.native[o.native] : null;
    fill(say, native ? native.say : found.os === 'linux' ? t.armLinux : o.notWindows ? t.notWindows : k.say, links);
    box.appendChild(say);

    // not-content: Starlight's prose styles (link colour, underline, spacing) stay off the buttons.
    var actions = document.createElement('div');
    actions.className = 'obs-actions not-content';
    // The download for this system (the RTX installer, or the Linux or macOS package), whose steps follow.
    var main = o.rtx ? button(links.rtx, t.install, t.installSub, o.first === 'rtx')
      : native ? button(links[o.native], native.install, native.sub, o.first === o.native) : null;
    var web = button(links.web, t.play, t.playSub, o.first === 'web');
    if (main && o.first !== 'web') {
      actions.appendChild(main);
      actions.appendChild(web);
    } else {
      actions.appendChild(web);
      if (main) {
        actions.appendChild(main);
      }
    }
    box.appendChild(actions);
    var rest = others(o).map(function (key) { return '[[' + t.platforms[key] + '|' + key + ']]'; });
    var other = document.createElement('p');
    other.className = 'obs-others';
    fill(other, t.others + rest.concat(['[[' + t.platforms.release + '|release]]']).join(' · '), links);
    box.appendChild(other);
    if (o.first === 'web' && found.keep) {
      var app = document.createElement('p');
      fill(app, t.keep[found.keep], links);
      box.appendChild(app);
    }

    if (main) {
      var steps = document.createElement('div');
      steps.className = 'obs-steps';
      steps.hidden = o.first === 'web';
      var after = document.createElement('p');
      after.className = 'obs-after';
      after.textContent = t.after;
      steps.appendChild(after);
      var ol = document.createElement('ol');
      var list = native ? native.steps : t.steps;
      for (var i = 0; i < list.length; i++) {
        var li = document.createElement('li');
        fill(li, list[i], links);
        ol.appendChild(li);
      }
      steps.appendChild(ol);
      var notes = document.createElement('p');
      fill(notes, native ? t.native.notes : t.notes, links);
      steps.appendChild(notes);
      box.appendChild(steps);
      // The file downloads in place (GitHub serves it as an attachment): the page stays, and says what next.
      main.addEventListener('click', function () {
        steps.hidden = false;
        steps.className = 'obs-steps started';
        after.textContent = t.started;
      });
    }

    if (found.kind !== 'software') {
      table(box, t, found, links);
    }
    box.setAttribute('data-kind', found.kind);
    box.setAttribute('data-first', o.first);
    box.setAttribute('data-os', found.os);
    box.setAttribute('data-native', o.native);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', show);
  } else {
    show();
  }
})();
