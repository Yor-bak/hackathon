# Memorias · App del cuidador (SwiftUI, iOS 17+)

Mismas 8 pantallas del lienzo de diseño, con datos de ejemplo, y 5 pestañas:
Inicio, Calendario, Alertas, Recuerdos y Familia.

## Cómo meterlo en Xcode
1. En tu proyecto, borra los archivos de la plantilla: `ContentView.swift` y el archivo `...App.swift`
   (el nuestro, `MemoriasCuidadorApp.swift`, ya trae `@main`).
2. Arrastra todos los `.swift` de esta carpeta al navegador de Xcode.
   Marca "Copy items if needed" y tu target.
3. En Deployment Target pon iOS 17.0 o superior.
4. Elige un simulador de iPhone y presiona ⌘R.

No hacen falta permisos en Info.plist: `PhotosPicker` y `MapKit` no los piden.

## Qué hay en cada archivo
- `Theme.swift`: colores, medidas y letra del sistema visual «gamificado» (piezas gordas con borde
  inferior que se hunde al tocar, solo modo oscuro). Cambiar la paleta es editar solo este archivo.
- `MemoView.swift`: Memo, el elefantito, dibujado con formas (normal y contento; parpadea y flota,
  y se queda quieto con «Reducir movimiento»). También el banner con globo que lee en voz alta.
- `Model.swift`: modelos y datos de ejemplo (contrato compartido con el equipo) + `AppStore`.
- `Components.swift`: botones y tarjetas gordos, fichas, pestañas gordas, barra inferior con medallón,
  aviso "Deshacer" (8 s) con Memo, voz.
- `MemoriasCuidadorApp.swift`: `@main` y las 5 pestañas.
- `InicioView.swift`: mapa + signos vitales.
- `CalendarioView.swift` y `AgregarPastillaView.swift` (incluye "Agregar evento").
- `AlertasView.swift`.
- `RecuerdosView.swift` y `AgregarRecuerdoView.swift` (`PhotosPicker`).
- `PerfilView.swift`.
- `FamiliaView.swift`: pestaña Familia. Árbol genealógico que se acomoda solo según las personas
  (Carmen y su pareja en el tronco, hijos con sus parejas, nietos arriba). Si crece, se desliza a los lados.
- `AgregarPersonaView.swift`: hoja para agregar a alguien al árbol (foto, parentesco, nota y
  vista previa de lo que Carmen escuchará). Se puede deshacer 8 s.

### Una sola lista de personas
`AppStore.relatives` (en `Model.swift`) es la única lista de personas conocidas. De ahí salen el árbol,
los álbumes "Recuerdos → Por persona" y las fichas "¿Quién aparece?" al agregar un recuerdo.
Agregar a alguien desde Familia o desde Recuerdos lo agrega en los tres lugares. Amigos y vecinos
tienen álbum pero no van en las ramas.

## Lo que es de ejemplo (y qué sigue)
- Nada se guarda al cerrar la app (todo vive en memoria). Siguiente paso: SwiftData.
- Mapa: coordenadas inventadas. Siguiente paso: `CLLocationManager` + geocercas.
- Signos vitales: valores fijos. Siguiente paso: HealthKit + app de watchOS con `WatchConnectivity`.
- "Llamar" no marca todavía. "Agregar Apple Watch" solo muestra un aviso.
- Fotos del árbol: símbolos, salvo que se elija una foto al agregar a la persona; la voz es real (`AVSpeechSynthesizer`, es-MX).

No pude compilarlo aquí (no hay Xcode en este entorno). Si Xcode marca algún error,
mándame el texto del error y lo corrijo.

## Notas del sistema visual
- Letra de títulos: se usa SF Rounded. Arial Rounded MT Bold en iOS solo existe para Safari y su licencia
  no permite meterla en la app sin comprarla (ver comentario en `Theme.swift`).
- En Xcode, para iPad: en el target marca iPhone y iPad (Supported Destinations).
- Pendiente: en los tamaños de letra más grandes (accessibility4-5) algunas etiquetas sobre el mapa
  todavía se cortan con «…»; falta ajustarlas.
