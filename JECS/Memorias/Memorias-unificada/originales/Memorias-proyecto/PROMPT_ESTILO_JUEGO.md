# Prompt: estilo «Juego» (tipo Duolingo) de Memorias

Diseña/implementa la interfaz con el siguiente sistema visual. Plataforma: iPhone y iPad, SwiftUI, español de México. Usuaria: adulto mayor con pérdida de memoria leve o moderada, así que el estilo es alegre pero siempre claro, grande y sin prisa. Solo modo oscuro.

## Idea
Interfaz «gamificada» como Duolingo: botones y tarjetas «gordos» con un borde inferior sólido que se hunde al tocarlos, nodos redondos y brillantes en un camino de puntos, colores planos y saturados sobre un azul marino muy oscuro, y una mascota (Memo, un elefantito) que acompaña y habla. Sin sombras difusas ni degradados decorativos: la profundidad la da el borde inferior de cada pieza.

## Color
- Fondo: #131F24. Tarjetas y botones secundarios: #1F2C34 con borde #37464F.
- Texto principal blanco; texto secundario #B7C4CB. Texto sobre colores claros: #0B1A22.
- Acción principal (azul): #1CB0F6, borde inferior #1899D6.
- Atención / «ahora» / elegido (amarillo): #FFC800, borde inferior #C9A000.
- Hecho (verde): #58CC02, borde inferior #46A302.
- Por venir (gris azulado): #3B4B54, borde inferior #2A363D.
- Contraste de texto 7:1 o mejor; el color nunca es la única señal (siempre icono y texto).

## Tipografía
Títulos y palabras destacadas: Arial Rounded MT Bold (redondeada, gruesa). Cuerpo y controles: SF Pro, peso heavy o bold. Dynamic Type obligatorio de xLarge a accessibility5, con topes más bajos en elementos de ancho fijo (barra inferior, pestañas, etiquetas del camino, banner de la mascota). Nada se corta con «…»: el texto se encoge o pasa a otra línea.

## Componentes
- **Botón grande:** alto mínimo 72 pt, esquinas 22, texto bold. Principal: relleno azul, texto #0B1A22, borde inferior 6 pt. Secundario: relleno #1F2C34, texto azul, contorno #37464F. Al tocar baja 5 pt y el borde casi desaparece. Un botón principal por pantalla.
- **Tarjeta / etiqueta:** esquinas 18, relleno #1F2C34, borde inferior de 5 pt en #37464F. Las etiquetas del camino van ligeramente inclinadas (±1.5°).
- **Pestañas «Mi día / Calendario»:** dos botones gordos; el elegido en amarillo y un poco más grande.
- **Nodo del camino:** círculo de 104 pt (el actual, 118 %), con borde inferior de color más oscuro y un brillo suave arriba. Actual = amarillo con aro que late (se desactiva con «Reducir movimiento») y cinta «AHORA» amarilla pegada a su etiqueta. Hecho = verde con palomita. Por venir = gris azulado. Pendiente = contorno punteado amarillo.
- **Camino:** puntos redondos de 9 pt en curva en zigzag; verdes lo recorrido, #37464F lo que falta.
- **Barra inferior:** fondo #131F24, línea superior #37464F, tres o cuatro botones circulares con icono y etiqueta siempre visible; el elegido sube sobre la barra como un medallón amarillo con la etiqueta subrayada en amarillo. Fuera de «Mi día» aparece un botón «Mi día» (sol).
- **Aviso de confirmación (8 s):** tarjeta con Memo contento, mensaje y botón «Deshacer». Toda acción es reversible.
- **Iconos:** de línea limpia, trazo grueso y redondeado, en blanco u oscuro según el fondo (no usar SF Symbols de relleno de colores).

## Mascota: Memo, el elefantito (dibujado con formas)
Elefante sentado SOLO en gris y azul: cuerpo gris #9AA8B2 con contorno grueso #4B5B67, orejas grandes caídas con interior azul #1CB0F6, ojos enormes iguales (aro blanco #E6EEF2, iris azul #1CB0F6, pupila #0B1A22 y brillo blanco), trompa regordeta que baja y enrosca la punta con dos arruguitas, colmillitos #E6EEF2 y sombra suave en el piso. Dos estados: normal y contento (mejillas azules al 55 %). Parpadea y flota suavemente. Aparece en: banner de «Mi día» (62 pt, con un globo de una o dos líneas), «Cuéntame» y «Estoy perdido» (150 pt), y en el aviso de confirmación (44 pt). Al tocar su globo, lee el mensaje en voz alta (es-MX, más lento).

## Reglas de comportamiento
Objetivos táctiles de 60 pt o más; una acción por botón y sin menús dentro de menús; confirmación visible en cada toque; voz para leer lo que Memo dice; deslizar para pasar páginas del álbum; respetar «Reducir movimiento».
