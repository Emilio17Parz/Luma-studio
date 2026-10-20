param([string]$Dispositivo = '')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path '.\android')) { throw 'Ejecuta primero Preparar.ps1.' }
if ($Dispositivo) { & flutter run -d $Dispositivo } else { & flutter run }
if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar. Comparte el error de Flutter.' }
