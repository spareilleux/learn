---
title: 2. Instalación
description: Pasar WSL a pre-release, verificar wslc y solucionar una actualización fallida.
sidebar:
  order: 2
---

## ¿Qué versión necesitas?

`wslc.exe` requiere **WSL 2.9.3 o posterior**. Por ahora esta rama solo existe como **pre-release**: la versión estable (2.7.x en septiembre de 2026) no incluye `wslc`.

Comprueba tu versión:

```powershell
wsl --version
```

## Actualizar

```powershell
wsl --update --pre-release
```

:::caution[La actualización detiene WSL]
Todas las distribuciones WSL se detienen durante la actualización, incluidas las de [Docker Desktop](https://docs.docker.com/desktop/) y [Podman](https://podman.io/). Guarda antes lo que se esté ejecutando en tus contenedores.
:::

## Verificar

```powershell
wsl --version        # debería mostrar 2.9.3 o posterior
wslc --version       # confirma que la CLI está disponible (wslc version también funciona)
wslc run --rm hello-world
```

```text
WSL version: 2.9.11.0
Kernel version: 6.18.40.1-1
...
wslc 2.9.11.0
Image 'hello-world' not found, pulling
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

La última prueba descarga la imagen `hello-world` y muestra su mensaje de bienvenida. «Hello from Docker!» es solo el texto incluido en la imagen: Docker Desktop no interviene, el contenedor se ejecuta con `wslc`.

:::caution[`wslc` no se reconoce]
`wslc.exe` se instala en `C:\Program Files\WSL\`, que está en el `PATH` de la máquina, pero un programa recibe una copia del entorno al arrancar. Una pestaña nueva de un [Windows Terminal](https://learn.microsoft.com/windows/terminal/) iniciado **antes** de la actualización hereda el `PATH` antiguo. Cierra todas las ventanas de Windows Terminal, o recarga el `PATH` en el PowerShell actual:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

Lo mismo ocurre con un IDE abierto antes de la actualización: MSBuild falla entonces con `WSLC0001` (ver la [lección 9](../09-csharp-api/)).
:::

## Solución de problemas: la instalación falla (error 1921 / 1603)

Esto es lo que me pasó (ver el [diario](../journal/)). El comando muestra la barra de progreso y luego termina, pero `wsl --version` sigue mostrando la versión antigua.

**Diagnóstico** — el registro *Application* de Windows contiene:

```text
Error 1921. Service 'WSL Service' (WSLService) could not be stopped.
Installation success or error status: 1603.
```

Para encontrarlo:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; StartTime=(Get-Date).AddHours(-1)} |
  Select-Object TimeCreated, Id, Message
```

**Causa** — el instalador MSI necesita detener el servicio `WSLService`, pero hay procesos que lo mantienen ocupado: Docker Desktop, Podman, terminales WSL abiertas…

**Corrección** — la secuencia que me funcionó. Primero, desde una terminal normal:

```powershell
docker desktop stop
podman machine stop
wsl --shutdown
wsl -l -v   # todas las distros deben estar en Stopped
```

Después, en una terminal de **administrador**:

```powershell
wsl --shutdown
Get-Process wsl, wslhost, wslrelay -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

Si el servicio sigue sin querer detenerse: reinicia Windows y lanza la actualización **antes** de que Docker Desktop vuelva a arrancar automáticamente.

## Volver atrás

Para salir de la pre-release, reinstala una versión estable: `wsl --update` (sin `--pre-release`) o el paquete MSI estable de las [releases de WSL en GitHub](https://github.com/microsoft/WSL/releases). *Por verificar: el comportamiento exacto de la vuelta atrás desde la 2.9.x.*

## Puntos clave

- `wslc` necesita WSL 2.9.3 o posterior, que por ahora solo existe como versión preliminar: `wsl --update --pre-release`.
- La actualización detiene todas las distribuciones de WSL, incluidas las de Docker Desktop y Podman.
- Una terminal o un IDE abiertos antes de la actualización conservan el `PATH` antiguo y no encuentran `wslc`.
- Una actualización puede fallar sin mostrar error: vuelve a ejecutar `wsl --version` y busca el error 1921 o el estado 1603 en los eventos de `MsiInstaller`.
- Si el servicio de WSL no se detiene, detén Docker Desktop, Podman y los procesos de WSL, y luego actualiza desde una terminal de administrador.

## Ejercicios

1. ¿Cómo saber si una actualización de WSL ha funcionado de verdad, aunque el comando no muestre ningún error?

<details>
<summary>Solución</summary>

Vuelve a ejecutar `wsl --version` y compara la versión. En caso de duda, lee los eventos `MsiInstaller`: el evento **1033** da el estado final (`0` = éxito, `1603` = fallo), el evento **11707** indica «Installation completed successfully» y el evento **11708**, «Installation failed». Después de mi intento exitoso:

```text
TimeCreated               Id Message
2026-09-13 12:25:19 PM  1033 Windows Installer installed the product. Product Name: Windows Subsystem for Linux. Product Version: 2.9.11.0. ...
2026-09-13 12:25:19 PM 11707 Product: Windows Subsystem for Linux -- Installation completed successfully.
```

</details>

2. ¿Por qué hay que detener Docker Desktop antes de actualizar WSL?

<details>
<summary>Solución</summary>

Docker Desktop ejecuta su propia distro WSL, que mantiene activo el servicio `WSLService`. El instalador no puede reemplazar los archivos de un servicio que no puede detener.

</details>

3. Abres una pestaña nueva en Windows Terminal después de la actualización. `wsl --version` muestra 2.9.11, pero `Get-Command wslc` responde que el término `wslc` no se reconoce. Explica por qué y da un arreglo que funcione en esa pestaña y otro que dure.

<details>
<summary>Solución</summary>

`wsl.exe` ya estaba en el `PATH` antes de la actualización, `wslc.exe` no. El proceso de Windows Terminal arrancó antes de la actualización, con el `PATH` antiguo, y cada pestaña nueva hereda una copia de él. En esa pestaña, recarga el `PATH` a partir de los valores de la máquina y del usuario con la línea `$env:Path = …` de arriba, o llama a la ruta completa, `& "C:\Program Files\WSL\wslc.exe" --version`. El arreglo duradero es cerrar **todas** las ventanas de Windows Terminal, para que no quede ningún proceso `WindowsTerminal.exe`, y volver a iniciarlo. En `cmd.exe`, la comprobación equivalente es `where wslc`.

</details>

## Fuentes

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
- [Notas de la versión de WSL — GitHub](https://github.com/microsoft/WSL/releases)
- [Registro de eventos — Windows Installer](https://learn.microsoft.com/windows/win32/msi/event-logging)
