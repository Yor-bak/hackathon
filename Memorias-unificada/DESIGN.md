# Design: Memorias (iPhone + iPad)

Mundo visual: collage sobre **papel acuarela** (arena arriba, blanco abajo; `Memorias/Resources/paper-*.jpg`, generado con `tools/make_paper.py`). **Mi día** va en tinta negra de pluma (#14161C) sobre el papel, dibujada a mano; el azul (#1033D6) queda en el álbum y las demás pantallas por ahora. Ámbar (marcador) solo para «AHORA» y lo que pide atención. La app está en **modo claro** (`preferredColorScheme(.light)`); el modo oscuro queda desactivado mientras el fondo sea de papel.

Lenguaje de componentes de Mi día (`Sketch.swift`): **círculos de pluma** (`RoughCircle`, doble trazo), **iconos de línea** dibujados con Paths (`SketchIcon`), **marcos y etiquetas** con borde tembloroso (`RoughRect`), **camino de puntos irregulares** (`DotTrail`), lo hecho con **rayado a lápiz y palomita**, lo de ahora con **marcador ámbar corrido**, recuerdos como **nube de pensamiento**. Sin rellenos sólidos ni sombras.

## Estructura
- **Mi día** (pantalla principal, `HomeView.swift`): «Estoy perdido» arriba a la izquierda, «Perfil» arriba a la derecha, título «Mi día» con la fecha, camino de círculos en zigzag con camino punteado, y barra inferior fija de 3 botones (Mi familia · Cuéntame · Mis recuerdos): es baja y el apartado elegido sobresale de la barra con marcador ámbar; fuera de «Mi día» aparece un botón «Mi día» (sol) a la izquierda para volver.
- **Mis recuerdos** (`RecuerdosView.swift`): un solo álbum, libro abierto con páginas en abanico 3D; tocar la página la abre. Diseño del equipo, se conserva.
- Mi familia y Cuéntame: pendientes (las diseña el equipo).

## Camino del día
Hecho = círculo rayado a lápiz con palomita. Ahora = círculo con marcador ámbar y etiqueta AHORA. Por venir = círculo solo de contorno. Pastilla pasada sin confirmar = contorno punteado y texto subrayado con marcador ámbar, «Toca si ya la tomaste». Sesión con el asistente = nube de pensamiento con micrófono; al tocarla abre «Cuéntame» con la pregunta de esa sesión; lo que se cuenta se guarda como página nueva del álbum y la nube queda con palomita y «Ya está en tu álbum» (al tocarla abre esa página).

## Color (Theme.swift, `Pal`)
| Token | Oscuro | Claro | Uso |
|---|---|---|---|
| bg | #060810 | #F6F8FD | fondo |
| surface / surface2 | #0F1424 / #18223B | #FFFFFF / #E3EAFA | círculos, tarjetas |
| text / text2 | #FFFFFF / #C3CCE0 | #0A0F24 / #39456B | texto (>= 7:1) |
| ink | #4DA3FF | #1033D6 | acción, hecho, selección |
| stripe | #FFC845 | #9A5B00 | AHORA y atención |

## Tipografía
SF Pro con Dynamic Type de xLarge a accessibility5 (barras: tope xxxLarge). Letra a mano (Bradley Hand) solo en palabras personales: «Mi día», pies de foto, relatos, títulos de recuerdos.

## Reglas
- Un botón principal por pantalla (BigButton, 72 pt mínimo) y uno de contorno.
- Cada acción confirma con un aviso de 8 s y «Deshacer».
- Sin menús dentro de menús; toda pantalla secundaria se cierra con «Volver a Mi día».

## Pendiente
Fotos reales, voz real, IA real, dirección real en «Estoy perdido», sincronización con la app del cuidador. Todo el contenido actual es sintético.

## Vista Calendario (pantalla principal)
Dos pestañas de papel arriba: «Mi día» y «Calendario» (la elegida en marcador ámbar). El calendario es mensual, dibujado a mano: nombre del mes en grande, botones con el nombre del mes anterior y siguiente (también se desliza en horizontal), «Hoy» aparece al centro solo cuando te alejas de hoy. Cada día con cita lleva un icono dibujado (pastilla, cruz de doctor, persona de visita, regalo); al tocar un día se ve su lista con hora y «Lo agregó Ana». Las citas y medicamentos los agrega la app espejo del cuidador: modelo `CalEvent` y `AppState.events` (datos de ejemplo en `Sample.events`).

## Estilos de álbum vintage (en prueba)
La app admite varios estilos con el mismo funcionamiento (`Memorias/Skin.swift`; se cambian en Perfil > «Estilo (prueba)» o con `-skin sketch|black|kraft|cloth`):
- **Páginas negras:** fondo negro de papel, tarjetas oscuras con esquinas de foto, tinta crema, títulos en cursiva (Snell Roundhand), medallones con aro plateado, camino de puntos dorados.
- **Cuero y kraft:** papel kraft, tarjetas crema cosidas (puntada discontinua) con cinta adhesiva, títulos de máquina de escribir (American Typewriter), marcador rojo, barra de cuero, camino de hilo.
- **Tela y sellos:** papel envejecido, tarjetas con filete dorado, títulos Baskerville, medallones como sellos postales dentados, barra de tela azul con dorado.
- **Dibujado:** el estilo anterior, como referencia.
Texturas generadas con `tools/make_skins.py`. Aún sin aplicar al álbum, «Estoy perdido» y «Perfil».

## DECISIÓN: estilo «Páginas negras» para toda la app
Se eligió el estilo de álbum vintage de páginas negras para todas las pantallas (Mi día, Calendario, álbum, Estoy perdido, Perfil, Cuéntame). Tokens (`Pal` y `Skin` en Theme.swift / Skin.swift): fondo papel negro #121214 con grano (Resources/skin-black-*.jpg), tarjetas #232328 con esquinas de foto crema, tinta crema #F3EAD3, texto secundario #CFC6B0, marcador y acción principal dorado #E3B54A (texto #121214 sobre dorado), líneas plateadas #B9B6AE. Títulos en cursiva de pluma (Snell Roundhand) y palabras personales con Bradley Hand; lo funcional en SF. Fotos de ejemplo en sepia. La app va siempre en modo oscuro. Los demás estilos (kraft, tela, dibujado) siguen en el código solo como referencia y ya no se ofrecen en Perfil.

## Exploración: estilo «Juego» (tipo Duolingo)
Disponible en Perfil > «Estilo (prueba del equipo)» o con `-skin duo`. Fondo azul marino #131F24, botones y tarjetas «gordos» con borde inferior sólido que se hunde al tocar, nodos del camino como botones redondos con brillo (actual = amarillo #FFC800, hecho = verde #58CC02, por venir = gris azulado), camino de puntos (verde lo recorrido), acción principal azul #1CB0F6, tipografía redondeada (Arial Rounded). Convive con «Páginas negras», que sigue siendo el predeterminado. Aún sin decidir cuál se queda.

## Mascota: Memo, el elefante («los elefantes nunca olvidan»)
Dibujado con formas en `Memorias/Mascot.swift` (sin imágenes), solo en el estilo Juego. Estilo de la referencia del equipo: elefantito sentado SOLO en gris y azul: cuerpo gris #9AA8B2 con contorno gris azulado #4B5B67 grueso, ojos enormes (uno azul claro y otro gris claro con aro azul), orejas grandes con interior azul #1CB0F6, trompa regordeta con la punta hacia arriba y colmillitos; parpadea y flota suave (se quita con «Reducir movimiento»). Estados: normal y contento. Usos: globo en «Mi día» que resume lo que toca ahora y lo lee en voz alta al tocarlo (`MascotSays`), y en el aviso de confirmación (contento). Pendiente: en «Cuéntame» y «Estoy perdido», y celebración al terminar una sesión.

## DECISIÓN FINAL: un solo estilo, «Juego»
La app usa únicamente el estilo «Juego» (tipo Duolingo) con Memo. «Páginas negras» y los demás estilos se quitaron de la app: ya no existe el selector de estilo en Perfil ni el argumento `-skin`, y se borraron las texturas de papel de `Memorias/Resources/`. Los restos de código de los otros estilos siguen en `Memorias/Skin.swift` sin poder elegirse. Esta decisión reemplaza a las secciones anteriores de «Páginas negras», «Papel acuarela» y «Estilos de álbum vintage».
