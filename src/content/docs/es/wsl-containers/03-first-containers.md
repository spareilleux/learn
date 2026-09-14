---
title: 3. Primeros contenedores
description: Ejecutar, publicar, inspeccionar y detener contenedores con wslc.
sidebar:
  order: 3
---

## Orientarse en la CLI

```powershell
wslc --help              # todos los comandos
wslc <COMMAND> --help    # ayuda de un comando
wslc image list          # imágenes disponibles localmente
wslc container list      # contenedores en ejecución
wslc container list --all  # incluidos los contenedores detenidos
wslc stats               # uso de CPU / memoria de los contenedores
```

## Un contenedor desechable

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
```

| Opción | Efecto |
|---|---|
| `--rm` | elimina el contenedor en cuanto se detiene |
| `-it` | modo interactivo con una terminal |
| `ubuntu:latest` | la imagen (se descarga automáticamente si falta) |
| `bash -c "…"` | el comando que se ejecuta en el contenedor |

## Un servidor web en segundo plano

```powershell
# Ejecutar nginx en segundo plano, puerto 8080 de Windows → puerto 80 del contenedor
wslc run -d --rm -p 8080:80 --name web nginx

# Consultar el servidor desde Windows
curl localhost:8080

# Ver el contenedor
wslc container list

# Ejecutar un comando en el contenedor en ejecución
wslc exec web cat /etc/os-release

# Detenerlo (y, gracias a --rm, eliminarlo)
wslc container stop web
```

| Opción | Efecto |
|---|---|
| `-d` | separado (detached): el contenedor se ejecuta en segundo plano |
| `-p 8080:80` | publica el puerto: `host:container` |
| `--name web` | nombre legible, utilizable en lugar del ID |

:::note[Si conoces Docker]
Estos comandos son casi idénticos a `docker run`, `docker exec`, etc. La principal diferencia visible: los subcomandos están agrupados (`wslc container list` en lugar de `docker ps`).
:::

## Puntos clave

- `run` crea **e** inicia un contenedor; `--rm` evita acumular contenedores detenidos.
- `-p host:container` hace que un servicio sea accesible desde Windows.
- `exec` ejecuta un comando en un contenedor **ya en ejecución**.

## Ejercicios

1. Ejecuta un contenedor `nginx` accesible en el puerto **9090** de Windows, llamado `site`, y comprueba que responde.

<details>
<summary>Solución</summary>

```powershell
wslc run -d --rm -p 9090:80 --name site nginx
curl localhost:9090
wslc container stop site
```

</details>

2. ¿Cómo saber qué distribución Linux usa la imagen `nginx` sin abrir un shell interactivo?

<details>
<summary>Solución</summary>

```powershell
wslc run -d --rm --name site nginx
wslc exec site cat /etc/os-release
wslc container stop site
```

</details>

3. ¿Cuál es la diferencia entre `wslc container list` y `wslc container list --all`?

<details>
<summary>Solución</summary>

Sin `--all`, solo se listan los contenedores **en ejecución**. Con `--all`, también aparecen los contenedores detenidos (pero no eliminados).

</details>
