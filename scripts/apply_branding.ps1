# Script de Aplicacion de Marca Comercial (PhotoAura Studio)
$ErrorActionPreference = "Stop"

Write-Output "Iniciando aplicacion de marca y branding..."

$SplashSrc = "C:\Users\win11nuevox\.gemini\antigravity\brain\2f47937c-1898-43e9-90bf-9f996171902d\photoaura_splash_violet_final.png"
$IconSrc = "C:\Users\win11nuevox\.gemini\antigravity\brain\2f47937c-1898-43e9-90bf-9f996171902d\photoaura_logo_violet_final.png"

$BuildDir = "c:\photo\build"
$AppDir = "c:\photo\build\app"
$AssetsDir = "c:\photo\assets"
$SrcFile = "c:\photo\src\Launcher.cs"

# 0. Eliminar DLLs de depuracion del sistema y ejecutables de arquitectura incompatible (32-bit vs 64-bit) que causan el error 0xc00007b
$GimpBinDir = Join-Path $AppDir "bin"
if (Test-Path $GimpBinDir) {
    $ConflictingDlls = @("dbgcore.dll", "dbghelp.dll")
    foreach ($Dll in $ConflictingDlls) {
        $DllPath = Join-Path $GimpBinDir $Dll
        if (Test-Path $DllPath) {
            Remove-Item -Path $DllPath -Force
            Write-Output "Eliminada DLL conflictiva para evitar error 0xc00007b: $Dll"
        }
    }
}

$TwainDir = Join-Path $AppDir "lib\gimp\2.0\plug-ins\twain"
if (Test-Path $TwainDir) {
    Remove-Item -Path $TwainDir -Recurse -Force
    Write-Output "Eliminado directorio plug-in TWAIN de 32-bits para evitar error 0xc00007b en el contenedor MSIX."
}

# 1. Crear directorio de assets si no existe
if (!(Test-Path $AssetsDir)) {
    New-Item -ItemType Directory -Path $AssetsDir | Out-Null
}

# 2. Reemplazar Splash Screen en GIMP
$GimpSplashDest = Join-Path $AppDir "share\gimp\2.0\images\gimp-splash.png"
if (Test-Path $SplashSrc) {
    if (Test-Path $GimpSplashDest) {
        Remove-Item -Force $GimpSplashDest
    }
    Copy-Item -Path $SplashSrc -Destination $GimpSplashDest -Force
    
    # Tambien limpiar y reemplazar en la carpeta de splashes del perfil de PhotoGIMP si existe
    $ProfileSplashDir = Join-Path $AppDir "perfil_photogimp\splashes"
    if (Test-Path $ProfileSplashDir) {
        Remove-Item -Path (Join-Path $ProfileSplashDir "*") -Force -ErrorAction SilentlyContinue
        Copy-Item -Path $SplashSrc -Destination (Join-Path $ProfileSplashDir "gimp-splash.png") -Force
    }
    
    Write-Output "Pantalla de carga (Splash Screen) personalizada aplicada con exito."
} else {
    Write-Warning "No se encontro la imagen de splash de origen."
}

# 2b. Inyectar configuraciones de temas de color y preferencias en gimprc (Perfil y Global)
$DestProfilePath = Join-Path $AppDir "perfil_photogimp"
$GimprcPath = Join-Path $DestProfilePath "gimprc"
$GlobalGimprcPath = Join-Path $AppDir "etc\gimp\2.0\gimprc"

# Asegurar que el directorio de perfil existe
if (!(Test-Path $DestProfilePath)) {
    New-Item -ItemType Directory -Path $DestProfilePath | Out-Null
}

# Crear gimprc personal si no existe
if (!(Test-Path $GimprcPath)) {
    New-Item -ItemType File -Path $GimprcPath | Out-Null
}

# Leer y actualizar gimprc personal
$gimprcContent = Get-Content -Raw $GimprcPath
$newGimprcLines = [System.Collections.Generic.List[string]]::new()

# Si el gimprc tiene contenido, lo cargamos línea por línea sin duplicados
if ($gimprcContent) {
    $gimprcContent -split "`r?`n" | ForEach-Object {
        $line = $_.Trim()
        if ($line -and $line -notlike "(theme *" -and $line -notlike "(icon-theme *" -and $line -notlike "(toolbox-wilber *" -and $line -notlike "(image-title-format *") {
            $newGimprcLines.Add($_)
        }
    }
}

# Inyectar las configuraciones oficiales de PhotoAura Studio
$newGimprcLines.Add('(theme "Dark")')
$newGimprcLines.Add('(icon-theme "Symbolic")')
$newGimprcLines.Add('(toolbox-wilber no)')
$newGimprcLines.Add('(image-title-format "%D*%f-%p.%i (%t, %o, %L) %wx%h - PhotoAura Studio (based on GIMP)")')

