OBSERVATORY RTX 0.2.0
The Observatory of https://spareilleux.github.io/learn/observatory/ (version 43 of the scene),
native on Windows, with DLSS, frame generation and path tracing.

English - Français - Español


ENGLISH
=======

What you need
  - A GeForce RTX 5080. It is the only card this build was run on. Other GeForce RTX cards: not tested.
  - Windows 10 or 11, 64-bit, with a recent NVIDIA driver (run with 617.14 on Windows 11).
  - 230 MB of disk, and an internet connection the first time.

Start
  1. Double-click Observatory-RTX-0.2.0-win64.msi. It installs for your account only, without
     administrator rights, into %LOCALAPPDATA%\Programs\Observatory-RTX, and adds Observatory RTX to
     the Start menu. (The zip holds the same files: extract it to a folder of your own, not Program
     Files, and double-click Observatory-RTX.cmd.)
  2. Start Observatory RTX from the Start menu.
  3. The first time, a window asks whether to fetch NVIDIA's DLSS files: press Enter.
     They come from NVIDIA's own release on GitHub (203 MB, once; about 95 MB are kept), the download's
     SHA-256 and NVIDIA's signature on each file are checked, and they are put beside the program.
     They are NVIDIA's software under NVIDIA's licences (nvidia-licenses folder), not part of this package.
     Press N to start without them: no DLSS and no path tracing. Setup-DLSS.cmd asks again later.

  Windows may say it protected your PC, because the installer and the program are not signed: More
  info, then Run anyway.
  Once NVIDIA's files are there, Observatory-RTX.exe can also be started directly.

What you see
  With NVIDIA's files, the Observatory starts path traced, with DLSS Ray Reconstruction, at DLSS
  Quality. Materials come into the rays over the first half minute.
  The program aims at 60 frames a second. Under 56 for five seconds, it goes one DLSS setting down
  (Balanced, Performance); with room to spare, one up (to DLAA at most); under 20
  at the last setting, it switches path tracing off, and says so. "(auto)" on the DLSS button means
  the program chooses; what you choose yourself stays as you chose it.
  Rasterized (F9), it runs DLAA: DLSS as anti-aliasing alone, at the window's full resolution.
  Path traced, light is followed for 2 bounces, and the hall and the wing's gallery have lamps the
  rasterized picture does without: there, an ambient light reaches everywhere; in the rays, only
  where a lamp does.

Buttons and keys
  A column on the left has a button for each feature, with its state, its key and a line that says
  what it does. Click, or press the key (Esc first releases the mouse if the scene holds it):
  F6    Max out: every setting at its best for the picture (path traced DLAA, 3 bounces, frame
        generation, everything that moves), not held at 60 frames a second; again, back to the start
  F9    path tracing with DLSS Ray Reconstruction, on and off
  F7    next DLSS setting: DLAA, Quality, Balanced, Performance, off (Ultra Performance finds no
        DLSS mode in this build: it is left out)
  F8    DLSS Frame Generation, on and off
  F5    light bounces, 1 to 4, while path tracing
  F10   hides the column, the line and the badge, then all but a small RTX button, then shows them
  Buttons alone: the anti-aliasing without DLSS (MSAA 4x + TAA by default: MSAA alone flickers ten
  times more while you turn), and what moves: glyphs falling down the green rain, the departments'
  banners as cloth in a draught, a little dust in the light.
  The scene's own keys are shown at the top left: WASD to walk, F to fly, 1-9 for the views, Tab for
  the curios, G to ride in the gardens. Esc releases the mouse; Alt+F4 closes the window.
  The badge at the bottom right is green while DLSS really runs.

Measured on the author's machine (RTX 5080, window of 3840 x 2054, in the hall)
  Path tracing with Ray Reconstruction, frames rendered a second and GPU time a frame:
    DLSS Quality (2562 x 1371 rendered)     60    15.3 ms    what it starts at, and stays at
    DLSS Balanced (2228 x 1192 rendered)    60    11.7 ms
    DLAA (3840 x 2054 rendered)             34    29.6 ms
    DLSS Quality with 3 bounces             55    18.3 ms    why it stops at 2
  Frame generation adds its own frames between the rendered ones.
  Max out (DLAA, 3 bounces, frame generation): 23 rendered, about 46 shown, 40.6 ms.
  The glyphs, the cloth and the dust add 0.3 ms. Rasterized, DLAA: 60 frames a second, 10.0 ms.
  Elsewhere at DLSS Quality, path traced: 14 to 15 ms in the wing, 8 to 10 ms outdoors.

