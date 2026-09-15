---
title: Diario
description: Notas de progreso fechadas del curso de JavaScript — la instalación de Node.js 24.21.0, la CI en tres SO, sorpresas en Node.js y npm, lo que mostró el frontend de GuitarAlchemist/ga, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Node.js 24.21.0 instalado en Windows, y en CI en Linux, Windows y macOS con .NET 10 y Java 25
- [x] CI: ejemplos, snippets de error, soluciones y las comparaciones en C# y Java comparados con su salida esperada en tres SO
- [x] Lección 1: Node.js, npm y módulos
- [x] Lección 2: valores y tipos
- [x] Lección 3: funciones, ámbito, closures y `this`
- [x] Lección 4: objetos, prototipos y clases
- [ ] Lección 5: arrays, iteración y colecciones

## 2026-09-14 — Instalación de Node.js 24.21.0

- El [índice de versiones](https://nodejs.org/dist/index.json) lista la 24.21.0, publicada el 2026-09-07, como la última versión LTS, y la 26.8.2 como la última versión current. Node.js 26 pasa a LTS el 2026-10-28, según el [calendario](https://github.com/nodejs/Release/blob/main/schedule.json).
- Mi máquina ya tenía un Node.js 24.12.0 global. Lo dejé tal cual, descargué `node-v24.21.0-win-x64.zip` en una carpeta propia, comprobé su SHA-256 con `SHASUMS256.txt`, y puse esa carpeta la primera en el `PATH` de las shells que capturan las salidas de las lecciones. `node -p process.versions.v8` imprime `13.6.233.17-node.53`; el npm incluido es el 11.19.0.
- Los comandos PowerShell de la lección 1 descargaron, comprobaron y descomprimieron el archivo en 22 segundos, en una carpeta de pruebas.
- `winget show OpenJS.NodeJS.LTS` ofrecía la 24.19.0, dos versiones por detrás de nodejs.org.

## 2026-09-14 — La CI

- [`javascript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/javascript-examples.yml) instala Node.js 24.21.0 con `actions/setup-node@v7`, .NET 10 y Java 25, y ejecuta [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/javascript-for-csharp-java/check.sh). El primer push pasó en los tres SO en 1 minuto y 28 segundos: las 52 salidas capturadas en Windows son idénticas en Linux y macOS.
- Node.js imprime rutas absolutas en sus errores, como URL de archivo, como ruta de Windows, o incluso como ruta de Windows con el prefijo de rutas largas `\\?\`, como en el mensaje sobre `package.json` de la lección 1. [`normalize.mjs`](https://github.com/spareilleux/learn/blob/main/code/javascript-for-csharp-java/normalize.mjs) las hace relativas a la carpeta del curso, quita los marcos de la pila y sustituye los identificadores de proceso.
- La comparación en C# imprimía al principio `1.0 / 0` como `∞`, el símbolo de infinito del formato numérico de mi configuración regional; ahora fija `CultureInfo.InvariantCulture`, que imprime `Infinity` en todas las máquinas. Java imprimía el emoji de la guitarra como `?` en la consola de Windows, así que los programas de comparación solo imprimen ASCII.
- La CI también instala `@esbuild/win32-x64@0.25.12` como dependencia de desarrollo en cada SO, para la lección 1: npm lo instala en Windows y se detiene con `EBADPLATFORM` en Linux y macOS.

## 2026-09-14 — Sorpresas al escribir las lecciones 1-4

**La pista "Did you mean to import" de Node.js depende de la carpeta actual.** Un import de ES module sin su extensión falla con `ERR_MODULE_NOT_FOUND`, y Node.js añade una pista con la ruta correcta, pero solo cuando el comando se ejecuta desde una carpeta donde esa ruta relativa también existe. `resolveAsCommonJS` crea un módulo padre CommonJS cuyo nombre de archivo nunca se asigna ([`resolve.js`, líneas 888-895](https://github.com/nodejs/node/blob/v24.21.0/lib/internal/modules/esm/resolve.js#L888-L895)), y para un padre sin nombre de archivo el resolvedor de CommonJS busca desde `'.'` ([`loader.js`, líneas 1021-1028](https://github.com/nodejs/node/blob/v24.21.0/lib/internal/modules/cjs/loader.js#L1021-L1028)). El código es el mismo en la rama `main` de Node.js. No encontré ninguna issue al respecto buscando "Did you mean to import" en nodejs/node. `check.sh` ejecuta los snippets de error desde su propia carpeta, y ejecuta este una segunda vez desde la carpeta del curso, sin la pista.

**Una función duplicada solo es un error en el nivel superior de un módulo.** Dos declaraciones `function describe` en el mismo ES module son un `SyntaxError` antes de que se ejecute nada; las mismas dos declaraciones dentro del cuerpo de una función, o en el nivel superior de un archivo CommonJS, se aceptan, y gana la segunda. Había escrito el duplicado en el nivel superior del ejemplo de la lección 3 para mostrar la sustitución silenciosa, y obtuve el error en su lugar.

**`[1, 2, 3].map(multiply)` imprime `[ 0, 2, 6 ]`.** Pasé `multiply` a `map` como ejemplo inofensivo de que las funciones son valores, y `map` pasó el índice como segundo argumento. El ejemplo se quedó en la lección 3, como la trampa que es, junto a `['1', '2', '3'].map(parseInt)`.

**`npm init -y` escribe `"type": "commonjs"`.** npm 11.19 añade el campo explícitamente; las plantillas anteriores lo omitían, lo que igualmente hacía que los archivos `.js` fueran CommonJS por defecto.

**Un archivo `.cjs` con `import` recibe un consejo que no se aplica.** Node.js imprime `Warning: Failed to load the ES module … Make sure to set "type": "module" in the nearest package.json file or use the .mjs extension`, y luego el `SyntaxError`. El campo `"type"` no puede ayudar a un archivo `.cjs`: su extensión manda.

**`require` de un ES module funciona sin ninguna advertencia.** Node.js 24.21.0 carga `modern.mjs` desde `from-cjs.cjs` en silencio; la [documentación](https://nodejs.org/docs/latest-v24.x/api/modules.html#loading-ecmascript-modules-using-require) dice que la funcionalidad dejó de ser experimental en la 24.15.0. Con un `await` en el nivel superior del módulo, `require` lanza `ERR_REQUIRE_ASYNC_MODULE`, lo que comprobé para la solución del ejercicio 1.

**pnpm no comprueba la plataforma de una dependencia directa.** En un proyecto de pruebas en Windows, `npx pnpm@10 add -D @esbuild/linux-x64@0.25.12` instaló el paquete de Linux sin ninguna advertencia (pnpm 10.34.5), mientras que npm lo rechaza con `EBADPLATFORM`.

## 2026-09-14 — Lo que mostró el frontend de GuitarAlchemist/ga (a826864)

Leí [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) y [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client) en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), buscando las trampas de las lecciones 1 a 4.

- **Dos archivos de bloqueo.** `Apps/ga-client` tiene un `package-lock.json` y un `pnpm-lock.yaml`; nada mantiene de acuerdo las dos resoluciones.
- **Un paquete solo para Windows en `devDependencies`.** [`ga-react-components/package.json`, línea 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/package.json#L71) lista `@esbuild/win32-x64`. La CI del curso muestra que npm rechaza ese mismo paquete en Linux y macOS; la carpeta solo tiene un `pnpm-lock.yaml`, y pnpm instaló en mi máquina un paquete de otra plataforma sin quejarse, así que el proyecto probablemente se instala con pnpm en todas partes (*por verificar* en Linux).
- **Un estado guardado que se impone a la URL.** En [`SceneOptions.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/SceneOptions.tsx#L57-L80), los parámetros de la URL se aplican antes de que `Object.assign` fusione las preferencias guardadas en `localStorage`, y cada interruptor guarda todas las claves. Tras el primer cambio, `?tower`, `?constellations`, `?weather`, `?skybox` y `?splats` ya no cambian nada. La fusión también conserva las claves desconocidas y los valores del tipo equivocado, y una clave `__proto__` sustituye el prototipo del objeto de estado. La lección 4 reproduce los tres problemas, y su ejercicio 3 los corrige. Parece un bug que merece una issue.
- **`|| 0.5` donde se quiere decir `??`.** [`BSPDoomExplorer.tsx`, línea 4895](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4895) convertiría una velocidad de rotación de 0 en 0.5. Hoy ninguna muestra recibe una velocidad de 0, así que el problema está latente. La [línea 5386](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5386) funciona porque `NaN` es falsy, no por la agrupación que parece tener.
- **Los listeners de eventos son correctos.** Las siete llamadas a `addEventListener` de los dos frontends que pasan un manejador `this.…` usan o bien una función enlazada una sola vez y guardada, o bien una función flecha guardada en un campo, y ninguna enlaza en línea; la lección 3 ejecuta los tres patrones.
- **Igualdad débil solo para `null`.** Los fuentes TypeScript usan `==` y `!=` solo como `== null` y `!= null`; las demás coincidencias son código de shaders GLSL dentro de cadenas. Sus configuraciones de ESLint extienden `js.configs.recommended`, que no activa `eqeqeq`.
- **`parseInt` sin base**, en [`BSPDoomExplorer.tsx`, línea 2421](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L2421) y [`MusicRoomLoader.ts`, líneas 209-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/MusicRoomLoader.ts#L209-L211). Las entradas son cifras decimales que vienen de un nombre o de una coincidencia de expresión regular, así que ahí es inofensivo.

## Por verificar

- Los comandos de instalación que no he ejecutado: `winget install OpenJS.NodeJS.LTS`, nvm en Linux, y el `node@24` de Homebrew en macOS.
- Si `pnpm install` de `ga-react-components` funciona en Linux y macOS con `@esbuild/win32-x64` en sus dependencias de desarrollo.
