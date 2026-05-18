# Documentacion Maestra: Editor de Fotos Personalizado (GIMP + PhotoGIMP)

Este documento contiene la guia completa, el codigo fuente, la arquitectura tecnica y el plan paso a paso para crear un editor de fotos de marca propia preconfigurado con el diseño de PhotoGIMP y publicarlo en la Microsoft Store para Windows de forma totalmente legal.

---

## 1. Contexto Legal y Viabilidad Comercial

### Legalidad bajo la Licencia GPLv3
GIMP y PhotoGIMP estan bajo la licencia publica **GNU GPLv3**. Esto significa:
* **Venta Comercial Permitida:** Es 100% legal empaquetar este software y cobrar por el en la Microsoft Store.
* **Obligacion de Compartir el Codigo:** Debes proporcionar a tus compradores acceso al codigo fuente de tu instalador, scripts y modificaciones bajo la misma licencia GPLv3 (por ejemplo, mediante un repositorio publico de GitHub).
* **Redistribucion:** Los compradores tienen derecho legal a compartir tu software si asi lo deciden, pero la mayoria de los usuarios de la Microsoft Store pagan por la comodidad de la instalacion con un clic, actualizaciones automaticas y soporte.

### Reglas de Marca Registrada (Microsoft Store)
* **Rebranding Obligatorio:** No puedes usar el nombre oficial "GIMP" ni "PhotoGIMP" como titulo principal de la aplicacion ni usar sus logos oficiales como icono principal, ya que violarias la ley de marcas comerciales.
* **Nombre de Marca Propia:** Debes elegir un nombre nuevo (por ejemplo: *PhotoAura Studio*, *Canvas Creator*, etc.) y mencionar de forma transparente en la descripcion que esta basado en GIMP y PhotoGIMP bajo la licencia GPLv3.

---

## 2. Arquitectura de Carpetas del Proyecto

Para que la aplicacion sea independiente y portable (no altere las instalaciones de GIMP que el usuario ya tenga en su PC), toda la suite se encapsula dentro del directorio local utilizando el modo portable de GIMP.

La estructura final generada sera:

```text
c:\photo\
├── README.md                      <-- Este archivo de documentacion maestra
├── setup_workspace.ps1           <-- Script PowerShell de automatizacion
├── src\
│   └── Launcher.cs               <-- Codigo fuente C# del lanzador portable
└── build\                        <-- Carpeta final para generar el instalador MSIX
    ├── Lanzador.exe              <-- Tu ejecutable con tu icono y marca propia
    └── app\                      <-- Contenedor del motor de GIMP
        ├── bin\
        │   └── gimp-2.10.exe    <-- Ejecutable original de GIMP
        ├── share\
        ├── lib\
        └── perfil_photogimp\        <-- Configuracion y temas de PhotoGIMP
            ├── themes\
            ├── tool-presets\
            ├── menurc
            └── ...
```

---

## 3. Codigo Fuente del Lanzador (C#)

Este codigo compila a un ejecutable silencioso (`Lanzador.exe`). Su funcion es establecer las variables de entorno de perfil y ejecutar GIMP de forma transparente, heredando cualquier ruta de imagen que el usuario arrastre al icono.

Ubicacion del archivo: `c:\photo\src\Launcher.cs`

```csharp
using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;

namespace BrandedGimpLauncher
{
    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
                string profileDirectory = Path.Combine(baseDirectory, "app", "perfil_photogimp");

                if (!Directory.Exists(profileDirectory))
                {
                    Directory.CreateDirectory(profileDirectory);
                }

                // Redireccionar el directorio de configuracion del usuario a nuestra carpeta local
                Environment.SetEnvironmentVariable("GIMP2_DIRECTORY", profileDirectory);
                Environment.SetEnvironmentVariable("GIMP3_DIRECTORY", profileDirectory);

                // Buscar el ejecutable original de GIMP
                string gimpExePath = Path.Combine(baseDirectory, "app", "bin", "gimp-2.10.exe");
                if (!File.Exists(gimpExePath))
                {
                    gimpExePath = Path.Combine(baseDirectory, "app", "bin", "gimp.exe");
                }

                if (!File.Exists(gimpExePath))
                {
                    MessageBox.Show(
                        "Error al iniciar el editor de fotos:\nNo se pudo encontrar el motor grafico interno en la ruta:\n\n" + gimpExePath + "\n\nVerifica que la carpeta 'app' contenga una instalacion valida de GIMP.",
                        "Error de Inicio",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }

                // Forwarding de argumentos de archivo (drag & drop de imagenes)
                string arguments = "";
                if (args.Length > 0)
                {
                    for (int i = 0; i < args.Length; i++)
                    {
                        arguments += "\"" + args[i] + "\" ";
                    }
                    arguments = arguments.TrimEnd();
                }

                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = gimpExePath;
                startInfo.Arguments = arguments;
                startInfo.WorkingDirectory = Path.GetDirectoryName(gimpExePath);
                startInfo.UseShellExecute = false;

                using (Process gimpProcess = Process.Start(startInfo))
                {
                    // El lanzador finaliza inmediatamente y deja correr a GIMP
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Ocurrio un error inesperado al intentar iniciar el editor:\n\n" + ex.Message,
                    "Error Critico",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
        }
    }
}
```

---

## 4. Script de Automatizacion (`setup_workspace.ps1`)

