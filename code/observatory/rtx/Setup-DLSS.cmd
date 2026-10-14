@echo off
rem Observatory RTX: fetch NVIDIA's DLSS files (again), whatever was answered the first time.
rem   Setup-DLSS.cmd           asks, downloads, checks, installs
rem   Setup-DLSS.cmd remove    takes NVIDIA's files away again
setlocal
title Observatory RTX - NVIDIA DLSS
rem Started from a PowerShell 7 terminal, this window carries its module path, and Windows PowerShell
rem then finds none of its own commands: cleared here, for this window only.
set "PSModulePath="
cd /d "%~dp0"
if exist "%~dp0dlss-declined.txt" del "%~dp0dlss-declined.txt"
if /i "%~1"=="remove" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-dlss.ps1" -Remove
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-dlss.ps1"
)
pause
