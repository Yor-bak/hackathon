# Contexto del proyecto «Memorias» (para el equipo y para cualquier asistente de IA)

## Qué es
App nativa para **iPhone y iPad** (Swift, **SwiftUI**, Xcode, iOS 17+) con el tema **«Adultos mayores: independientes, conectados y seguros»**. Es un álbum de recuerdos interactivo y una herramienta de orientación diaria para adultos mayores con pérdida de memoria leve o moderada. Se diseña para el caso moderado, que cubre también al leve.

Son dos apps:
1. **App del adulto mayor** (la que estamos diseñando): lo más simple e intuitiva posible.
2. **App espejo del familiar/cuidador**: monitorea la actividad y agrega recuerdos al álbum. Aún no diseñada aquí.

Idioma de la interfaz y de la voz: **español de México**.

## Usuario principal
Adulto mayor que usa el iPad o iPhone solo, en casa. Se confunde con facilidad, no debe perder nada por equivocación y necesita saber qué día es, quién es quién y qué sigue. Usuaria de ejemplo: Carmen; hija Ana (familiar de confianza).

## Principios (no negociables)
1. Una pantalla, un trabajo: un botón principal por pantalla.
2. Orientación antes que funciones: siempre se sabe qué día es y qué sigue.
3. Nada se pierde: toda decisión es reversible (aviso de 8 s con «Deshacer»).
4. Calma: sin urgencia, temporizadores ni sorpresas.
5. El cuidador refuerza al adulto mayor, nunca lo reemplaza.
Además: menús de una sola acción (sin menús dentro de menús), confirmación visible en cada botón, asistente de voz para acciones, alto contraste y texto extragrande.

## Pantallas del adulto mayor
- **Mi día (principal):** «Estoy perdido» (arriba izq.), «Perfil» (arriba der.), título «Mi día» con fecha, camino de círculos en zigzag con camino punteado (actividades y recuerdos), barra inferior FIJA y baja de 3 botones (el elegido sobresale; fuera de Mi día aparece un botón «Mi día» para volver): **Mi familia** (árbol genealógico), **Cuéntame** (asistente de IA que pregunta por su historia y la guarda en el álbum), **Mis recuerdos** (álbum).
- **Mis recuerdos:** UN solo álbum con toda la historia de la persona. Libro abierto con páginas en abanico 3D; tocar la página la abre (foto con nombres, audio con transcripción o «Comienza una nueva historia»).
- **Mi familia** y **Cuéntame:** las diseña el equipo (hoy son pantallas vacías con «Volver a Mi día»).
- **Calendario:** parte de la idea original; su lugar en la navegación está por definir.

## Camino de «Mi día»
Hecho = círculo azul relleno con palomita. Ahora = anillo ámbar + «AHORA». Por venir = anillo azul. Pastilla pasada sin confirmar = anillo ámbar punteado «Toca si ya la tomaste». Nube de pensamiento con micrófono = SESIÓN con el asistente de IA: al tocarla abre «Cuéntame» con la pregunta de la sesión; lo que se cuenta se guarda como página nueva del álbum (`AppState.completeSession`) y la nube queda con palomita.

## Sistema visual
Mundo: collage sobre **papel acuarela** (fondo arena que se desvanece a blanco, definido por el equipo), con tinta azul vibrante y negro. La app va en modo claro. «Mi día» va en tinta negra de pluma, todo dibujado a mano (círculos de trazo tembloroso, iconos de línea, etiquetas con borde irregular, camino de puntos), con marcador ámbar para «AHORA»; sin rellenos sólidos ni sombras. El azul sigue en el álbum y las demás pantallas. Todo el texto ≥ 4.5:1 (la mayoría ≥ 7:1).
- Tinta (acción, hecho): #1033D6. Texto: #0A0F24 / #39456B. Superficies: blanco. Ámbar: relleno #FFC845 con texto #0A0F24; como texto #9A5B00 (solo «AHORA» y atención).
- Fondo: papel acuarela (Resources/paper-portrait.jpg y paper-landscape.jpg; regenerar con tools/make_paper.py).
- Tipografía: SF Pro con Dynamic Type (mínimo xLarge, hasta accessibility5; barras con tope xxxLarge). Letra a mano (Bradley Hand) SOLO en palabras personales: «Mi día», pies de foto, relatos.
- Botones: 72 pt de alto mínimo; objetivos táctiles ≥ 60 pt; siempre con texto, no solo icono.
- Respetar «Reducir movimiento» (el paso de página cambia a fundido).

## Estado actual del código
Carpeta `Memorias/`: `MemoriasApp.swift`, `HomeView.swift` (Mi día), `RecuerdosView.swift` (álbum), `Theme.swift` (tokens, botones, voz), `AppState.swift`, `Model.swift`. Compilar para el simulador: `./build.sh`. Para capturas: argumentos de lanzamiento `-screen album|familia|asistente|perdido|perfil` y `-entry`.
**Todo es simulado/sintético:** fotos (símbolos sobre color plano), voz (solo lectura en voz alta real con AVSpeechSynthesizer), IA, «Estoy perdido» (dirección y llamada), datos del día.
**Pendiente:** fotos reales (PhotosPicker), reconocimiento de voz (Speech), IA real, Contactos/Calendario/Ubicación, sincronización y permisos con la app del cuidador, árbol genealógico, asistente Cuéntame.

## Cómo trabajar sobre esto
Respeta los principios y el sistema visual; no agregues menús anidados ni gestos ocultos; usa controles nativos de iOS salvo razón de accesibilidad; no inventes datos reales (mantén lo sintético etiquetado); verifica en iPhone y iPad, en oscuro y claro, y con texto gigante.

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
