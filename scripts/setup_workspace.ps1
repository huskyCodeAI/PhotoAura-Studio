# Script de Preparacion de Entorno para Editor de Fotos de Marca Propia
# Ejecutar en PowerShell como Administrador desde c:\photo

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" # Deshabilita barra de progreso para maxima velocidad de descarga

Write-Output "Iniciando preparacion del proyecto..."

# 1. Crear directorios de trabajo
$BuildDir = "c:\photo\build"
$AppDir = "c:\photo\build\app"
$SrcFile = "c:\photo\src\Launcher.cs"

if (!(Test-Path "c:\photo\src")) { New-Item -ItemType Directory -Path "c:\photo\src" | Out-Null }
if (!(Test-Path $BuildDir)) { New-Item -ItemType Directory -Path $BuildDir | Out-Null }
if (!(Test-Path $AppDir)) { New-Item -ItemType Directory -Path $AppDir | Out-Null }

$WebClient = New-Object System.Net.WebClient
$WebClient.Headers.Add("User-Agent", "Mozilla/5.0")

# 2. Descargar GIMP (Asegurar que el archivo no este incompleto)
$GimpInstallerPath = "c:\photo\gimp_setup.exe"
if (Test-Path $GimpInstallerPath) {
    $GimpSize = (Get-Item $GimpInstallerPath).Length
    if ($GimpSize -lt 150MB) {
        Write-Output "Detectado instalador de GIMP incompleto ($($GimpSize / 1MB) MB). Eliminando para re-descargar..."
        Remove-Item -Force $GimpInstallerPath
    }
}

if (!(Test-Path $GimpInstallerPath)) {
    Write-Output "Descargando instalador de GIMP (aprox. 200MB)..."
    $GimpUrl = "https://download.gimp.org/gimp/v2.10/windows/gimp-2.10.38-setup.exe"
    $WebClient.DownloadFile($GimpUrl, $GimpInstallerPath)
    Write-Output "Descarga de GIMP finalizada."
} else {
    Write-Output "Instalador de GIMP ya descargado y verificado."
}

# 3. Descargar PhotoGIMP (Asegurar que el archivo no este incompleto)
$PhotoGimpZipPath = "c:\photo\photogimp.zip"
if (Test-Path $PhotoGimpZipPath) {
    $PhotoGimpSize = (Get-Item $PhotoGimpZipPath).Length
    if ($PhotoGimpSize -lt 1MB) {
        Write-Output "Detectado zip de PhotoGIMP incompleto. Eliminando para re-descargar..."
        Remove-Item -Force $PhotoGimpZipPath
    }
}

if (!(Test-Path $PhotoGimpZipPath)) {
    Write-Output "Descargando parche de PhotoGIMP..."
    $PhotoGimpUrl = "https://github.com/Diolinux/PhotoGIMP/archive/refs/heads/master.zip"
    $WebClient.DownloadFile($PhotoGimpUrl, $PhotoGimpZipPath)
    Write-Output "Descarga de PhotoGIMP finalizada."
} else {
    Write-Output "Parche de PhotoGIMP ya descargado."
}