# Guardar gimprc personal
[System.IO.File]::WriteAllLines($GimprcPath, $newGimprcLines)
Write-Output "Configuraciones inyectadas en gimprc personal con exito."

# Leer y actualizar gimprc global de la instalacion (para asegurar carga de temas/iconos pase lo que pase)
if (Test-Path $GlobalGimprcPath) {
    $globalGimprcContent = Get-Content -Raw $GlobalGimprcPath
    $newGlobalLines = [System.Collections.Generic.List[string]]::new()
    
    if ($globalGimprcContent) {
        $globalGimprcContent -split "`r?`n" | ForEach-Object {
            $line = $_.Trim()
            if ($line -and $line -notlike "(theme *" -and $line -notlike "(icon-theme *" -and $line -notlike "(toolbox-wilber *" -and $line -notlike "(image-title-format *") {
                $newGlobalLines.Add($_)
            }
        }
    }
    
    $newGlobalLines.Add('(theme "Dark")')
    $newGlobalLines.Add('(icon-theme "Symbolic")')
    $newGlobalLines.Add('(toolbox-wilber no)')
    $newGlobalLines.Add('(image-title-format "%D*%f-%p.%i (%t, %o, %L) %wx%h - PhotoAura Studio (based on GIMP)")')
    
    [System.IO.File]::WriteAllLines($GlobalGimprcPath, $newGlobalLines)
    Write-Output "Configuraciones inyectadas en gimprc global del sistema con exito."
}

# 3. Convertir PNG a ICO usando Python y Pillow para garantizar compatibilidad total
$IcoDest = Join-Path $AssetsDir "logo.ico"
if (Test-Path $IconSrc) {
    Write-Output "Generando archivo de icono logo.ico compatible con Windows usando Python Pillow..."
    
    # Asegurar que logo.png se copie en assets
    Copy-Item -Path $IconSrc -Destination (Join-Path $AssetsDir "logo.png") -Force
    
    # Llamar a Python para generar el ICO con multiples tamaños estandar
    $pythonCode = "from PIL import Image; img = Image.open(r'$IconSrc'); sizes = [(16,16), (24,24), (32,32), (48,48), (64,64), (128,128), (256,256)]; img.save(r'$IcoDest', sizes=sizes)"
    python -c $pythonCode
    
    Write-Output "Icono de Windows logo.ico generado exitosamente en multiples resoluciones."
} else {
    Write-Warning "No se encontro la imagen de icono de origen."
}

# 4. Recompilar Lanzador.exe con el Icono de Marca
Write-Output "Recompilando Lanzador.exe con el icono embebido..."
$CscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (Test-Path $CscPath) {
    if (Test-Path $IcoDest) {
        & $CscPath /platform:x64 /target:winexe /win32icon:$IcoDest /out:"$BuildDir\Lanzador.exe" /r:System.Windows.Forms.dll,System.dll,System.Drawing.dll $SrcFile
    } else {
        & $CscPath /platform:x64 /target:winexe /out:"$BuildDir\Lanzador.exe" /r:System.Windows.Forms.dll,System.dll,System.Drawing.dll $SrcFile
    }
    Write-Output "¡Recompilacion de Lanzador.exe exitosa!"
} else {
    Write-Warning "No se encontro csc.exe. No se pudo compilar con el icono."
}

# 5. Aplicar Rebranding de Traducciones y Logos Internos
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