Not verified
  Any other card, any other machine, Windows 10, and a download made by a browser (this package was
  run from a folder on the author's machine). If it does not start, the log is in
  %APPDATA%\Godot\app_userdata\Observatory RTX\logs.

Remove
  Settings, Apps, Installed apps, Observatory RTX, Uninstall: the program, NVIDIA's files fetched beside
  it and the Start menu entry go. From the zip: delete the folder. Either way, also delete
  %APPDATA%\Godot\app_userdata\Observatory RTX (settings, logs, shader cache) if you wish.
  "Setup-DLSS.cmd remove" takes NVIDIA's files away alone.

Licences: LICENSES.txt and GODOT_COPYRIGHT.txt. NVIDIA, GeForce, RTX and DLSS are trademarks of NVIDIA
Corporation; this package is not sponsored, endorsed or supported by NVIDIA.


FRANÇAIS
========

Ce qu'il faut
  - Une GeForce RTX 5080. C'est la seule carte sur laquelle cette version a tourné. Les autres
    GeForce RTX : non testées.
  - Windows 10 ou 11, 64 bits, avec un pilote NVIDIA récent (exécuté avec le 617.14 sous Windows 11).
  - 230 Mo de disque, et une connexion internet la première fois.

Démarrer
  1. Double-cliquez sur Observatory-RTX-0.2.0-win64.msi. Il s'installe pour votre compte seulement,
     sans droits d'administrateur, dans %LOCALAPPDATA%\Programs\Observatory-RTX, et ajoute
     Observatory RTX au menu Démarrer. (Le zip contient les mêmes fichiers : extrayez-le dans un
     dossier à vous, pas Program Files, et double-cliquez sur Observatory-RTX.cmd.)
  2. Lancez Observatory RTX depuis le menu Démarrer.
  3. La première fois, une fenêtre demande s'il faut récupérer les fichiers DLSS de NVIDIA : appuyez
     sur Entrée. Ils viennent de la publication de NVIDIA sur GitHub (203 Mo, une fois ; environ 95 Mo
     sont gardés), le SHA-256 du téléchargement et la signature NVIDIA de chaque fichier sont vérifiés,
     puis ils sont placés à côté du programme. Ce sont des logiciels de NVIDIA sous les licences de
     NVIDIA (dossier nvidia-licenses), ils ne font pas partie de ce paquet.
     Appuyez sur N pour démarrer sans eux : ni DLSS ni path tracing. Setup-DLSS.cmd repose la question.

  Windows peut dire qu'il a protégé votre ordinateur, car l'installeur et le programme ne sont pas
  signés : Informations complémentaires, puis Exécuter quand même.
  Une fois les fichiers de NVIDIA en place, Observatory-RTX.exe peut aussi être lancé directement.

Ce que vous voyez
  Avec les fichiers de NVIDIA, l'Observatoire démarre en path tracing, avec DLSS Ray Reconstruction, en
  DLSS Quality. Les matériaux arrivent dans les rayons pendant la première demi-minute.
  Le programme vise 60 images par seconde. Sous 56 pendant cinq secondes, il descend d'un réglage DLSS
  (Balanced, Performance) ; avec de la marge, il remonte d'un réglage (jusqu'à DLAA
  au plus) ; sous 20 au dernier réglage, il coupe le path tracing et le dit. « (auto) » sur le bouton
  DLSS signifie que le programme choisit ; ce que vous choisissez vous-même reste comme vous l'avez
  choisi.
  En rastérisation (F9), il tourne en DLAA : DLSS comme anticrénelage seul, à la pleine résolution de
  la fenêtre.
  En path tracing, la lumière est suivie sur 2 rebonds, et la salle et la galerie de l'aile ont des
  lampes dont l'image rastérisée se passe : là, une lumière ambiante arrive partout ; dans les
  rayons, seulement là où une lampe arrive.

Boutons et touches
  Une colonne à gauche a un bouton pour chaque fonction, avec son état, sa touche et une ligne qui dit
  ce qu'elle fait. Cliquez, ou appuyez sur la touche (Échap libère d'abord la souris si la scène la
  tient) :
  F6    Max out : chaque réglage au mieux pour l'image (DLAA en path tracing, 3 rebonds, génération
        d'images, tout ce qui bouge), sans tenir 60 images par seconde ; de nouveau, retour au départ
  F9    path tracing avec DLSS Ray Reconstruction, activé ou non
  F7    réglage DLSS suivant : DLAA, Quality, Balanced, Performance, désactivé (Ultra Performance ne
        trouve pas de mode DLSS dans cette version : il est omis)
  F8    DLSS Frame Generation, activé ou non
  F5    rebonds de la lumière, de 1 à 4, en path tracing
  F10   masque la colonne, la ligne et la pastille, puis tout sauf un petit bouton RTX, puis les montre
  Boutons seuls : l'anticrénelage sans DLSS (MSAA 4x + TAA par défaut : le MSAA seul scintille dix
  fois plus quand on tourne), et ce qui bouge : des glyphes qui tombent le long de la pluie verte,
  les bannières des départements en tissu dans un courant d'air, un peu de poussière dans la lumière.
  Les touches de la scène sont affichées en haut à gauche : WASD (ou ZQSD) pour marcher, F pour voler,
  1-9 pour les vues, Tab pour les curiosités, G pour rouler dans les jardins. Échap libère la souris ;
  Alt+F4 ferme la fenêtre.
  La pastille en bas à droite est verte tant que DLSS tourne vraiment.

