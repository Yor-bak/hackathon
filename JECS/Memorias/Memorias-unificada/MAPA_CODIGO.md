# Mapa del código · Memorias

Rutas relativas a `Memorias/` (dentro de `Memorias-unificada/`). Los números de línea son aproximados y pueden moverse.

## ¿Dónde está…? (búsqueda rápida)

| Quiero encontrar… | Archivo | Qué buscar |
|---|---|---|
| El punto de entrada y las 3 pestañas | `MemoriasApp.swift` | `MemoriasApp`, `TabView` |
| La barra inferior de Carmen (Mi día / Mi familia / Mis recuerdos) | `MemoriasApp.swift` | `MainTabBar`, `RootView` |
| «Estoy perdido» | `MemoriasApp.swift` | `LostScreen` |
| Perfil de Carmen | `MemoriasApp.swift` | `ProfileScreen` |
| El aviso «Deshacer» de Carmen | `MemoriasApp.swift` / `AppState.swift` | `ToastBar`, `Toast` |
| «Mi día» (camino de círculos) | `HomeView.swift` | `HomeView`, `DayNode` |
| El calendario de Carmen | `CalendarView.swift` | `MonthCalendarView` |
| El **libro 3D** (giro de páginas, portada) | `Libro/LibroPhotoBookView.swift` | `PhotoBookView`, `PageFace`, `BookPage` |
| **Las fotos y recuerdos de ejemplo** del libro | `Libro/LibroView.swift` | arreglo `memories`, función `memory(...)` |
| El orden por fecha del libro | `Libro/LibroView.swift` | `bookPages`, `sorted` |
| Los filtros por década | `Libro/LibroView.swift` | `filterBar` |
| El botón «+» para agregar foto | `Libro/LibroAddMemoryView.swift` y `Libro/LibroPhotoSource.swift` | `LibroAddMemoryView`, `PhotoAddButton`, `CameraPicker` |
| La pantalla de detalle de un recuerdo | `Libro/LibroMemoryDetailView.swift` | `MemoryDetailView` |
| Tocar una cara → biografía en el árbol | `Libro/LibroMemoryDetailView.swift` | `openInTree`, `PersonLink` |
| Las preguntas de Memo y la historia que arma | `Libro/LibroMemoryDetailView.swift` | `ScriptedInterviewer`, `ScriptedStoryWriter` |
| Detección de caras y personas | `Libro/LibroPersonDetector.swift` | `PersonDetector` |
| La voz (hablar y escuchar) | `Libro/LibroVoiceServices.swift` | `VoiceOutput`, `VoiceInput` |
| El árbol genealógico | `Familia/FamilyTreeView.swift` | `FamilyTreeView`, `drawLeaves` |
| La ficha de una persona (bio, foto, editar) | `Familia/FamilyTreeView.swift` | `FamilyDetailView` |
| Agregar persona al árbol | `Familia/FamilyTreeView.swift` | `FamilyAddView` |
| Los datos del árbol y su guardado | `Familia/FamilyStore.swift` | `FamilyStore.shared`, semilla, `familia3.json` |
| Memo (el elefante) | `Mascot.swift` | `Mascot`, `MascotSays` |
| **El Cuidador: raíz y pestañas** | `Cuidador/CuidadorRoot.swift` | `CuidadorRootView`, `CuidadorTabs` |
| Cuidador · Inicio (mapa, signos vitales) | `Cuidador/CuidadorInicioView.swift` | `InicioView`, `MapCard`, `VitalsCard` |
| Cuidador · Calendario | `Cuidador/CuidadorCalendarioView.swift` | `CalendarioView` |
| Cuidador · Alertas | `Cuidador/CuidadorAlertasView.swift` | `AlertasView` |
| Cuidador · Recuerdos | `Cuidador/CuidadorRecuerdosView.swift` | `CuidadorRecuerdosView` |
| Cuidador · agregar pastilla o evento | `Cuidador/CuidadorAgregarPastillaView.swift` | `AgregarPastillaView`, `AgregarEventoView` |
| Cuidador · agregar persona | `Cuidador/CuidadorAgregarPersonaView.swift` | `AgregarPersonaView`, `FacePhoto` |
| Cuidador · agregar recuerdo | `Cuidador/CuidadorAgregarRecuerdoView.swift` | `AgregarRecuerdoView` |
| Cuidador · perfil | `Cuidador/CuidadorPerfilView.swift` | `PerfilView` |
| Cuidador · Memo | `Cuidador/CuidadorMemoView.swift` | `MemoView` |
| La barra de medallones del Cuidador | `Cuidador/CuidadorComponents.swift` | `MedallionTabBar`, `TabMedallion` |
| Datos de ejemplo y estado del Cuidador | `Cuidador/CuidadorModel.swift` | `SampleData`, `AppStore` |
| **El Reloj** (Apple Watch) | `Reloj/RelojView.swift` | `RelojView`, `RelojScreen`, `WatchPhase` |

## Por carpeta

