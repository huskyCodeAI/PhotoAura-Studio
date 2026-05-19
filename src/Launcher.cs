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
[assembly: AssemblyCopyright("Copyright © 2026 PhotoAura Studio")]
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

                // 2. Definir la ruta de origen (empaquetada y de solo lectura) y la de destino (escribible)
                string sourceProfileDir = Path.Combine(baseDirectory, "app", "perfil_photogimp");
                string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string profileDirectory = Path.Combine(localAppData, "PhotoAuraStudio", "perfil_photogimp");

                // Copiar el perfil preconfigurado a una zona con permisos de escritura (AppData) si no existe
                if (!Directory.Exists(profileDirectory))
                {
                    Directory.CreateDirectory(profileDirectory);
                    if (Directory.Exists(sourceProfileDir))
                    {
                        CopyDirectory(sourceProfileDir, profileDirectory);
                    }
                }

                // 3. Establecer las variables de entorno para que GIMP trabaje en modo portable e independiente
                // GIMP2_DIRECTORY es para la version 2.10, GIMP3_DIRECTORY es para futuras versiones 3.0
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
                        "Error al iniciar el editor de fotos:\nNo se pudo encontrar el motor gráfico interno en la ruta esperada:\n\n" + gimpExePath + "\n\nPor favor, verifica que la carpeta 'app' contenga una instalación válida de GIMP.",
                        "Error de Inicio",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }

                // 5. Preparar los argumentos para iniciar GIMP.
                // Si el usuario arrastró un archivo al Lanzador, se lo pasamos a GIMP.
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
                    "Ocurrió un error inesperado al intentar iniciar el editor:\n\n" + ex.Message,
                    "Error Crítico",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
        }

        // Método auxiliar para copiar directorios de forma recursiva
        private static void CopyDirectory(string sourceDir, string destDir)
        {
            DirectoryInfo dir = new DirectoryInfo(sourceDir);
            if (!dir.Exists) return;

            DirectoryInfo[] dirs = dir.GetDirectories();

            // Si el destino no existe, lo creamos
            Directory.CreateDirectory(destDir);

            // Copiar los archivos del directorio actual
            FileInfo[] files = dir.GetFiles();
            foreach (FileInfo file in files)
            {
                string tempPath = Path.Combine(destDir, file.Name);
                file.CopyTo(tempPath, true);
            }

            // Copiar subdirectorios recursivamente
            foreach (DirectoryInfo subdir in dirs)
            {
                string tempPath = Path.Combine(destDir, subdir.Name);
                CopyDirectory(subdir.FullName, tempPath);
            }
        }
    }
}