Mesuré sur la machine de l'auteur (RTX 5080, fenêtre de 3840 x 2054, dans la salle)
  Path tracing avec Ray Reconstruction, images rendues par seconde et temps de GPU par image :
    DLSS Quality (2562 x 1371 rendus)     60    15,3 ms    le réglage de départ, et il y reste
    DLSS Balanced (2228 x 1192 rendus)    60    11,7 ms
    DLAA (3840 x 2054 rendus)             34    29,6 ms
    DLSS Quality avec 3 rebonds           55    18,3 ms    pourquoi il s'arrête à 2
  La génération d'images ajoute les siennes entre les images rendues.
  Max out (DLAA, 3 rebonds, génération d'images) : 23 rendues, environ 46 affichées, 40,6 ms.
  Les glyphes, le tissu et la poussière ajoutent 0,3 ms. En rastérisation, DLAA : 60 images par
  seconde, 10,0 ms.
  Ailleurs en DLSS Quality, en path tracing : 14 à 15 ms dans l'aile, 8 à 10 ms dehors.

Non vérifié
  Toute autre carte, toute autre machine, Windows 10, et un téléchargement fait par un navigateur (ce
  paquet a été exécuté depuis un dossier de la machine de l'auteur). S'il ne démarre pas, le journal
  est dans %APPDATA%\Godot\app_userdata\Observatory RTX\logs.

Supprimer
  Paramètres, Applications, Applications installées, Observatory RTX, Désinstaller : le programme, les
  fichiers de NVIDIA récupérés à côté et l'entrée du menu Démarrer s'en vont. Depuis le zip : supprimez
  le dossier. Dans les deux cas, supprimez aussi %APPDATA%\Godot\app_userdata\Observatory RTX
  (réglages, journaux, cache de shaders) si vous le souhaitez. « Setup-DLSS.cmd remove » retire
  seulement les fichiers de NVIDIA.

Licences : LICENSES.txt et GODOT_COPYRIGHT.txt. NVIDIA, GeForce, RTX et DLSS sont des marques de NVIDIA
Corporation ; ce paquet n'est ni parrainé, ni approuvé, ni pris en charge par NVIDIA.


ESPAÑOL
=======

Lo que hace falta
  - Una GeForce RTX 5080. Es la única tarjeta en la que se ha ejecutado esta versión. Las demás
    GeForce RTX: sin probar.
  - Windows 10 u 11, 64 bits, con un controlador NVIDIA reciente (ejecutado con el 617.14 en Windows 11).
  - 230 MB de disco, y conexión a internet la primera vez.

Iniciar
  1. Haga doble clic en Observatory-RTX-0.2.0-win64.msi. Se instala solo para su cuenta, sin derechos
     de administrador, en %LOCALAPPDATA%\Programs\Observatory-RTX, y añade Observatory RTX al menú
     Inicio. (El zip contiene los mismos archivos: extráigalo en una carpeta suya, no Program Files, y
     haga doble clic en Observatory-RTX.cmd.)
  2. Inicie Observatory RTX desde el menú Inicio.
  3. La primera vez, una ventana pregunta si descargar los archivos DLSS de NVIDIA: pulse Intro.
     Vienen de la publicación de NVIDIA en GitHub (203 MB, una vez; se conservan unos 95 MB), se
     comprueban el SHA-256 de la descarga y la firma de NVIDIA de cada archivo, y se colocan junto al
     programa. Son software de NVIDIA bajo las licencias de NVIDIA (carpeta nvidia-licenses), no forman
     parte de este paquete.
     Pulse N para iniciar sin ellos: ni DLSS ni path tracing. Setup-DLSS.cmd vuelve a preguntar.

  Windows puede decir que protegió su PC, porque el instalador y el programa no están firmados: Más
  información, y luego Ejecutar de todas formas.
  Con los archivos de NVIDIA instalados, Observatory-RTX.exe también puede iniciarse directamente.

Lo que se ve
  Con los archivos de NVIDIA, el Observatorio se inicia con path tracing, con DLSS Ray Reconstruction,
  en DLSS Quality. Los materiales entran en los rayos durante el primer medio minuto.
  El programa busca 60 imágenes por segundo. Por debajo de 56 durante cinco segundos, baja un ajuste
  de DLSS (Balanced, Performance); con margen, sube uno (hasta DLAA como máximo);
  por debajo de 20 en el último ajuste, desactiva el path tracing y lo dice. «(auto)» en el botón de
  DLSS significa que el programa elige; lo que usted elija se queda como lo eligió.
  Rasterizado (F9), funciona con DLAA: DLSS solo como antialiasing, a la resolución completa de la
  ventana.
  Con path tracing, la luz se sigue durante 2 rebotes, y la sala y la galería del ala tienen lámparas
  que la imagen rasterizada no necesita: allí, una luz ambiente llega a todas partes; en los rayos,
  solo adonde llega una lámpara.

Botones y teclas
  Una columna a la izquierda tiene un botón para cada función, con su estado, su tecla y una línea
  que dice lo que hace. Haga clic, o pulse la tecla (Esc libera antes el ratón si la escena lo
  retiene):
  F6    Max out: cada ajuste al máximo para la imagen (DLAA con path tracing, 3 rebotes, generación de
        imágenes, todo lo que se mueve), sin mantener 60 imágenes por segundo; otra vez, vuelta al inicio
  F9    path tracing con DLSS Ray Reconstruction, activado o no
  F7    siguiente ajuste de DLSS: DLAA, Quality, Balanced, Performance, desactivado (Ultra Performance
        no encuentra modo DLSS en esta versión: se omite)
  F8    DLSS Frame Generation, activado o no
  F5    rebotes de la luz, de 1 a 4, con path tracing
  F10   oculta la columna, la línea y el distintivo, luego todo salvo un pequeño botón RTX, y después
        los muestra
  Solo botones: el antialiasing sin DLSS (MSAA 4x + TAA por defecto: el MSAA solo parpadea diez veces
  más al girar), y lo que se mueve: glifos que caen por la lluvia verde, los estandartes de los
  departamentos como tela en una corriente de aire, un poco de polvo en la luz.
  Las teclas de la escena se muestran arriba a la izquierda: WASD para caminar, F para volar, 1-9 para
  las vistas, Tab para las curiosidades, G para pasear por los jardines. Esc libera el ratón; Alt+F4
  cierra la ventana.
  El distintivo de abajo a la derecha está en verde mientras DLSS funciona de verdad.

Medido en la máquina del autor (RTX 5080, ventana de 3840 x 2054, en la sala)
  Path tracing con Ray Reconstruction, imágenes renderizadas por segundo y tiempo de GPU por imagen:
    DLSS Quality (2562 x 1371 renderizados)     60    15,3 ms    el ajuste inicial, y en él se queda
    DLSS Balanced (2228 x 1192 renderizados)    60    11,7 ms
    DLAA (3840 x 2054 renderizados)             34    29,6 ms
    DLSS Quality con 3 rebotes                  55    18,3 ms    por qué se detiene en 2
  La generación de imágenes añade las suyas entre las renderizadas.
  Max out (DLAA, 3 rebotes, generación de imágenes): 23 renderizadas, unas 46 mostradas, 40,6 ms.
  Los glifos, la tela y el polvo añaden 0,3 ms. Rasterizado, DLAA: 60 imágenes por segundo, 10,0 ms.
  En otros lugares con DLSS Quality y path tracing: de 14 a 15 ms en el ala, de 8 a 10 ms fuera.

Sin verificar
  Cualquier otra tarjeta, cualquier otra máquina, Windows 10, y una descarga hecha con un navegador
  (este paquete se ejecutó desde una carpeta de la máquina del autor). Si no se inicia, el registro
  está en %APPDATA%\Godot\app_userdata\Observatory RTX\logs.

Quitar
  Configuración, Aplicaciones, Aplicaciones instaladas, Observatory RTX, Desinstalar: el programa, los
  archivos de NVIDIA descargados junto a él y la entrada del menú Inicio desaparecen. Desde el zip:
  elimine la carpeta. En ambos casos, elimine también %APPDATA%\Godot\app_userdata\Observatory RTX
  (ajustes, registros, caché de shaders) si lo desea. «Setup-DLSS.cmd remove» retira solo los
  archivos de NVIDIA.

Licencias: LICENSES.txt y GODOT_COPYRIGHT.txt. NVIDIA, GeForce, RTX y DLSS son marcas de NVIDIA
Corporation; este paquete no está patrocinado, avalado ni respaldado por NVIDIA.
