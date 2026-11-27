---
title: Demos
description: What you can play or watch here — the 3D observatory, the BRUTAL Colossus and its Lego city, the three.js scenes and the Guitar Alchemist prototypes.
---

Some courses end in something you can see. This page gathers them. The first ones run in your browser, on a computer or a phone. The others are native programs that run only on the author's machine: they are shown here as videos and captures.

## In the browser

### Playable observatory

**[Play in the browser](../demos/observatory/)** · [About the observatory](../observatory/)

A 3D scene made with [Godot](https://godotengine.org/), from a model built in Blender and textures generated locally with ComfyUI. The web version needs a recent browser with WebGL 2, and downloads about 55 MB the first time. An RTX version, path traced with DLSS, installs on Windows with a GeForce RTX card. The Linux and macOS versions are rasterized.

### three.js scenes

Four whole scenes from the [three.js course](../threejs/):

- [A guitar to play](../threejs-demos/demos/guitar.html): click a string between two frets, or strum chords (lesson 5).
- [A guitar in a studio](../threejs-demos/demos/studio.html): exposure, lights, bloom and a neon sign, set from a panel (lesson 7).
- [Picks](../threejs-demos/demos/physics.html): throw picks at the neck, simulated with Rapier (lesson 10).
- [Voicings](../threejs-demos/demos/voicing.html): pick a chord and a voicing, see it on the neck and hear it (lesson 13).

Each lesson also has its own smaller demo.

### Guitar Alchemist Lab

Two prototypes from [Guitar Alchemist Lab](../ga-lab/):

- [P1: Voicing space explorer](../ga-lab/01-voicing-explorer/): 30,000 of Guitar Alchemist's guitar voicings as a 3D point cloud to orbit, click and hear.
- [P2: Play a chord, see the universe](../ga-lab/02-chord-universe/): a chord recognizer that runs in the browser, drawn on a 3D neck.

## Videos and captures

### BRUTAL: the Colossus

<figure>
<a href="../observatory/brutal/"><img src="../demos/brutal/colossus-day.jpg" alt="The swarm's face among the towers, in the afternoon haze, with the sun beside it" width="1280" height="536" loading="lazy" /></a>
<figcaption>Afternoon: the face among the towers.</figcaption>
</figure>

A C# and Vulkan prototype built with [BRUTAL](https://github.com/ahwootech/BRUTAL) to try another engine for the observatory. Ten thousand bodies fly between brutalist towers and gather into a colossal face, path traced on a GeForce RTX with DLSS. **[Watch the one-minute video](../observatory/brutal/)**.

### Lego

<figure>
<img src="../demos/lego/lego-polis-rtx-20261021.jpg" alt="A walled Greek city seen from above at sunset: houses with tiled roofs, an agora, a theatre and an acropolis on its terrace, with the Colossus's towers behind" width="1600" height="900" loading="lazy" />
<figcaption>The polis: walls, houses, agora, theatre and acropolis, in the Colossus's city.</figcaption>
</figure>

A small F# library composes scenes from typed, nested blocks. A column, then a colonnade of columns, then a temple of colonnades, and so on up to a walled city: the polis. It holds 406 block instances and 6,663 boxes, and nests five levels deep: polis, acropolis, propylon, temple, colonnade, column. Each block places the others by name and version, with its own arguments; none copies another's logic.

The library draws nothing. It generates a scene, then validates it, and a refused scene never reaches the engine. Its tests run without an engine. The polis and the acropolis are drawn by BRUTAL with the Colossus's RTX features: DLAA and Ray Reconstruction.

<figure>
<img src="../demos/lego/lego-acropolis-rtx-20261021.jpg" alt="An acropolis at sunset: a great stair climbs to a terrace with a large temple, a porch flanked by two stoas, and a round tholos, among lit towers" width="1600" height="900" loading="lazy" />
<figcaption>The acropolis: a stair, a porch between two stoas, temples and a tholos on the terrace.</figcaption>
</figure>

<figure>
<img src="../demos/lego/lego-sanctuary-20261021.png" alt="A large temple surrounded by smaller temples on a grey plane, without lighting effects" width="1280" height="720" loading="lazy" />
<figcaption>The first slice: a sanctuary of temples around temples, without the RTX features.</figcaption>
</figure>

Captured on 2026-10-21. The blocks, conventions and measurements are in [the BRUTAL evaluation's notes](https://github.com/GuitarAlchemist/ga/blob/644e25db913a53f43b1464677fd130fe79c75090/Experiments/Brutal/README.md#lego-composable-scenes-2026-10-21) (Guitar Alchemist pull request [#840](https://github.com/GuitarAlchemist/ga/pull/840)). Like the Colossus, it is a local experiment and is not distributed; the engine is [BRUTAL](https://github.com/ahwootech/BRUTAL) by Ahwoo, under the BRUTAL License v1.0.

### GeoTiles: a drone flight over Ottawa

<video controls playsinline preload="metadata" poster="../demos/geotiles/ottawa-drone.jpg" width="1280" height="720" style="width: 100%; height: auto;"><source src="../demos/geotiles/ottawa-drone.mp4" type="video/mp4"></video>

*A drone flight around Parliament Hill, Ottawa: 57 s, 15 MB, without sound. Imagery: Google Maps.*

A C# and Vulkan program built with [BRUTAL](https://github.com/ahwootech/BRUTAL) reads Google's [Photorealistic 3D Tiles](https://developers.google.com/maps/documentation/tile/3d-tiles): it opens a session, walks the nested tilesets, decodes the Draco meshes and their JPEG textures, and moves each tile from Earth-centred coordinates to a local frame around the place. The camera then follows an oval 150 m above the ground, or the keyboard and mouse take over. With `--osm` the same program extrudes OpenStreetMap buildings instead, without a key.

Captured on 2026-11-11. The tiles are chosen once, at the start, so the far ones stay coarse. The code and its measurements are in Guitar Alchemist pull request [#851](https://github.com/GuitarAlchemist/ga/pull/851). It is a local experiment and is not distributed: the tiles are streamed from Google at each run and none is stored.

### GeoTiles: above the Château Frontenac, Quebec City

<video controls playsinline preload="metadata" poster="../demos/geotiles/quebec-drone.jpg" width="1280" height="720" style="width: 100%; height: auto;"><source src="../demos/geotiles/quebec-drone.mp4" type="video/mp4"></video>

*A drone flight above the Château Frontenac and Old Quebec: 60 s, 15 MB, without sound. Imagery: Google Maps.*

The same program and the same oval, centred on the Château Frontenac: the Dufferin Terrace, the Place d'Armes, the Citadelle and the old port on the St. Lawrence pass below the camera. The run walked 100 nested tilesets to pick 185 tiles, about 700,000 triangles, with 286 requests in one Google session, and drew them at 60 frames a second.

Captured on 2026-11-14, with the code of pull request [#851](https://github.com/GuitarAlchemist/ga/pull/851). As for Ottawa, the tiles are streamed from Google at each run and none is stored.

### GeoTiles: above the Place du Capitole, Toulouse

<video controls playsinline preload="metadata" poster="../demos/geotiles/toulouse-drone.jpg" width="1920" height="1080" style="width: 100%; height: auto;"><source src="../demos/geotiles/toulouse-drone.mp4" type="video/mp4"></video>

*A drone flight above the Place du Capitole and the old town of Toulouse: 60 s, 30 MB, without sound. Imagery: Google Maps.*

The same oval, centred on the Place du Capitole: the façade of the Capitole, the square and the garden behind it pass below the camera, among the brick and tile roofs. The run walked 122 nested tilesets to pick 216 tiles, about 965,000 triangles, with 339 requests in one Google session. It ran full screen at 3840 × 2160 and 59 frames a second; the video is 1920 × 1080.

### GeoTiles: above the Piazza di Spagna, Rome

<video controls playsinline preload="metadata" poster="../demos/geotiles/rome-drone.jpg" width="1920" height="1080" style="width: 100%; height: auto;"><source src="../demos/geotiles/rome-drone.mp4" type="video/mp4"></video>

*A drone flight above the Piazza di Spagna in Rome: 60 s, 34 MB, without sound. Imagery: Google Maps.*

The same oval, centred on the Piazza di Spagna: the Spanish Steps, the church of Trinità dei Monti and the Villa Medici above them pass below the camera. The run walked 125 nested tilesets to pick 285 tiles, about 738,000 triangles, with 411 requests in one Google session, full screen at 3840 × 2160 and 60 frames a second.

Both captured on 2026-11-25, with the code of pull request [#851](https://github.com/GuitarAlchemist/ga/pull/851); the tiles are streamed from Google at each run and none is stored.

### Delta: a tour of its hall

<video controls playsinline preload="metadata" poster="../demos/delta/delta-demo.jpg" width="1920" height="1080" style="width: 100%; height: auto;"><source src="../demos/delta/delta-demo.mp4" type="video/mp4"></video>

*Delta shows a visitor around its hall: 2 min, 31 MB, with sound. Voice: [Piper](https://github.com/rhasspy/piper) with the LJ Speech voice (public domain). Streets: © OpenStreetMap contributors.*

Delta is a small robot in a window on the author's screen: it hears the microphone, thinks with Claude and answers out loud. It lives in a hall drawn in C# and Vulkan with [BRUTAL](https://github.com/ahwootech/BRUTAL). The tour passes Pong on Delta's chest, an office where each little robot at a desk is a Claude Code session, Gaia's planet, clocks for Ottawa and Paris, a gallery of the courses and demos, a lectern to read a course, twenty-one sailors' knots and a paper crane checked by IX, a gymnasium and the streets of Ottawa. One shot turns on Max out: path tracing with DLSS Ray Reconstruction.

Filmed on 2026-11-26 in a hidden window at 1920 × 1080. The visitor's question and Delta's answers were written beforehand and spoken by Piper; nothing came from a microphone. The office shows demo sessions, not the author's. The code is in [brickyard](https://github.com/GuitarAlchemist/brickyard).

## Also

The [Artifacts](../artifacts/) page lists interactive pages hosted on claude.ai, such as the *Atlas des Douze* and a microphone placement bench.