### Raíz de `Memorias/` (app de Carmen)
| Archivo | Líneas | Contenido |
|---|---|---|
| `MemoriasApp.swift` | ~230 | `@main`, las 3 pestañas, barra inferior de Carmen, Estoy perdido, Perfil, avisos |
| `HomeView.swift` | ~360 | «Mi día»: camino, nodos (`NodeKind`), sesiones |
| `CalendarView.swift` | ~200 | Calendario mensual de Carmen |
| `AppState.swift` | ~110 | Estado global de Carmen: `AppState`, secciones (`MainSection`), pantallas (`Screen`), `Toast`, `Fmt` |
| `Model.swift` | ~110 | Modelos de Carmen: `Memory`, `CalEvent`, `Session`, datos de ejemplo `Sample` |
| `Theme.swift` | ~175 | Colores `Pal`, `Hand`, botones `BigButton`/`OutlinePill`/`FilledPill`, `Speaker`, `PaperBackground` |
| `Mascot.swift` | ~70 | Memo (imagen `memo.png` con animación) |
| `Skin.swift` | ~300 | **Código viejo** de estilos que ya no se pueden elegir |
| `Sketch.swift` | ~340 | **Código viejo** de dibujo a mano (también define íconos de eventos) |

### `Libro/` (Mis recuerdos)
| Archivo | Líneas | Contenido |
|---|---|---|
| `LibroView.swift` | ~200 | Pantalla del libro, filtros, datos de ejemplo, `UIImage.bundled` |
| `LibroPhotoBookView.swift` | ~390 | Libro 3D, `BookPage`, `FaceTag`, `MemoryStory`, `ChatMessage` |
| `LibroMemoryDetailView.swift` | ~650 | Detalle del recuerdo, caras, narración, entrevista de Memo (el archivo más grande) |
| `LibroAddMemoryView.swift` | ~115 | Hoja para agregar un recuerdo |
| `LibroPhotoSource.swift` | ~85 | Galería, cámara, reducción de tamaño de imagen |
| `LibroPersonDetector.swift` | ~65 | Vision: caras y personas |
| `LibroVoiceServices.swift` | ~180 | Voz de salida y de entrada |
| `LibroTheme.swift` | ~30 | `MemoryTheme` y `ChunkyPress` |

### `Familia/`
| Archivo | Líneas | Contenido |
|---|---|---|
| `FamilyStore.swift` | ~150 | Modelos `FamilyMember`, `FamilyLink`, `FamilyConnection`; almacén compartido y guardado en JSON |
| `FamilyTreeView.swift` | ~430 | Árbol, nodos, ficha, alta de personas |

### `Cuidador/`
| Archivo | Líneas | Contenido |
|---|---|---|
| `CuidadorRoot.swift` | ~70 | Entrada, `TabView` oculto, apariencia global |
| `CuidadorModel.swift` | ~360 | `AppStore`, modelos (`Person`, `Medication`, `CareEvent`, `CareAlert`, `Album`, `Relative`, `MemoryRecord`), `SampleData` |
| `CuidadorComponents.swift` | ~475 | Botones, chips, pestañas, barra de medallones, banner «Deshacer», `FlowLayout` |
| `CuidadorTheme.swift` | ~90 | Colores `Theme`, fuentes, rangos de texto |
| Vistas | 40–250 cada una | Inicio, Calendario, Alertas, Recuerdos, Perfil, Memo y las 3 pantallas de alta |

### `Reloj/`
`RelojView.swift` (~200): el reloj y sus 3 páginas. Solo interfaz, con números fijos.

### Recursos (en `Memorias/`)
`memo.png`, `arbol.png`, `pescador.jpg`, `pesca-1.jpg` a `pesca-4.jpg`.

## Cosas que confunden (hay duplicados)
Carmen y el Cuidador vienen de dos proyectos distintos y conservan nombres paralelos:

| Concepto | Versión de Carmen | Versión del Cuidador | Versión del libro |
|---|---|---|---|
| Colores | `Pal` (`Theme.swift`) | `Theme` (`CuidadorTheme.swift`) | `MemoryTheme` (`LibroTheme.swift`) |
| Botón «gordo» | `BigButton` | `ChunkyButtonStyle`, `Chunky` | `ChunkyPress` |
| Voz de salida | `Speaker` | `CuidadorSpeaker` | `VoiceOutput` |
| Estado | `AppState` | `AppStore` | — |
| Datos de ejemplo | `Sample` | `SampleData` | arreglo `memories` en `LibroView` |
| Recuerdo | `Memory` | `MemoryRecord` | `BookPage` |
| Evento | `CalEvent` | `CareEvent` | — |

**Lo único realmente compartido** entre las tres pestañas es `FamilyStore.shared` (el árbol). Por eso lo que Ana agrega en eventos no llega a Carmen.

## Archivos para limpiar en el futuro
`Skin.swift`, `Sketch.swift` y partes de `Theme.swift` (`BigButton`, `OutlinePill`, `FilledPill`, `PaperBackground`) son de estilos anteriores. Antes de borrarlos, comprobar con una búsqueda que ninguna vista los use.

## Otras carpetas del repo
- `tools/`: `make_paper.py` y `make_skins.py` (texturas de los estilos viejos).
- `video/`, `originales/`: material de video y proyectos de origen.
- `build.sh`: compilar para el simulador.
- Documentos: `PRODUCT.md`, `DESIGN.md`, `GUION_VIDEO_5MIN.md`, `SPEECH_5MIN.md`, `CONTEXTO_EQUIPO.md` (desactualizado).
