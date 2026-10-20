$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no esta en PATH. Abre una terminal donde funcione flutter doctor.' }
# Crear solo carpetas nativas en un temporal para conservar todo el codigo de Luma.
if (-not (Test-Path '.\android')) {
    $lumaTemp = Join-Path ([System.IO.Path]::GetTempPath()) ('luma_' + [Guid]::NewGuid().ToString('N'))
    & flutter create --project-name luma_study --org com.lumastudy --platforms android,ios,windows --no-pub $lumaTemp
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el proyecto nativo.' }
    foreach ($name in @('android', 'ios', 'windows', '.metadata')) {
        $source = Join-Path $lumaTemp $name
        if (Test-Path $source) { Copy-Item $source -Destination $PSScriptRoot -Recurse -Force }
    }
    Remove-Item $lumaTemp -Recurse -Force
    $manifest = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
    $text = [System.IO.File]::ReadAllText($manifest).Replace('android:label="luma_study"','android:label="Luma Study"')
    [System.IO.File]::WriteAllText($manifest, $text)
}
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron resolver las dependencias. Revisa la conexion a internet.' }
& dart format lib test
if ($LASTEXITCODE -ne 0) { throw 'Se detecto un error de sintaxis.' }
& flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'La revision detecto problemas. Comparte la salida completa.' }
& flutter test
if ($LASTEXITCODE -ne 0) { throw 'Alguna prueba fallo. Comparte la salida completa.' }
Write-Host 'Listo. Ejecuta flutter devices y despues flutter run -d ID_DE_TU_TELEFONO' -ForegroundColor Green