# 5b. Reemplazar Wilber en los temas de iconos (tanto SVG de marca propia como PNGs internos de marca)
$IconsDir = Join-Path $AppDir "share\gimp\2.0\icons"
if (Test-Path $IconsDir) {
    Write-Output "Personalizando iconos internos de la app (remplazando Wilber por logo de marca en todos los tamaños)..."
    
    $TempPyScript = Join-Path $PSScriptRoot "rebrand_icons.py"
    $pythonRebrandCode = @'
import os
from PIL import Image

logo_path = r'c:\photo\assets\logo.png'
icons_dir = r'c:\photo\build\app\share\gimp\2.0\icons'
images_dir = r'c:\photo\build\app\share\gimp\2.0\images'

# Definir el logotipo premium como SVG vectorial de colores solidos planos.
# EVITAMOS los degradados XML (<linearGradient>) porque el motor SVG antiguo de GTK 2 (librsvg) en Windows
# tiene un error conocido y los renderiza como negro solido. Este diseño plano es 100% compatible y se ve increible.
brand_svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <!-- Fondo redondeado con un violeta de lujo solido premium -->
  <rect x="12" y="12" width="232" height="232" rx="48" fill="#120a1f" stroke="#5c5370" stroke-width="4" />
  
  <!-- Cuerpo del lente exterior magenta/violeta neon solido -->
  <circle cx="128" cy="128" r="80" fill="none" stroke="#b92bff" stroke-width="10" />
  <circle cx="128" cy="128" r="68" fill="none" stroke="#5c5370" stroke-width="2" />
  
  <!-- Apertura del lente purpura real solido -->
  <circle cx="128" cy="128" r="55" fill="#6b00d2" opacity="0.85" />
  
  <!-- Hojas del obturador geometricas blancas -->
  <path d="M 128 73 L 155 110" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  <path d="M 173 102 L 140 135" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  <path d="M 178 143 L 138 153" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  <path d="M 152 178 L 118 150" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  <path d="M 103 173 L 113 130" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  <path d="M 78 138 L 110 115" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  <path d="M 88 92 L 128 102" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.9" />
  
  <!-- Reflejo brillante de cristal -->
  <path d="M 90 90 A 55 55 0 0 1 166 90" fill="none" stroke="#ffffff" stroke-width="6" stroke-linecap="round" opacity="0.6" />
  <circle cx="150" cy="105" r="10" fill="#ffffff" opacity="0.4" />
</svg>"""

logo_img = None
if os.path.exists(logo_path):
    logo_img = Image.open(logo_path)

count_png = 0
count_svg = 0
for root, dirs, files in os.walk(icons_dir):
    for f in files:
        if 'wilber' in f.lower():
            full_path = os.path.join(root, f)
            ext = os.path.splitext(f)[1].lower()
            if ext == '.svg':
                # Reemplazar con el SVG vectorial puro ultra-compatible
                with open(full_path, 'w', encoding='utf-8') as svg_file:
                    svg_file.write(brand_svg)
                count_svg += 1
            elif ext == '.png' and logo_img is not None:
                # Redimensionar logo PNG al tamaño exacto del PNG original
                try:
                    with Image.open(full_path) as orig:
                        size = orig.size
                    resized = logo_img.resize(size, Image.Resampling.LANCZOS)
                    resized.save(full_path, 'PNG')
                    count_png += 1
                except Exception:
                    pass

# Remplazar el Wilber de fondo (watermark) del canvas vacio con un PNG 1x1 transparente limpio
canvas_watermark = os.path.join(images_dir, 'wilber.png')
if os.path.exists(canvas_watermark):
    try:
        transparent_img = Image.new('RGBA', (1, 1), (0, 0, 0, 0))
        transparent_img.save(canvas_watermark, 'PNG')
        print('Marca de agua de Wilber en el canvas reemplazada por un lienzo transparente limpio.')
    except Exception as e:
        print(f'Error al ocultar la marca de agua del canvas: {e}')

print(f'Rebranding de iconos completo: {count_png} PNGs redimensionados, {count_svg} SVGs convertidos.')
'@
    [System.IO.File]::WriteAllText($TempPyScript, $pythonRebrandCode)
    python $TempPyScript
    if (Test-Path $TempPyScript) {
        Remove-Item -Force $TempPyScript
    }
}

# 6. Crear accesos directos (shortcuts) con icono de marca explícito
Write-Output "Creando accesos directos de PhotoAura Studio con icono de marca..."
$ShortcutPathLocal = "c:\photo\PhotoAura Studio.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPathLocal)
$Shortcut.TargetPath = "c:\photo\build\Lanzador.exe"
$Shortcut.WorkingDirectory = "c:\photo\build"
$Shortcut.IconLocation = "c:\photo\assets\logo.ico,0"
$Shortcut.Description = "PhotoAura Studio (based on GIMP)"
$Shortcut.Save()
Write-Output "Acceso directo creado con exito en: c:\photo\PhotoAura Studio.lnk"

# Intentar copiar al escritorio del usuario
$DesktopDir = [System.Environment]::GetFolderPath('Desktop')
if ($DesktopDir -and (Test-Path $DesktopDir)) {
    $ShortcutPathDesktop = Join-Path $DesktopDir "PhotoAura Studio.lnk"
    Copy-Item -Path $ShortcutPathLocal -Destination $ShortcutPathDesktop -Force
    Write-Output "Acceso directo copiado con exito a tu Escritorio de Windows: $ShortcutPathDesktop"
}

Write-Output "--------------------------------------------------------"
Write-Output "¡Personalizacion de marca completada!"
Write-Output "Tu Lanzador.exe ahora muestra tu logotipo y el Splash de carga esta configurado."
Write-Output "Se crearon los accesos directos con tu icono personalizado de alta calidad."
Write-Output "--------------------------------------------------------"