# 4. Extraer / Instalar silenciosamente GIMP en la carpeta build\app
Write-Output "Extrayendo motor de GIMP silenciosamente en build\app..."
# Flag /DIR=... especifica donde instalar de forma aislada
Start-Process -FilePath $GimpInstallerPath -ArgumentList "/VERYSILENT", "/NORESTART", "/ALLUSERS", "/SUPPRESSMSGBOXES", "/DIR=`"$AppDir`"" -Wait

# 5. Extraer y colocar PhotoGIMP en build\app\perfil_photogimp
Write-Output "Configurando perfil de PhotoGIMP..."
$TempExtract = "c:\photo\temp_photogimp"
if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
Expand-Archive -Path $PhotoGimpZipPath -DestinationPath $TempExtract

# Mapear los archivos de PhotoGIMP al directorio de perfil local de nuestra app
# PhotoGIMP master tiene la ruta .config/GIMP/3.0/ en su repositorio actualizado
$ConfigOrigPath = Join-Path $TempExtract "PhotoGIMP-master\.config\GIMP\3.0"
$DestProfilePath = Join-Path $AppDir "perfil_photogimp"

if (Test-Path $DestProfilePath) { Remove-Item -Recurse -Force $DestProfilePath }
Copy-Item -Path $ConfigOrigPath -Destination $DestProfilePath -Recurse -Force

# Limpiar los splashes por defecto del perfil de PhotoGIMP y reemplazar con nuestro splash de marca
$ProfileSplashDir = Join-Path $DestProfilePath "splashes"
$AssetsSplash = "c:\photo\assets\splash.png"
if (Test-Path $ProfileSplashDir) {
    Remove-Item -Path (Join-Path $ProfileSplashDir "*") -Force -ErrorAction SilentlyContinue
    if (Test-Path $AssetsSplash) {
        Copy-Item -Path $AssetsSplash -Destination (Join-Path $ProfileSplashDir "gimp-splash.png") -Force
    }
}

# Desactivar la comprobacion de actualizaciones para evitar notificaciones de gimp.org
Write-Output "Desactivando comprobacion de actualizaciones en gimprc..."
Add-Content -Path (Join-Path $DestProfilePath "gimprc") -Value "`n(check-updates no)"

# Desactivar el logo de Wilber en la caja de herramientas
Write-Output "Desactivando logo de Wilber en la caja de herramientas..."
Add-Content -Path (Join-Path $DestProfilePath "gimprc") -Value "`n(toolbox-wilber no)"

# Personalizar el titulo de la ventana principal de edicion para mostrar nuestra marca
Write-Output "Personalizando titulo de ventana en gimprc..."
Add-Content -Path (Join-Path $DestProfilePath "gimprc") -Value "`n(image-title-format `"%D*%f-%p.%i (%t, %o, %L) %wx%h - PhotoAura Studio`")"

# Limpiar extraccion temporal
Remove-Item -Recurse -Force $TempExtract

# 6. Compilar el Lanzador en C#
Write-Output "Compilando lanzador C# (Lanzador.exe)..."
$CscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$IcoPath = "c:\photo\assets\logo.ico"
if (Test-Path $CscPath) {
    # Compilar como Windows Application (/target:winexe) para ocultar consola y añadir referencia a Windows Forms
    if (Test-Path $IcoPath) {
        & $CscPath /platform:x64 /target:winexe /win32icon:$IcoPath /out:"$BuildDir\Lanzador.exe" /r:System.Windows.Forms.dll,System.dll,System.Drawing.dll $SrcFile
    } else {
        & $CscPath /platform:x64 /target:winexe /out:"$BuildDir\Lanzador.exe" /r:System.Windows.Forms.dll,System.dll,System.Drawing.dll $SrcFile
    }
    Write-Output "Compilacion exitosa! Ejecutable creado en $BuildDir\Lanzador.exe"
} else {
    Write-Warning "No se encontro el compilador csc.exe de .NET Framework por defecto en tu maquina."
}

# 7. Aplicar Rebranding de Traducciones y Logos Internos
Write-Output "Aplicando rebranding en archivos de lenguaje y logos internos..."
$PythonScript = "c:\photo\scripts\rebrand_translations.py"
if (Test-Path $PythonScript) {
    & python $PythonScript
}

$LogoPng = "c:\photo\assets\logo.png"
$InternalImagesDir = Join-Path $AppDir "share\gimp\2.0\images"
if (Test-Path $LogoPng) {
    if (Test-Path $InternalImagesDir) {
        Copy-Item -Path $LogoPng -Destination (Join-Path $InternalImagesDir "gimp-logo.png") -Force
        Copy-Item -Path $LogoPng -Destination (Join-Path $InternalImagesDir "wilber.png") -Force
        Write-Output "Logos internos rebrandeados con exito."
    }
}

Write-Output "--------------------------------------------------------"
Write-Output "Configuracion completa!"
Write-Output "La carpeta '$BuildDir' contiene tu aplicacion de marca propia."
Write-Output "--------------------------------------------------------"
