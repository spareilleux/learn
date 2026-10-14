// The Observatory page's "Your graphics card" block (src/content/docs/observatory/index.md and its fr/
// and es/ mirrors). It reads the name the browser gives the graphics card (WebGL's
// WEBGL_debug_renderer_info) and says which version of the Observatory suits it. Nothing leaves the page.
// The RTX 5080's measured figures are in the pages themselves; here, only what follows from a card's name.
(function () {
  'use strict';

  var LINKS = {
    rtx: 'https://github.com/spareilleux/learn/releases/download/observatory-rtx-0.2.1/Observatory-RTX-0.2.1-win64.msi',
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

  function classify(raw, userAgent) {
    var text = String(raw || '');
    var name = clean(text);
    var kind;
    if (/or similar/i.test(text)) {
      kind = 'unknown';  // Firefox names a family of cards, not this one: its name is not shown
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
    return { kind: kind, name: name, windows: /Windows/i.test(String(userAgent || '')) };
  }

  var RTX_YES_EN = [
    'DLSS, and path tracing with DLSS Ray Reconstruction: the program starts with them once NVIDIA\'s files are in place.',
    'A frame rate the program looks after: under 56 frames a second it lowers the DLSS setting; under 20 at the lowest setting, it switches path tracing off and says so.'
  ];
  var RTX_NO_EN = [
    'The RTX 5080\'s figures: a slower card runs a lower DLSS setting, or rasterized; a faster one, a higher setting.',
    'Frame generation on every series: [[NVIDIA says which cards run it|nvidia]].'
  ];
  var RTX_YES_FR = [
    'DLSS, et le path tracing avec DLSS Ray Reconstruction : le programme démarre avec eux une fois les fichiers de NVIDIA en place.',
    'Une cadence dont le programme s\'occupe : sous 56 images par seconde, il baisse le réglage DLSS ; sous 20 au dernier réglage, il coupe le path tracing et le dit.'
  ];
  var RTX_NO_FR = [
    'Les chiffres de la RTX 5080 : une carte plus lente tourne avec un réglage DLSS plus bas, ou en rastérisation ; une plus rapide, avec un réglage plus haut.',
    'La génération d\'images sur toutes les séries : [[NVIDIA dit quelles cartes la font tourner|nvidia]].'
  ];
  var RTX_YES_ES = [
    'DLSS, y path tracing con DLSS Ray Reconstruction: el programa se inicia con ellos una vez instalados los archivos de NVIDIA.',
    'Una cadencia de la que se ocupa el programa: por debajo de 56 imágenes por segundo baja el ajuste de DLSS; por debajo de 20 en el último ajuste, desactiva el path tracing y lo dice.'
  ];
  var RTX_NO_ES = [
    'Las cifras de la RTX 5080: una tarjeta más lenta funciona con un ajuste de DLSS más bajo, o rasterizada; una más rápida, con uno más alto.',
    'La generación de imágenes en todas las series: [[NVIDIA dice qué tarjetas la ejecutan|nvidia]].'
  ];

  var TEXT = {
    en: {
      detected: 'Your browser names this card: ',
      local: ' (read in this page; nothing is sent).',
      yes: 'It allows',
      no: 'It does not allow',
      notWindows: 'The RTX version is a Windows program, and this device does not seem to run Windows: the [[web version|web]] is the one for it.',
      kinds: {
        rtx5080: {
          say: 'This is the card the RTX version was measured on: [[download it|rtx]]. The figures below are for it.',
          yes: ['What the list below says: path tracing with DLSS Ray Reconstruction at 60 frames a second, DLSS Frame Generation, DLAA.'],
          no: ['What the list below says it does not: path tracing at the full 4K resolution at 60 frames a second.']
        },
        geforce_rtx: {
          say: 'A GeForce RTX card: the [[RTX version|rtx]] should run on it, with DLSS and path tracing. It has only been run on an RTX 5080: what follows is expected, not measured.',
          yes: RTX_YES_EN, no: RTX_NO_EN
        },
        nvidia_rtx: {
          say: 'An NVIDIA RTX card: the [[RTX version|rtx]] should run on it, with DLSS and path tracing. It has only been run on a GeForce RTX 5080: what follows is expected, not measured.',
          yes: RTX_YES_EN, no: RTX_NO_EN
        },
        nvidia_other: {
          say: 'An NVIDIA card without RTX: the [[web version|web]] is the one for it.',
          yes: ['The web version, in this browser.', 'Perhaps the RTX version without its extras, rasterized: not tested on such a card.'],
          no: ['DLSS, frame generation and path tracing: they need an RTX card.']
        },
        other: {
          say: 'Not an NVIDIA card: the [[web version|web]] is the one for it.',
          yes: ['The web version, in this browser.'],
          no: ['DLSS, frame generation and path tracing: they are NVIDIA\'s and need a GeForce RTX card.', 'The RTX version on a card of another make: not tested.']
        },
        software: {
          say: 'Your browser draws WebGL without a graphics card (software rendering): the [[web version|web]] will be slow here, and this page cannot tell which card the machine has.',
          yes: [], no: []
        },
        unknown: {
          say: 'Your browser does not say which card this is (Firefox, for one, names a family of cards). With a GeForce RTX card under Windows, take the [[RTX version|rtx]]; otherwise, the [[web version|web]].',
          yes: [], no: []
        }
      }
    },
    fr: {
      detected: 'Votre navigateur nomme cette carte : ',
      local: ' (lu dans cette page ; rien n\'est envoyé).',
      yes: 'Elle permet',
      no: 'Elle ne permet pas',
      notWindows: 'La version RTX est un programme Windows, et cet appareil ne semble pas tourner sous Windows : la [[version web|web]] est celle qu\'il lui faut.',
      kinds: {
        rtx5080: {
          say: 'C\'est la carte sur laquelle la version RTX a été mesurée : [[téléchargez-la|rtx]]. Les chiffres ci-dessous sont les siens.',
          yes: ['Ce que dit la liste ci-dessous : le path tracing avec DLSS Ray Reconstruction à 60 images par seconde, DLSS Frame Generation, DLAA.'],
          no: ['Ce que la liste ci-dessous dit qu\'elle ne permet pas : le path tracing à la pleine résolution 4K à 60 images par seconde.']
        },
        geforce_rtx: {
          say: 'Une carte GeForce RTX : la [[version RTX|rtx]] devrait y tourner, avec DLSS et le path tracing. Elle n\'a tourné que sur une RTX 5080 : ce qui suit est attendu, pas mesuré.',
          yes: RTX_YES_FR, no: RTX_NO_FR
        },
        nvidia_rtx: {
          say: 'Une carte NVIDIA RTX : la [[version RTX|rtx]] devrait y tourner, avec DLSS et le path tracing. Elle n\'a tourné que sur une GeForce RTX 5080 : ce qui suit est attendu, pas mesuré.',
          yes: RTX_YES_FR, no: RTX_NO_FR
        },
        nvidia_other: {
          say: 'Une carte NVIDIA sans RTX : la [[version web|web]] est celle qu\'il lui faut.',
          yes: ['La version web, dans ce navigateur.', 'Peut-être la version RTX sans ses extras, en rastérisation : non testé sur une telle carte.'],
          no: ['DLSS, la génération d\'images et le path tracing : il leur faut une carte RTX.']
        },
        other: {
          say: 'Pas une carte NVIDIA : la [[version web|web]] est celle qu\'il lui faut.',
          yes: ['La version web, dans ce navigateur.'],
          no: ['DLSS, la génération d\'images et le path tracing : ils sont à NVIDIA et demandent une carte GeForce RTX.', 'La version RTX sur une carte d\'une autre marque : non testé.']
        },
        software: {
          say: 'Votre navigateur dessine WebGL sans carte graphique (rendu logiciel) : la [[version web|web]] sera lente ici, et cette page ne peut pas dire quelle carte a la machine.',
          yes: [], no: []
        },
        unknown: {
          say: 'Votre navigateur ne dit pas de quelle carte il s\'agit (Firefox, par exemple, nomme une famille de cartes). Avec une carte GeForce RTX sous Windows, prenez la [[version RTX|rtx]] ; sinon, la [[version web|web]].',
          yes: [], no: []
        }
      }
    },
    es: {
      detected: 'Su navegador nombra esta tarjeta: ',
      local: ' (leído en esta página; no se envía nada).',
      yes: 'Permite',
      no: 'No permite',
      notWindows: 'La versión RTX es un programa de Windows, y este dispositivo no parece usar Windows: la [[versión web|web]] es la que le corresponde.',
      kinds: {
        rtx5080: {
          say: 'Es la tarjeta en la que se midió la versión RTX: [[descárguela|rtx]]. Las cifras de abajo son las suyas.',
          yes: ['Lo que dice la lista de abajo: path tracing con DLSS Ray Reconstruction a 60 imágenes por segundo, DLSS Frame Generation, DLAA.'],
          no: ['Lo que la lista de abajo dice que no permite: path tracing a la resolución 4K completa a 60 imágenes por segundo.']
        },
        geforce_rtx: {
          say: 'Una tarjeta GeForce RTX: la [[versión RTX|rtx]] debería funcionar en ella, con DLSS y path tracing. Solo se ha ejecutado en una RTX 5080: lo que sigue es lo esperado, no lo medido.',
          yes: RTX_YES_ES, no: RTX_NO_ES
        },
        nvidia_rtx: {
          say: 'Una tarjeta NVIDIA RTX: la [[versión RTX|rtx]] debería funcionar en ella, con DLSS y path tracing. Solo se ha ejecutado en una GeForce RTX 5080: lo que sigue es lo esperado, no lo medido.',
          yes: RTX_YES_ES, no: RTX_NO_ES
        },
        nvidia_other: {
          say: 'Una tarjeta NVIDIA sin RTX: la [[versión web|web]] es la que le corresponde.',
          yes: ['La versión web, en este navegador.', 'Quizá la versión RTX sin sus extras, rasterizada: sin probar en una tarjeta así.'],
          no: ['DLSS, la generación de imágenes y el path tracing: necesitan una tarjeta RTX.']
        },
        other: {
          say: 'No es una tarjeta NVIDIA: la [[versión web|web]] es la que le corresponde.',
          yes: ['La versión web, en este navegador.'],
          no: ['DLSS, la generación de imágenes y el path tracing: son de NVIDIA y necesitan una tarjeta GeForce RTX.', 'La versión RTX en una tarjeta de otra marca: sin probar.']
        },
        software: {
          say: 'Su navegador dibuja WebGL sin tarjeta gráfica (renderizado por software): la [[versión web|web]] irá lenta aquí, y esta página no puede saber qué tarjeta tiene el equipo.',
          yes: [], no: []
        },
        unknown: {
          say: 'Su navegador no dice qué tarjeta es (Firefox, por ejemplo, nombra una familia de tarjetas). Con una tarjeta GeForce RTX en Windows, use la [[versión RTX|rtx]]; si no, la [[versión web|web]].',
          yes: [], no: []
        }
      }
    }
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { clean: clean, classify: classify, TEXT: TEXT, LINKS: LINKS };
    return;
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

  // "see the [[web version|web]]" -> text nodes and links; the card's name never passes through HTML.
  function fill(parent, text, links) {
    var re = /\[\[([^|\]]+)\|([a-z]+)\]\]/g;
    var last = 0;
    var m;
    while ((m = re.exec(text))) {
      parent.appendChild(document.createTextNode(text.slice(last, m.index)));
      var a = document.createElement('a');
      a.href = links[m[2]];
      a.textContent = m[1];
      parent.appendChild(a);
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

  function show() {
    var box = document.getElementById('obs-gpu');
    if (!box) {
      return;
    }
    var lang = (document.documentElement.lang || 'en').slice(0, 2).toLowerCase();
    var t = TEXT[lang] || TEXT.en;
    var links = { rtx: LINKS.rtx, nvidia: LINKS.nvidia, web: box.getAttribute('data-web') || LINKS.web };
    var found = classify(renderer(), navigator.userAgent);
    var k = t.kinds[found.kind];
    while (box.firstChild) {
      box.removeChild(box.firstChild);
    }
    if (found.name) {
      var named = document.createElement('p');
      named.appendChild(document.createTextNode(t.detected));
      var strong = document.createElement('strong');
      strong.textContent = found.name;
      named.appendChild(strong);
      named.appendChild(document.createTextNode(t.local));
      box.appendChild(named);
    }
    var say = document.createElement('p');
    var rtxCard = found.kind === 'rtx5080' || found.kind === 'geforce_rtx' || found.kind === 'nvidia_rtx';
    fill(say, rtxCard && !found.windows ? t.notWindows : k.say, links);
    box.appendChild(say);
    if (!rtxCard || found.windows) {
      list(box, t.yes, k.yes, links);
      list(box, t.no, k.no, links);
    }
    box.setAttribute('data-kind', found.kind);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', show);
  } else {
    show();
  }
})();
