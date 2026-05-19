# ROADMAP: PhotoAura Studio (based on GIMP)

Este documento describe el mapa de ruta del desarrollo, el progreso actual y los hitos alcanzados en el empaquetado, rebranding y publicación de **PhotoAura Studio** en la Microsoft Store para Windows.

---

## Concepto Técnico
PhotoAura Studio es una suite de edición fotográfica profesional, independiente y portable para Windows basada en el motor de código abierto de GIMP y el perfil preconfigurado de PhotoGIMP. Se ejecuta en un espacio de usuario aislado sin alterar ninguna instalación o perfil preexistente en el sistema operativo del usuario.

---

## Fase 1: Marca y Experiencia de Usuario (Completado)

- [x] **Compilación del Lanzador Silencioso en C#**
  - Compilación de un binario nativo ligero (`Lanzador.exe`) que aísla de forma virtual los directorios del perfil de GIMP a las subcarpetas del paquete de la aplicación.
  - Icono premium de alta resolución incrustado directamente en el ejecutable principal.
  - Creación automática de accesos directos de Windows (`PhotoAura Studio.lnk`) vinculados explícitamente a los activos de la marca.

- [x] **Tema Visual Terciopelo Violeta Profundo (Deep Velvet Violet)**
  - Integración de una paleta estética moderna y elegante (fondo `#120a1f`) para sustituir el clásico gris neutro de GIMP.
  - Personalización a nivel de CSS y archivos `gtkrc` para ocultar la silueta por defecto del lienzo del editor, logrando un espacio de trabajo profesional libre de distracciones.

- [x] **Logotipo e Iconografía Premium**
  - Diseño y generación de un isotipo e icono glassmórfico elegante compatible con múltiples resoluciones de pantalla y sistemas operativos.
  - Parcheo en caliente del motor de iconos vectoriales planos y monocromáticos nativos para cargar el nuevo logo de marca en todos los paneles, barra de tareas e interfaces.

- [x] **Sanitización del Lienzo de Trabajo**
  - Ocultación completa de Wilber (la mascota original de GIMP) en el panel de herramientas (`toolbox-wilber no`), barra de título y pantallas secundarias para una imagen corporativa unificada.

- [x] **Personalización de Título y Textos Locales**
  - Descompilación y edición de los catálogos de localización (`gimp20.mo`) para presentar la marca oficial "PhotoAura Studio (based on GIMP)" de forma transparente y legal.

---

## Fase 2: Empaquetado y Aislamiento MSIX (Completado)

- [x] **Definición del Manifiesto AppX (`AppxManifest.xml`)**
  - Estructuración de las propiedades del contenedor UWP/MSIX (nombre del paquete, Publisher ID, dependencias de Windows SDK y capacidades).
  - Inyección de la política de sobreescritura de directorios de búsqueda de dependencias (`uap6:LoaderSearchPathOverride`) apuntando a la carpeta de binarios (`app\bin`) para resolver la carga dinámica de DLLs en el entorno virtualizado.

- [x] **Empaquetado de Activos Visuales**
  - Diseño del grid de logotipos del sistema (Square 44x44, Square 150x150, Wide 310x150, Store Logo) en escala de grises y color con el logotipo de PhotoAura Studio.

- [x] **Resolución del Error de Arquitectura Híbrida (`0xc00007b`)**
  - Identificación y eliminación del plug-in TWAIN de 32 bits (`twain.exe`) en el directorio de complementos, evitando el choque de bits con librerías nativas de 64 bits dentro del sandbox de MSIX.

- [x] **Pipeline de Compilación Automática (`packaging/build_and_sign_msix.ps1`)**
  - Script automatizado en PowerShell que invoca la herramienta de empaquetado `makeappx.exe` de Microsoft y firma digitalmente el binario final mediante `signtool.exe` con una clave de firma local autorizada `.pfx`.

---

## Fase 3: Publicación y Fichas de Tienda (Completado)

- [x] **Generación y Despliegue de Política de Privacidad**
  - Creación, traducción y maquetación interactiva de la Política de Privacidad de PhotoAura Studio (requisito obligatorio de la tienda).
  - Alojamiento y despliegue público en GitHub Pages: [https://huskycodeai.github.io/PrivacyPolicies/photoaurastudio/](https://huskycodeai.github.io/PrivacyPolicies/photoaurastudio/)

- [x] **Firma Digital con el Certificado de Producción**
  - Vinculación del editor y firma digital definitiva del paquete de distribución MSIX con la identidad asignada en la consola de Microsoft Partner Center.

- [x] **Redacción Saneada de Fichas de la Tienda (Compliance)**
  - Creación de descripciones de producto completas y listas de características (Features) en inglés y español.
  - Sanitización estricta de las fichas para eliminar cualquier referencia a marcas comerciales de competidores (como Photoshop/Adobe) y evitar el rechazo de certificación de la tienda.

- [x] **Subida y Envío a Certificación en el Partner Center**
  - Envío exitoso del binario firmado a los servidores de Microsoft Store. La aplicación ya se encuentra enviada, validada en la consola y lista para su distribución comercial.
