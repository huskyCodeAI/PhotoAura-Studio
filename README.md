# DocumentaciÃ³n Maestra: PhotoAura Studio (GIMP + PhotoGIMP Rebranded)

Este documento contiene la guÃ­a tÃ©cnica completa, la arquitectura del proyecto, el cÃ³digo fuente del lanzador independiente y las plantillas oficiales de publicaciÃ³n en la Microsoft Store para **PhotoAura Studio**. Todo el contenido ha sido adaptado y verificado para cumplir plenamente con la licencia pÃºblica **GNU GPLv3** y las estrictas directrices de marcas registradas de Microsoft.

---

## 1. Contexto Legal y Viabilidad Comercial

### Legalidad bajo la Licencia GPLv3
GIMP y la distribuciÃ³n de PhotoGIMP estÃ¡n protegidas bajo la licencia pÃºblica **GNU GPLv3**. Bajo estos tÃ©rminos:
* **Venta Comercial Autorizada:** Es 100% legal empaquetar y vender este software en la Microsoft Store.
* **Transparencia de CÃ³digo:** Se debe proporcionar acceso al cÃ³digo fuente de nuestro lanzador, scripts y manifiestos de empaquetado bajo la misma licencia GPLv3. Esto se cumple hospedando de forma pÃºblica los scripts y cÃ³digo del lanzador en GitHub: [https://github.com/huskyCodeAI/PhotoAura-Studio](https://github.com/huskyCodeAI/PhotoAura-Studio).
* **Valor AÃ±adido:** Aunque los usuarios podrÃ­an descargar GIMP de forma gratuita, pagan en la tienda por la comodidad del empaquetado optimizado, atajos preinstalados, instalaciÃ³n rÃ¡pida con un clic, actualizaciones automÃ¡ticas en segundo plano y soporte tÃ©cnico en Windows.

### Directrices de Marcas de Microsoft Store (SanitizaciÃ³n)
* **Rebranding Obligatorio:** Para evitar el rechazo por uso indebido de marcas de terceros, el tÃ­tulo oficial de la aplicaciÃ³n y sus recursos grÃ¡ficos de marca se han cambiado a **PhotoAura Studio**.
* **Cumplimiento de Marcas Registradas:** Se han eliminado por completo referencias a otras suites de software de terceros (como "Photoshop" o "Adobe") dentro de las descripciones del producto y metadatos del instalador, sustituyÃ©ndolos por tÃ©rminos genÃ©ricos pero altamente profesionales como *"Atajos estÃ¡ndar de la industria"* y *"Comandos universales de diseÃ±o"*.
* **MenciÃ³n Obligatoria del Motor de CÃ³digo Abierto:** Por transparencia legal y cumplimiento de las directrices de Microsoft, se indica explÃ­citamente en la descripciÃ³n que el software estÃ¡ basado en el motor de GIMP.

---

## 2. Arquitectura de Carpetas del Proyecto

El proyecto estÃ¡ estructurado de manera modular y limpia para facilitar el mantenimiento y automatizaciÃ³n del empaquetado:

```text
c:\photo\
â”œâ”€â”€ README.md                      <-- Este documento de documentaciÃ³n maestra
â”œâ”€â”€ ROADMAP.md                     <-- Seguimiento de fases del ciclo de vida
â”œâ”€â”€ src\
â”‚   â””â”€â”€ Launcher.cs                <-- CÃ³digo fuente C# del lanzador portÃ¡til optimizado
â”œâ”€â”€ assets\
â”‚   â”œâ”€â”€ logo.ico                   <-- Icono oficial de PhotoAura Studio (mÃºltiples escalas)
â”‚   â”œâ”€â”€ logo.png                   <-- Logo de alta resoluciÃ³n para la tienda y banners
â”‚   â””â”€â”€ splash.png                 <-- Pantalla de carga Deep Velvet Violet
â”œâ”€â”€ scripts\
â”‚   â”œâ”€â”€ setup_workspace.ps1        <-- Descarga inicial e instalaciÃ³n aislada de GIMP
â”‚   â”œâ”€â”€ apply_branding.ps1         <-- Script maestro de rebranding estÃ©tico y funcional
â”‚   â”œâ”€â”€ rebrand_translations.py    <-- Script Python de parcheo de binarios locales (.mo)
â”‚   â””â”€â”€ shift_hue.py               <-- Utilidad de procesamiento de tono violeta para iconos
â”œâ”€â”€ packaging\
â”‚   â”œâ”€â”€ build_and_sign_msix.ps1    <-- Pipeline de empaquetado automatizado MSIX
â”‚   â”œâ”€â”€ PhotoAuraStudio.msix       <-- Instalador final firmado listo para la tienda
â”‚   â”œâ”€â”€ PhotoAuraStudio_TestCert.cer <-- Certificado digital pÃºblico de desarrollo
â”‚   â””â”€â”€ PhotoAuraStudio_TestCert.pfx <-- Clave privada de firma local
â”œâ”€â”€ docs\
â”‚   â””â”€â”€ aprendizajes_empaquetado.md <-- BitÃ¡cora tÃ©cnica y resoluciÃ³n de fallos (twain.exe, etc.)
â””â”€â”€ PrivacyPolicies\
    â””â”€â”€ photoaurastudio\
        â””â”€â”€ index.html             <-- PolÃ­tica de Privacidad oficial para la Microsoft Store
```

---

## 3. CÃ³digo Fuente del Lanzador Optimizado (C#)

Este ejecutable silencioso (`Lanzador.exe`) se encarga de aislar por completo el perfil de configuraciÃ³n de GIMP dentro de la carpeta local de la aplicaciÃ³n, haciÃ©ndolo 100% portable e independiente. AdemÃ¡s, inyecta dinÃ¡micamente las rutas de bibliotecas en la variable de entorno `PATH` para evitar fallos de carga DLL bajo el sandbox de Windows MSIX.

UbicaciÃ³n del archivo: `c:\photo\src\Launcher.cs`

```csharp
using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("PhotoAura Studio")]
[assembly: AssemblyDescription("Lanzador Independiente para PhotoAura Studio")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("PhotoAura Studio")]
[assembly: AssemblyProduct("PhotoAura Studio")]
[assembly: AssemblyCopyright("Copyright Â© 2026 PhotoAura Studio")]
[assembly: AssemblyTrademark("PhotoAura Studio")]
[assembly: AssemblyCulture("")]
[assembly: ComVisible(false)]
[assembly: Guid("d3b07384-ad3b-4c2c-8cb4-3e9a4d2f099c")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace BrandedGimpLauncher
{
    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // 1. Obtener la ruta base donde se ejecuta este Lanzador
                string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;

                // 2. Definir la ruta del perfil interno autocompletado con PhotoGIMP
                string profileDirectory = Path.Combine(baseDirectory, "app", "perfil_photogimp");

                // Crear el directorio de perfil si no existe para evitar fallos de inicio
                if (!Directory.Exists(profileDirectory))
                {
                    Directory.CreateDirectory(profileDirectory);
                }

                // 3. Establecer las variables de entorno para que GIMP trabaje en modo portable e independiente
                Environment.SetEnvironmentVariable("GIMP2_DIRECTORY", profileDirectory);
                Environment.SetEnvironmentVariable("GIMP3_DIRECTORY", profileDirectory);

                // 4. Buscar el ejecutable de GIMP dentro de nuestro paquete
                string gimpExePath = Path.Combine(baseDirectory, "app", "bin", "gimp-2.10.exe");
                
                // Intentar buscar 'gimp.exe' si 'gimp-2.10.exe' no existe (por compatibilidad)
                if (!File.Exists(gimpExePath))
                {
                    gimpExePath = Path.Combine(baseDirectory, "app", "bin", "gimp.exe");
                }

                string binDirectory = Path.GetDirectoryName(gimpExePath);
                
                // 4.5. Inyectar el directorio bin en la variable PATH para el entorno de MSIX
                string currentPath = Environment.GetEnvironmentVariable("PATH") ?? "";
                Environment.SetEnvironmentVariable("PATH", binDirectory + ";" + currentPath);

                // Si no se encuentra GIMP, notificar al usuario de forma amigable
                if (!File.Exists(gimpExePath))
                {
                    MessageBox.Show(
                        "Error al iniciar el editor de fotos:\nNo se pudo encontrar el motor grÃ¡fico interno en la ruta esperada:\n\n" + gimpExePath + "\n\nPor favor, verifica que la carpeta 'app' contenga una instalaciÃ³n vÃ¡lida de GIMP.",
                        "Error de Inicio",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }

                // 5. Preparar los argumentos para iniciar GIMP.
                // Si el usuario arrastrÃ³ un archivo al Lanzador, se lo pasamos a GIMP.
                string arguments = "";
                if (args.Length > 0)
                {
                    // Unir y escapar los argumentos de ruta de archivo
                    for (int i = 0; i < args.Length; i++)
                    {
                        arguments += "\"" + args[i] + "\" ";
                    }
                    arguments = arguments.TrimEnd();
                }

                // 6. Iniciar GIMP de manera transparente
                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = gimpExePath;
                startInfo.Arguments = arguments;
                startInfo.WorkingDirectory = Path.GetDirectoryName(gimpExePath);
                startInfo.UseShellExecute = false;

                using (Process gimpProcess = Process.Start(startInfo))
                {
                    // El lanzador finaliza y deja que el motor de GIMP corra de forma independiente
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "OcurriÃ³ un error inesperado al intentar iniciar el editor:\n\n" + ex.Message,
                    "Error CrÃ­tico",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
        }
    }
}
```

---

## 4. Script de PreparaciÃ³n Inicial del Workspace (`scripts/setup_workspace.ps1`)

Este script descarga el instalador oficial de GIMP y el perfil optimizado de PhotoGIMP de forma segura, y los extrae en el subdirectorio aislado `build\app\`.

UbicaciÃ³n del archivo: `c:\photo\scripts\setup_workspace.ps1`

---

## 5. Script Maestro de Rebranding (`scripts/apply_branding.ps1`)

Este potente script de automatizaciÃ³n ejecuta de forma secuencial todo el proceso de personalizaciÃ³n estÃ©tica y de seguridad del editor:

1. **InyecciÃ³n de Identidad de Marca:** Reemplaza la pantalla de carga original (`splash.png`) por la pantalla oficial violeta de PhotoAura Studio.
2. **Branding Visual Violeta en Iconos:** Modifica los iconos nativos del sistema GTK aplicando algoritmos de cambio de tono de color para lograr un estilo de marca coherente.
3. **DesactivaciÃ³n de Alertas de ActualizaciÃ³n:** Inyecta en el archivo de configuraciÃ³n `gimprc` local las propiedades `(check-updates no)` para que la aplicaciÃ³n funcione de forma offline y aislada de avisos de actualizaciÃ³n externos.
4. **Parcheo de Traducciones (Gettext):** Llama a un script de Python de forma local que descompila y modifica los archivos binarios de localizaciÃ³n (`gimp20.mo`) para reemplazar las cadenas de texto del tÃ­tulo del editor por la marca registrada **"PhotoAura Studio (based on GIMP)"**.
5. **MitigaciÃ³n de Errores de Arquitectura de Bits (STATUS_INVALID_IMAGE_FORMAT):** Localiza y remueve de forma automÃ¡tica plug-ins de 32 bits problemÃ¡ticos (`twain.exe`) que colisionan con las llamadas a librerÃ­as de 64 bits bajo el entorno virtual de MSIX.

---

## 6. Pipeline de Empaquetado Automatizado MSIX (`packaging/build_and_sign_msix.ps1`)

Una vez preparado y personalizado el espacio de trabajo en `build\`, este script ejecuta de forma automÃ¡tica:
1. **CompilaciÃ³n del Paquete:** Invoca la utilidad oficial `makeappx.exe` de Microsoft Windows SDK para compilar la carpeta `build\` en el contenedor de aplicaciÃ³n empaquetada `PhotoAuraStudio.msix`.
2. **GeneraciÃ³n de Firma Digital:** Crea un certificado digital autofirmado `.pfx` con la informaciÃ³n del editor asociada al Microsoft Partner Center.
3. **Firma del Binario:** Ejecuta `signtool.exe` sobre el archivo `.msix` para inyectarle la firma digital, permitiendo la instalaciÃ³n en cualquier mÃ¡quina de pruebas local o el envÃ­o directo a la plataforma de Microsoft.

---
