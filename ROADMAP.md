# ROADMAP: PhotoAura Studio (based on GIMP)

This document outlines the development roadmap, current progress, and next steps for the production and publication of PhotoAura Studio on the Microsoft Store.

---

## Technical Concept
PhotoAura Studio is a professional, standalone, and portable image editing suite for Windows based on the GIMP engine and pre-configured with a streamlined UI layout. It runs in isolated user space without altering any existing GIMP configurations on the user's computer.

---

## Phase 1: Branding and User Experience (Completed)

- [x] **Silent Windows Launcher Compilation**
  - Compiled custom lightweight C# executable (`Lanzador.exe`) that isolates GIMP's profile directories to the application's local folders.
  - Custom branded high-resolution Windows icon embedded directly inside `Lanzador.exe` using native compiler assets.
  - Created automatic Windows Shortcuts (`PhotoAura Studio.lnk`) in the project directory and on the user's Desktop with the custom premium icon explicitly linked.

- [x] **Deep Velvet Violet Theme**
  - Integrated custom Deep Velvet Violet styling (`#120a1f` base background) to replace GIMP's default gray interfaces.
  - Fully rebranded GIMP's default "Dark" theme internally as Deep Velvet Violet, ensuring it loads automatically.
  - Added CSS rule overrides to camouflage Wilber silhouette assets inside canvas rendering widgets.

- [x] **High-Resolution Premium Brand Icons**
  - Generated a breathtaking, modern, and professional glassmorphic app icon (`logo.png`/`logo.ico`) with multiple Windows-compatible resolutions.
  - Deep-rebranded GIMP's icon theme to load our gorgeous new brand logo natively in all scales and vectors (using base64-encoded SVG injections). GIMP's window icon, taskbar shortcut, toolbox header, and about screens now show the brand new logo natively instead of the default mascot.

- [x] **Clean Canvas Workspace (Wilber Masquerade)**
  - Fully rebranded GIMP's internal files and hidden default assets to provide a beautiful, clean, and modern editing space.

- [x] **GIMP Mascot Wilber Hidden from Tools**
  - Injected configuration rules (`toolbox-wilber no`) to remove GIMP's branding mascot from the toolbox sidebar.

- [x] **English Window Title Rebranding**
  - Translated GIMP's core localization catalog (`gimp20.mo`) to display `"PhotoAura Studio (based on GIMP)"` as the primary editor window title for English locales, ensuring complete transparency and compliance.

---

## Phase 2: Packaging and MSIX Deployment (Current Phase)

- [ ] **AppX Manifest Definition**
  - Generate the official `AppxManifest.xml` listing launch arguments, capabilities, and file association details for PhotoAura Studio.

- [ ] **Assets Packaging**
  - Create the standard package visual asset grid (Square 44x44, Square 150x150, Wide 310x150, Store Logo) utilizing the custom brand assets.

- [ ] **MSIX Container Build**
  - Compile the compiled `build` workspace folder into a signed, self-contained Windows App Package (`.msix`) using the Microsoft MSIX Packaging Tool or Command Line compiler.

---

## Phase 3: Microsoft Partner Center & Store Release (Upcoming)

- [ ] **Publisher Certification**
  - Sign the `.msix` package with the developer publisher certificate generated from the Microsoft Partner Center.

- [ ] **Store Listing Creation**
  - Prepare store listing copy in English and Spanish, clearly describing the application features and explicitly stating that it is based on the open-source GIMP engine under the GNU GPLv3 license.

- [ ] **Submission & Publication**
  - Upload the signed package to Partner Center, configure pricing model, pass automated app certification, and go live on the store.
