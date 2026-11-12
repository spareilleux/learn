---
title: Démos
description: Ce qu'on peut jouer ou regarder ici — l'observatoire 3D, le Colosse de BRUTAL et sa ville Lego, les scènes three.js et les prototypes de Guitar Alchemist.
---

Certains cours aboutissent à quelque chose qu'on peut voir. Cette page les rassemble. Les premières démos tournent dans votre navigateur, sur ordinateur ou sur téléphone. Les autres sont des programmes natifs qui ne tournent que sur la machine de l'auteur : elles sont montrées ici en vidéo et en captures.

## Dans le navigateur

### Observatoire interactif

**[Jouer dans le navigateur](../../demos/observatory/)** · [À propos de l'observatoire](../observatory/)

Une scène 3D faite avec [Godot](https://godotengine.org/), à partir d'un modèle construit dans Blender et de textures générées en local avec ComfyUI. La version web demande un navigateur récent avec WebGL 2 et télécharge environ 55 Mo la première fois. Une version RTX, en path tracing avec DLSS, s'installe sous Windows avec une carte GeForce RTX. Les versions Linux et macOS sont rastérisées.

### Scènes three.js

Quatre scènes complètes du [cours three.js](../threejs/) :

- [Une guitare à jouer](../../threejs-demos/demos/guitar.html) : cliquez une corde entre deux frettes, ou grattez des accords (leçon 5).
- [Une guitare en studio](../../threejs-demos/demos/studio.html) : exposition, lumières, bloom et néon, réglés depuis un panneau (leçon 7).
- [Médiators](../../threejs-demos/demos/physics.html) : lancez des médiators sur le manche, simulés avec Rapier (leçon 10).
- [Voicings](../../threejs-demos/demos/voicing.html) : choisissez un accord et un voicing, voyez-le sur le manche et écoutez-le (leçon 13).

Chaque leçon a aussi sa propre démo, plus petite.

### Laboratoire Guitar Alchemist

Deux prototypes du [Laboratoire Guitar Alchemist](../ga-lab/) :

- [P1 : explorateur de l'espace des voicings](../ga-lab/01-voicing-explorer/) : 30 000 voicings de guitare de Guitar Alchemist en nuage de points 3D, à faire tourner, cliquer et écouter.
- [P2 : joue un accord, vois l'univers](../ga-lab/02-chord-universe/) : un reconnaisseur d'accords qui tourne dans le navigateur, dessiné sur un manche en 3D.

## Vidéos et captures

### BRUTAL : le Colosse

<figure>
<a href="../observatory/brutal/"><img src="../../demos/brutal/colossus-day.jpg" alt="Le visage de l'essaim parmi les tours, dans la brume de l'après-midi, le soleil à côté" width="1280" height="536" loading="lazy" /></a>
<figcaption>L'après-midi : le visage parmi les tours.</figcaption>
</figure>

Un prototype en C# et Vulkan construit avec [BRUTAL](https://github.com/ahwootech/BRUTAL) pour essayer un autre moteur pour l'observatoire. Dix mille corps volent entre des tours brutalistes et se rassemblent en un visage colossal, en path tracing sur une GeForce RTX avec DLSS. **[Voir la vidéo d'une minute](../observatory/brutal/)**.

### Lego

<figure>
<img src="../../demos/lego/lego-polis-rtx-20261021.jpg" alt="Une cité grecque fortifiée vue d'en haut au coucher du soleil : maisons aux toits de tuiles, agora, théâtre et acropole sur sa terrasse, avec les tours du Colosse derrière" width="1600" height="900" loading="lazy" />
<figcaption>La polis : remparts, maisons, agora, théâtre et acropole, dans la ville du Colosse.</figcaption>
</figure>

Une petite bibliothèque F# compose des scènes à partir de blocs typés et imbriqués. Une colonne, puis une colonnade de colonnes, puis un temple de colonnades, et ainsi de suite jusqu'à une cité fortifiée : la polis. Elle compte 406 instances de blocs et 6 663 boîtes, sur cinq niveaux d'imbrication : polis, acropole, propylée, temple, colonnade, colonne. Chaque bloc place les autres par leur nom et leur version, avec ses propres arguments ; aucun ne recopie la logique d'un autre.

La bibliothèque ne dessine rien. Elle génère une scène, puis la valide, et une scène refusée n'atteint jamais le moteur. Ses tests tournent sans moteur. La polis et l'acropole sont dessinées par BRUTAL avec les fonctions RTX du Colosse : DLAA et Ray Reconstruction.

<figure>
<img src="../../demos/lego/lego-acropolis-rtx-20261021.jpg" alt="Une acropole au coucher du soleil : un grand escalier monte vers une terrasse portant un grand temple, un porche entre deux stoas et une tholos ronde, parmi des tours éclairées" width="1600" height="900" loading="lazy" />
<figcaption>L'acropole : un escalier, un porche entre deux stoas, des temples et une tholos sur la terrasse.</figcaption>
</figure>

<figure>
<img src="../../demos/lego/lego-sanctuary-20261021.png" alt="Un grand temple entouré de temples plus petits sur un plan gris, sans effets de lumière" width="1280" height="720" loading="lazy" />
<figcaption>La première tranche : un sanctuaire de temples autour de temples, sans les fonctions RTX.</figcaption>
</figure>

Captures du 2026-10-21. Les blocs, les conventions et les mesures sont dans [les notes de l'évaluation de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/644e25db913a53f43b1464677fd130fe79c75090/Experiments/Brutal/README.md#lego-composable-scenes-2026-10-21) (pull request [#840](https://github.com/GuitarAlchemist/ga/pull/840) de Guitar Alchemist, en anglais). Comme le Colosse, c'est une expérience locale, qui n'est pas distribuée ; le moteur est [BRUTAL](https://github.com/ahwootech/BRUTAL) d'Ahwoo, sous la BRUTAL License v1.0.

### GeoTiles : un vol de drone au-dessus d'Ottawa

<video controls playsinline preload="metadata" poster="../../demos/geotiles/ottawa-drone.jpg" width="1280" height="720" style="width: 100%; height: auto;"><source src="../../demos/geotiles/ottawa-drone.mp4" type="video/mp4"></video>

*Un vol de drone autour de la colline du Parlement, à Ottawa : 57 s, 15 Mo, sans son. Imagerie : Google Maps.*

Un programme en C# et Vulkan, construit avec [BRUTAL](https://github.com/ahwootech/BRUTAL), lit les [tuiles 3D photoréalistes](https://developers.google.com/maps/documentation/tile/3d-tiles) de Google : il ouvre une session, parcourt les jeux de tuiles imbriqués, décode les maillages Draco et leurs textures JPEG, et ramène chaque tuile des coordonnées centrées sur la Terre à un repère local autour du lieu. La caméra suit ensuite un ovale à 150 m du sol, ou le clavier et la souris prennent les commandes. Avec `--osm`, le même programme extrude à la place les bâtiments d'OpenStreetMap, sans clef.

Capture du 2026-11-11. Les tuiles sont choisies une seule fois, au départ : les plus lointaines restent donc grossières. Le code et ses mesures sont dans la pull request [#851](https://github.com/GuitarAlchemist/ga/pull/851) de Guitar Alchemist (en anglais). C'est une expérience locale, qui n'est pas distribuée : les tuiles sont lues chez Google à chaque lancement et aucune n'est conservée.

## Voir aussi

La page [Artefacts](../artifacts/) liste des pages interactives hébergées sur claude.ai, comme l'*Atlas des Douze* et un banc de placement de micros.
