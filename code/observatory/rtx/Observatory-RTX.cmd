@echo off
rem Observatory RTX: the one file to double-click.
rem The first time, it offers to fetch NVIDIA's DLSS files from NVIDIA (setup-dlss.ps1: one key, 203 MB,
rem checked before use). Then it starts the Observatory. Without those files the Observatory still starts,
rem without DLSS and without path tracing. Observatory-RTX.exe needs no argument: once NVIDIA's files are
rem there, it can be started directly.
setlocal
title Observatory RTX
rem Started from a PowerShell 7 terminal, this window carries its module path, and Windows PowerShell
rem then finds none of its own commands: cleared here, for this window only.
set "PSModulePath="
cd /d "%~dp0"
if not exist "%~dp0Observatory-RTX.exe" (
  echo Observatory-RTX.exe is not beside this file. Extract the whole zip first, then start again.
  echo Observatory-RTX.exe n'est pas a cote de ce fichier. Extrayez tout le zip, puis recommencez.
  echo Observatory-RTX.exe no esta junto a este archivo. Extraiga todo el zip y vuelva a empezar.
  pause
  exit /b 1
)
set NEED=0
if not exist "%~dp0sl.interposer.dll" set NEED=1
if not exist "%~dp0NvLowLatencyVk.dll" set NEED=1
if exist "%~dp0dlss-declined.txt" set NEED=0
if %NEED%==1 powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-dlss.ps1"
start "" "%~dp0Observatory-RTX.exe"
