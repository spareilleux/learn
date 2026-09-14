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
Todas las distribuciones WSL se detienen durante la actualización, incluidas las de Docker Desktop y Podman. Guarda antes lo que se esté ejecutando en tus contenedores.
:::

## Verificar

```powershell
wsl --version        # debería mostrar 2.9.3 o posterior
wslc version         # confirma que la CLI está disponible
wslc run --rm hello-world
```

La última prueba descarga la imagen `hello-world` si hace falta y muestra un mensaje de bienvenida.

:::tip
Si no se encuentra `wslc` justo después de la actualización, abre una terminal **nueva**: la antigua no tiene el `PATH` actualizado.
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

**Corrección** — en una terminal de **administrador**:

```powershell
Get-Process "Docker Desktop","com.docker.backend" -ErrorAction SilentlyContinue | Stop-Process -Force
podman machine stop
wsl --shutdown
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

Si el servicio sigue sin querer detenerse: reinicia Windows y lanza la actualización **antes** de que Docker Desktop vuelva a arrancar automáticamente.

## Volver atrás

Para salir de la pre-release, reinstala una versión estable: `wsl --update` (sin `--pre-release`) o el paquete MSI estable de las [releases de WSL en GitHub](https://github.com/microsoft/WSL/releases). *Por verificar: el comportamiento exacto de la vuelta atrás desde la 2.9.x.*

## Ejercicios

1. ¿Cómo saber si una actualización de WSL ha funcionado de verdad, aunque el comando no muestre ningún error?

<details>
<summary>Solución</summary>

Vuelve a ejecutar `wsl --version` y compara la versión. En caso de duda, lee los eventos `MsiInstaller`: el evento **1033** da el estado final (`0` = éxito, `1603` = fallo) y el evento **11708** indica «Installation failed».

</details>

2. ¿Por qué hay que detener Docker Desktop antes de actualizar WSL?

<details>
<summary>Solución</summary>

Docker Desktop ejecuta su propia distro WSL, que mantiene activo el servicio `WSLService`. El instalador no puede reemplazar los archivos de un servicio que no puede detener.

</details>