Este script en PowerShell automatiza todo el proceso de descarga, extraccion, fusion de archivos y compilacion en tu propia maquina de desarrollo.

Ubicacion del archivo: `c:\photo\setup_workspace.ps1`

```powershell
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
        & $CscPath /target:winexe /win32icon:$IcoPath /out:"$BuildDir\Lanzador.exe" /r:System.Windows.Forms.dll,System.dll,System.Drawing.dll $SrcFile
    } else {
        & $CscPath /target:winexe /out:"$BuildDir\Lanzador.exe" /r:System.Windows.Forms.dll,System.dll,System.Drawing.dll $SrcFile
    }
    Write-Output "Compilacion exitosa! Ejecutable creado en $BuildDir\Lanzador.exe"
} else {
    Write-Warning "No se encontro el compilador csc.exe de .NET Framework por defecto en tu maquina."
}

Write-Output "--------------------------------------------------------"
Write-Output "Configuracion completa!"
Write-Output "La carpeta '$BuildDir' contiene tu aplicacion de marca propia."
Write-Output "--------------------------------------------------------"
```

---

## 5. Personalizacion de Marca (Rebranding)

Para cambiar totalmente la apariencia y hacerla lucir como tu propia aplicacion comercial:

### Reemplazar la Pantalla de Carga (Splash Screen)
1. Diseña una imagen `.png` en formato horizontal (por ejemplo de `800x480` pixeles) con tu logotipo y nombre de marca.
2. Reemplaza el archivo original en la ruta:
   `c:\photo\build\app\share\gimp\2.0\images\gimp-splash.png`
   por tu diseño (conservando exactamente el nombre `gimp-splash.png`).

### Reemplazar Icono del Ejecutable
Para cambiar el icono de `Lanzador.exe`, puedes indicarle al compilador `csc.exe` que le asocie un archivo de icono `.ico` añadiendo el parametro `/win32icon:ruta\tu_icono.ico` durante la compilacion.

### Modificar textos de GIMP ("GIMP" -> "TuMarca") sin recompilar
Para cambiar el nombre que aparece en la barra de titulo y en los menus:
1. Instala una herramienta como **Poedit** o el comando de Gettext `msgunfmt`.
2. Ubica el archivo de idioma en español:
   `c:\photo\build\app\share\locale\es\LC_MESSAGES\gimp20.mo`
3. Descompila el archivo `.mo` a `.po` (texto plano):
   `msgunfmt.exe gimp20.mo -o gimp20.po`
4. Abre `gimp20.po` en un editor de texto y busca la palabra `"GIMP"` o `"Programa de Manipulación de Imágenes de GNU"`. Reemplazalas por tu nombre de marca.
5. Vuelve a compilar el archivo a formato binario `.mo`:
   `msgfmt.exe gimp20.po -o gimp20.mo`
6. Reemplaza el archivo original por tu version parcheada.

### Desactivar la Alerta de Actualizacion ("¡Actualizacion disponible!")
Para evitar que tus usuarios sean invitados a descargar e instalar la version gratuita oficial de GIMP en su PC (lo que arruinaria la experiencia de tu marca), el script de preparacion añade automaticamente la directiva `(check-updates no)` al archivo de configuracion `gimprc` del perfil local. Esto deshabilita por completo las comprobaciones de actualizacion en red y oculta el recuadro negro de alertas.

### Manejo del Dialogo "Acerca de GIMP" (Mascota Wilber y Creditos)
El dialogo oficial de informacion ("Acerca de...") que muestra la mascota Wilber y los creditos originales (Spencer Kimball, Peter Mattis, etc.) es un recurso interno y no debe modificarse:
* **Cumplimiento Obligatorio de Licencia (GPLv3 Seccion 7):** La licencia GPLv3 exige expresamente conservar intactos todos los avisos de derechos de autor, licencias y creditos que se muestren de cara al usuario final (las llamadas "Appropriate Legal Notices").
* **Tu Escudo Legal Definitivo:** Mantener esta ventana de creditos visible demuestra transparencia. Al declarar abiertamente que tu aplicacion utiliza y apoya el motor GIMP bajo GPLv3, te blindas juridicamente contra cualquier reclamacion de plagio o mal uso de marcas de terceros.

---

## 6. Creacion del Instalador MSIX y Publicacion

Para poder subir tu aplicacion a la **Microsoft Store**, debes empaquetarla en formato MSIX:

1. **Descargar MSIX Packaging Tool:** Instala la aplicacion oficial *MSIX Packaging Tool* de Microsoft desde la Microsoft Store de forma gratuita.
2. **Crear Paquete desde Carpeta Existente:**
   * Abre la herramienta y selecciona "Application Package".
   * Selecciona como directorio de origen de la aplicacion la carpeta `c:\photo\build\`.
   * Indica que el archivo ejecutable principal (Entry Point) es `Lanzador.exe`.
3. **Definir Identidad del Paquete:**
   * Completa los campos con la informacion del **Microsoft Partner Center** (Nombre del paquete, Publisher ID, version, etc.).
4. **Firmar el paquete:** Genera y asocia un certificado digital de pruebas para probar la instalacion local, o firma con la clave proporcionada por Microsoft.
5. **Subir al Partner Center:** Ingresa a tu cuenta de desarrollador de Microsoft, crea una nueva ficha de aplicacion, sube tu archivo `.msix` generado y envialo a revision para su publicacion.
