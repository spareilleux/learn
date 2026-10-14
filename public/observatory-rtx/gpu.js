// The Observatory page's install block, at the top of src/content/docs/observatory/index.md and its fr/
// and es/ mirrors. It reads the name the browser gives the graphics card (WebGL's
// WEBGL_debug_renderer_info), and offers the version that suits it as a button: the RTX installer on a
// GeForce RTX card under Windows, the web version otherwise. Nothing leaves the page.
// The RTX 5080's measured figures are in the pages themselves; here, only what follows from a card's name.
(function () {
  'use strict';

  var VERSION = '0.2.1';
  var LINKS = {
    rtx: 'https://github.com/spareilleux/learn/releases/download/observatory-rtx-0.2.1/Observatory-RTX-0.2.1-win64.msi',
    release: 'https://github.com/spareilleux/learn/releases/tag/observatory-rtx-0.2.1',
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
    return { os: os, browser: browser };
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
    return { kind: kind, name: name, windows: sys.os === 'windows', os: sys.os, keep: keep(sys) };
  }

  // Which button leads, and whether the RTX one is offered at all.
  function offer(found) {
    var rtxCard = found.kind === 'rtx5080' || found.kind === 'geforce_rtx' || found.kind === 'nvidia_rtx';
    if (!found.windows) {
      return { first: 'web', rtx: false, notWindows: rtxCard || found.kind === 'nvidia_masked' || found.kind === 'unknown' };
    }
    if (rtxCard || found.kind === 'nvidia_masked') {
      return { first: 'rtx', rtx: true };
    }
    return { first: 'web', rtx: found.kind === 'nvidia_other' || found.kind === 'unknown' };
  }

  var RTX_YES_EN = [
    'DLSS, and path tracing with DLSS Ray Reconstruction: the program starts with them once NVIDIA\'s files are in place.',
    'A frame rate the program looks after: when a frame takes more than 16 ms, or under 56 frames a second, it lowers the DLSS setting; under 20 at the lowest setting, it switches path tracing off and says so.'
  ];
  var RTX_NO_EN = [
    'The RTX 5080\'s figures: a slower card runs a lower DLSS setting, or rasterized; a faster one, a higher setting.',
    'Frame generation on every series: [[NVIDIA says which cards run it|nvidia]].'
  ];
  var RTX_YES_FR = [
    'DLSS, et le path tracing avec DLSS Ray Reconstruction : le programme démarre avec eux une fois les fichiers de NVIDIA en place.',
    'Une cadence dont le programme s\'occupe : quand une image prend plus de 16 ms, ou sous 56 images par seconde, il baisse le réglage DLSS ; sous 20 au dernier réglage, il coupe le path tracing et le dit.'
  ];
  var RTX_NO_FR = [
    'Les chiffres de la RTX 5080 : une carte plus lente tourne avec un réglage DLSS plus bas, ou en rastérisation ; une plus rapide, avec un réglage plus haut.',
    'La génération d\'images sur toutes les séries : [[NVIDIA dit quelles cartes la font tourner|nvidia]].'
  ];
  var RTX_YES_ES = [
    'DLSS, y path tracing con DLSS Ray Reconstruction: el programa se inicia con ellos una vez instalados los archivos de NVIDIA.',
    'Una cadencia de la que se ocupa el programa: cuando una imagen tarda más de 16 ms, o por debajo de 56 imágenes por segundo, baja el ajuste de DLSS; por debajo de 20 en el último ajuste, desactiva el path tracing y lo dice.'
  ];
  var RTX_NO_ES = [
    'Las cifras de la RTX 5080: una tarjeta más lenta funciona con un ajuste de DLSS más bajo, o rasterizada; una más rápida, con uno más alto.',
    'La generación de imágenes en todas las series: [[NVIDIA dice qué tarjetas la ejecutan|nvidia]].'
  ];

  var TEXT = {
    en: {
      detected: 'Your browser names this card: ',
      windows: ', under Windows',
      local: ' (read in this page; nothing is sent).',
      install: 'Install the RTX version',
      installSub: 'Windows installer · 71 MB · version ' + VERSION,
      play: 'Play in the browser',
      playSub: 'WebGL 2 · about 55 MB, computer or phone',
      after: 'Once it is downloaded:',
      started: 'The download has started. Once it is done:',
      steps: [
        'Open the file. It installs in a few seconds, for your Windows account only, without administrator rights. If Windows says it protected your PC (the installer is not signed): **More info**, then **Run anyway**.',
        'Start **Observatory RTX** from the Start menu.',
        'The first time, press **Enter** to fetch NVIDIA\'s DLSS files (203 MB, once).'
      ],
      notes: '[[What is new in ' + VERSION + ', and the installer\'s SHA-256|release]]',
      more: 'What this card allows',
      yes: 'It allows',
      no: 'It does not allow',
      notWindows: 'The RTX version is a Windows program: NVIDIA\'s DLSS, through its Streamline library, runs on Windows only. On this device, the web version is the one.',
      keep: {
        chromium: 'To keep it as an app: once the observatory is open, the install button at the right of Chrome\'s or Edge\'s address bar.',
        safari: 'To keep it as an app: once the observatory is open, in Safari (macOS 14 or later), **File → Add to Dock**.',
        ios: 'To keep it as an app: once the observatory is open, **Share**, then **Add to Home Screen**.',
        android: 'To keep it as an app: once the observatory is open, the browser\'s menu, then **Install app** or **Add to Home screen**.'
      },
      kinds: {
        rtx5080: {
          say: 'This is the card the RTX version was measured on: the figures below are for it.',
          yes: ['What the list below says: path tracing with DLSS Ray Reconstruction at 60 frames a second, DLSS Frame Generation, DLAA.'],
          no: ['What the list below says it does not: path tracing at the full 4K resolution at 60 frames a second.']
        },
        geforce_rtx: {
          say: 'A GeForce RTX card: the RTX version should run on it, with DLSS and path tracing. It has only been run on an RTX 5080: what it allows here is expected, not measured.',
          yes: RTX_YES_EN, no: RTX_NO_EN
        },
        nvidia_rtx: {
          say: 'An NVIDIA RTX card: the RTX version should run on it, with DLSS and path tracing. It has only been run on a GeForce RTX 5080: what it allows here is expected, not measured.',
          yes: RTX_YES_EN, no: RTX_NO_EN
        },
        nvidia_masked: {
          say: 'An NVIDIA card, but your browser does not say which (Firefox names a family of cards). If it is a GeForce RTX, take the RTX version; otherwise, the web version.',
          yes: [], no: []
        },
        nvidia_other: {
          say: 'An NVIDIA card without RTX: the web version is the one for it.',
          yes: ['The web version, in this browser.', 'Perhaps the RTX version without its extras, rasterized: not tested on such a card.'],
          no: ['DLSS, frame generation and path tracing: they need an RTX card.']
        },
        other: {
          say: 'Not an NVIDIA card: the web version is the one for it.',
          yes: ['The web version, in this browser.'],
          no: ['DLSS, frame generation and path tracing: they are NVIDIA\'s and need a GeForce RTX card.', 'The RTX version on a card of another make: not tested.']
        },
        software: {
          say: 'Your browser draws WebGL without a graphics card (software rendering): the web version will be slow here, and this page cannot tell which card the machine has.',
          yes: [], no: []
        },
        unknown: {
          say: 'Your browser does not say which card this is. With a GeForce RTX card under Windows, take the RTX version; otherwise, the web version.',
          yes: [], no: []
        }
      }
    },
    fr: {
      detected: 'Votre navigateur nomme cette carte : ',
      windows: ', sous Windows',
      local: ' (lu dans cette page ; rien n\'est envoyé).',
      install: 'Installer la version RTX',
      installSub: 'installateur Windows · 71 Mo · version ' + VERSION,
      play: 'Jouer dans le navigateur',
      playSub: 'WebGL 2 · environ 55 Mo, ordinateur ou téléphone',
      after: 'Une fois téléchargé :',
      started: 'Le téléchargement a commencé. Une fois terminé :',
      steps: [
        'Ouvrez le fichier. Il s\'installe en quelques secondes, pour votre compte Windows seulement, sans droits d\'administrateur. Si Windows dit avoir protégé votre PC (l\'installateur n\'est pas signé) : **Informations complémentaires**, puis **Exécuter quand même**.',
        'Lancez **Observatory RTX** depuis le menu Démarrer.',
        'La première fois, appuyez sur **Entrée** pour récupérer les fichiers DLSS de NVIDIA (203 Mo, une fois).'
      ],
      notes: '[[Les nouveautés de la ' + VERSION + ', et le SHA-256 de l\'installateur|release]]',
      more: 'Ce que permet cette carte',
      yes: 'Elle permet',
      no: 'Elle ne permet pas',
      notWindows: 'La version RTX est un programme Windows : le DLSS de NVIDIA, par sa bibliothèque Streamline, ne tourne que sous Windows. Sur cet appareil, c\'est la version web.',
      keep: {
        chromium: 'Pour la garder comme une application : une fois l\'observatoire ouvert, le bouton d\'installation à droite de la barre d\'adresse de Chrome ou d\'Edge.',
        safari: 'Pour la garder comme une application : une fois l\'observatoire ouvert, dans Safari (macOS 14 ou plus récent), **Fichier → Ajouter au Dock**.',
        ios: 'Pour la garder comme une application : une fois l\'observatoire ouvert, **Partager**, puis **Sur l\'écran d\'accueil**.',
        android: 'Pour la garder comme une application : une fois l\'observatoire ouvert, le menu du navigateur, puis **Installer l\'application** ou **Ajouter à l\'écran d\'accueil**.'
      },
      kinds: {
        rtx5080: {
          say: 'C\'est la carte sur laquelle la version RTX a été mesurée : les chiffres ci-dessous sont les siens.',
          yes: ['Ce que dit la liste ci-dessous : le path tracing avec DLSS Ray Reconstruction à 60 images par seconde, DLSS Frame Generation, DLAA.'],
          no: ['Ce que la liste ci-dessous dit qu\'elle ne permet pas : le path tracing à la pleine résolution 4K à 60 images par seconde.']
        },
        geforce_rtx: {
          say: 'Une carte GeForce RTX : la version RTX devrait y tourner, avec DLSS et le path tracing. Elle n\'a tourné que sur une RTX 5080 : ce qu\'elle permet ici est attendu, pas mesuré.',
          yes: RTX_YES_FR, no: RTX_NO_FR
        },
        nvidia_rtx: {
          say: 'Une carte NVIDIA RTX : la version RTX devrait y tourner, avec DLSS et le path tracing. Elle n\'a tourné que sur une GeForce RTX 5080 : ce qu\'elle permet ici est attendu, pas mesuré.',
          yes: RTX_YES_FR, no: RTX_NO_FR
        },
        nvidia_masked: {
          say: 'Une carte NVIDIA, mais votre navigateur ne dit pas laquelle (Firefox nomme une famille de cartes). Si c\'est une GeForce RTX, prenez la version RTX ; sinon, la version web.',
          yes: [], no: []
        },
        nvidia_other: {
          say: 'Une carte NVIDIA sans RTX : la version web est celle qu\'il lui faut.',
          yes: ['La version web, dans ce navigateur.', 'Peut-être la version RTX sans ses extras, en rastérisation : non testé sur une telle carte.'],
          no: ['DLSS, la génération d\'images et le path tracing : il leur faut une carte RTX.']
        },
        other: {
          say: 'Pas une carte NVIDIA : la version web est celle qu\'il lui faut.',
          yes: ['La version web, dans ce navigateur.'],
          no: ['DLSS, la génération d\'images et le path tracing : ils sont à NVIDIA et demandent une carte GeForce RTX.', 'La version RTX sur une carte d\'une autre marque : non testé.']
        },
        software: {
          say: 'Votre navigateur dessine WebGL sans carte graphique (rendu logiciel) : la version web sera lente ici, et cette page ne peut pas dire quelle carte a la machine.',
          yes: [], no: []
        },
        unknown: {
          say: 'Votre navigateur ne dit pas de quelle carte il s\'agit. Avec une carte GeForce RTX sous Windows, prenez la version RTX ; sinon, la version web.',
          yes: [], no: []
        }
      }
    },
    es: {
      detected: 'Su navegador nombra esta tarjeta: ',
      windows: ', en Windows',
      local: ' (leído en esta página; no se envía nada).',
      install: 'Instalar la versión RTX',
      installSub: 'instalador de Windows · 71 MB · versión ' + VERSION,
      play: 'Jugar en el navegador',
      playSub: 'WebGL 2 · unos 55 MB, ordenador o teléfono',
      after: 'Una vez descargado:',
      started: 'La descarga ha comenzado. Una vez terminada:',
      steps: [
        'Abra el archivo. Se instala en unos segundos, solo para su cuenta de Windows, sin derechos de administrador. Si Windows dice que protegió su PC (el instalador no está firmado): **Más información**, y luego **Ejecutar de todas formas**.',
        'Inicie **Observatory RTX** desde el menú Inicio.',
        'La primera vez, pulse **Intro** para obtener los archivos DLSS de NVIDIA (203 MB, una sola vez).'
      ],
      notes: '[[Las novedades de la ' + VERSION + ', y el SHA-256 del instalador|release]]',
      more: 'Lo que permite esta tarjeta',
      yes: 'Permite',
      no: 'No permite',
      notWindows: 'La versión RTX es un programa de Windows: el DLSS de NVIDIA, mediante su biblioteca Streamline, solo funciona en Windows. En este dispositivo, la versión web es la que corresponde.',
      keep: {
        chromium: 'Para conservarla como aplicación: una vez abierto el observatorio, el botón de instalar a la derecha de la barra de direcciones de Chrome o Edge.',
        safari: 'Para conservarla como aplicación: una vez abierto el observatorio, en Safari (macOS 14 o posterior), **Archivo → Añadir al Dock**.',
        ios: 'Para conservarla como aplicación: una vez abierto el observatorio, **Compartir** y luego **Añadir a pantalla de inicio**.',
        android: 'Para conservarla como aplicación: una vez abierto el observatorio, el menú del navegador y luego **Instalar aplicación** o **Añadir a pantalla de inicio**.'
      },
      kinds: {
        rtx5080: {
          say: 'Es la tarjeta en la que se midió la versión RTX: las cifras de abajo son las suyas.',
          yes: ['Lo que dice la lista de abajo: path tracing con DLSS Ray Reconstruction a 60 imágenes por segundo, DLSS Frame Generation, DLAA.'],
          no: ['Lo que la lista de abajo dice que no permite: path tracing a la resolución 4K completa a 60 imágenes por segundo.']
        },
        geforce_rtx: {
          say: 'Una tarjeta GeForce RTX: la versión RTX debería funcionar en ella, con DLSS y path tracing. Solo se ha ejecutado en una RTX 5080: lo que permite aquí es lo esperado, no lo medido.',
          yes: RTX_YES_ES, no: RTX_NO_ES
        },
        nvidia_rtx: {
          say: 'Una tarjeta NVIDIA RTX: la versión RTX debería funcionar en ella, con DLSS y path tracing. Solo se ha ejecutado en una GeForce RTX 5080: lo que permite aquí es lo esperado, no lo medido.',
          yes: RTX_YES_ES, no: RTX_NO_ES
        },
        nvidia_masked: {
          say: 'Una tarjeta NVIDIA, pero su navegador no dice cuál (Firefox nombra una familia de tarjetas). Si es una GeForce RTX, use la versión RTX; si no, la versión web.',
          yes: [], no: []
        },
        nvidia_other: {
          say: 'Una tarjeta NVIDIA sin RTX: la versión web es la que le corresponde.',
          yes: ['La versión web, en este navegador.', 'Quizá la versión RTX sin sus extras, rasterizada: sin probar en una tarjeta así.'],
          no: ['DLSS, la generación de imágenes y el path tracing: necesitan una tarjeta RTX.']
        },
        other: {
          say: 'No es una tarjeta NVIDIA: la versión web es la que le corresponde.',
          yes: ['La versión web, en este navegador.'],
          no: ['DLSS, la generación de imágenes y el path tracing: son de NVIDIA y necesitan una tarjeta GeForce RTX.', 'La versión RTX en una tarjeta de otra marca: sin probar.']
        },
        software: {
          say: 'Su navegador dibuja WebGL sin tarjeta gráfica (renderizado por software): la versión web irá lenta aquí, y esta página no puede saber qué tarjeta tiene el equipo.',
          yes: [], no: []
        },
        unknown: {
          say: 'Su navegador no dice qué tarjeta es. Con una tarjeta GeForce RTX en Windows, use la versión RTX; si no, la versión web.',
          yes: [], no: []
        }
      }
    }
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { clean: clean, system: system, keep: keep, classify: classify, offer: offer, TEXT: TEXT, LINKS: LINKS, VERSION: VERSION };
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
    '@media (max-width:30rem){#obs-gpu .obs-btn{flex:1 1 100%}}'
  ].join('');

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

  function list(box, title, items, links) {
    if (!items.length) {
      return;
    }
    var p = document.createElement('p');
    var strong = document.createElement('strong');
    strong.textContent = title;
    p.appendChild(strong);
    box.appendChild(p);
    var ul = document.createElement('ul');
    for (var i = 0; i < items.length; i++) {
      var li = document.createElement('li');
      fill(li, items[i], links);
      ul.appendChild(li);
    }
    box.appendChild(ul);
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
    var links = { rtx: LINKS.rtx, release: LINKS.release, nvidia: LINKS.nvidia, web: box.getAttribute('data-web') || LINKS.web };
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
    fill(say, o.notWindows ? t.notWindows : k.say, links);
    box.appendChild(say);

    // not-content: Starlight's prose styles (link colour, underline, spacing) stay off the buttons.
    var actions = document.createElement('div');
    actions.className = 'obs-actions not-content';
    var rtx = o.rtx ? button(links.rtx, t.install, t.installSub, o.first === 'rtx') : null;
    var web = button(links.web, t.play, t.playSub, o.first === 'web');
    if (rtx && o.first === 'rtx') {
      actions.appendChild(rtx);
      actions.appendChild(web);
    } else {
      actions.appendChild(web);
      if (rtx) {
        actions.appendChild(rtx);
      }
    }
    box.appendChild(actions);
    if (o.first === 'web' && found.keep) {
      var app = document.createElement('p');
      fill(app, t.keep[found.keep], links);
      box.appendChild(app);
    }

    if (rtx) {
      var steps = document.createElement('div');
      steps.className = 'obs-steps';
      steps.hidden = o.first !== 'rtx';
      var after = document.createElement('p');
      after.className = 'obs-after';
      after.textContent = t.after;
      steps.appendChild(after);
      var ol = document.createElement('ol');
      for (var i = 0; i < t.steps.length; i++) {
        var li = document.createElement('li');
        fill(li, t.steps[i], links);
        ol.appendChild(li);
      }
      steps.appendChild(ol);
      var notes = document.createElement('p');
      fill(notes, t.notes, links);
      steps.appendChild(notes);
      box.appendChild(steps);
      // The installer downloads in place (GitHub serves it as an attachment): the page stays, and says what next.
      rtx.addEventListener('click', function () {
        steps.hidden = false;
        steps.className = 'obs-steps started';
        after.textContent = t.started;
      });
    }

    if (k.yes.length || k.no.length) {
      if (!o.notWindows) {
        var more = document.createElement('details');
        var summary = document.createElement('summary');
        summary.textContent = t.more;
        more.appendChild(summary);
        list(more, t.yes, k.yes, links);
        list(more, t.no, k.no, links);
        box.appendChild(more);
      }
    }
    box.setAttribute('data-kind', found.kind);
    box.setAttribute('data-first', o.first);
    box.setAttribute('data-os', found.os);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', show);
  } else {
    show();
  }
})();
