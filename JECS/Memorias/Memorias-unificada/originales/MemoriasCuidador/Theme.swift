import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Sistema visual «gamificado»: piezas gordas con un borde inferior sólido que se hunde al tocarlas,
/// colores planos y saturados sobre azul marino muy oscuro. Sin sombras difusas ni degradados:
/// la profundidad la da el borde inferior. Solo modo oscuro.
/// Para cambiar la paleta basta con editar este archivo.
enum Theme {
    // Fondo y piezas
    static let background = Color(hex: 0x131F24)
    static let surface = Color(hex: 0x1F2C34)       // tarjetas y botones secundarios
    static let line = Color(hex: 0x37464F)          // contorno y borde inferior de tarjetas

    // Texto (contraste 7:1 o mejor sobre fondo y tarjetas)
    static let text = Color.white
    static let secondaryText = Color(hex: 0xB7C4CB)
    static let onInk = Color(hex: 0x0B1A22)         // texto sobre colores claros

    // Acción principal (azul)
    static let ink = Color(hex: 0x1CB0F6)
    static let inkEdge = Color(hex: 0x1899D6)

    // Atención / «ahora» / elegido (amarillo)
    static let attention = Color(hex: 0xFFC800)
    static let attentionEdge = Color(hex: 0xC9A000)

    // Hecho (verde)
    static let done = Color(hex: 0x58CC02)
    static let doneEdge = Color(hex: 0x46A302)

    // Por venir (gris azulado)
    static let upcoming = Color(hex: 0x3B4B54)
    static let upcomingEdge = Color(hex: 0x2A363D)

    // Caras del árbol y portadas
    static let faceFill = Color(hex: 0x1F2C34)
    static let faceFillAlt = Color(hex: 0x2A3A44)

    // Medidas
    static let buttonHeight: CGFloat = 72
    static let buttonCorner: CGFloat = 22
    static let buttonEdge: CGFloat = 6      // borde inferior de botones
    static let cardCorner: CGFloat = 18
    static let cardEdge: CGFloat = 5        // borde inferior de tarjetas
    static let pressDepth: CGFloat = 5      // cuánto baja al tocar
    static let cornerLarge: CGFloat = 18
    static let minTouch: CGFloat = 60       // objetivo táctil mínimo
    static let screenPadding: CGFloat = 24
    static let readableWidth: CGFloat = 720 // ancho máximo del contenido en iPad
}

extension Font {
    /// Títulos y palabras destacadas (nombres, frases), con Dynamic Type.
    ///
    /// El sistema pide Arial Rounded MT Bold, pero en iOS esa letra solo existe para Safari
    /// (carpeta WebFonts) y las apps no pueden usarla; su licencia tampoco permite meterla en la app
    /// sin comprarla. Por eso se usa SF Rounded (la letra redondeada de Apple), que se ve casi igual.
    /// Si consiguen la licencia: agreguen el .ttf al proyecto, decláralo en Info.plist (UIAppFonts)
    /// y cambien esta línea por `.custom("ArialRoundedMTBold", size: size, relativeTo: style)`.
    /// `size` se conserva por compatibilidad; el tamaño real lo da `style` para que siga a Dynamic Type.
    static func rounded(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .system(style, design: .rounded, weight: .heavy)
    }

    /// Nombre anterior; ahora usa la letra redondeada del sistema visual.
    static func handwritten(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        rounded(size, relativeTo: style)
    }
}

/// Rango de Dynamic Type: de xLarge a accessibility5 en toda la app.
/// Las piezas de ancho fijo usan topes más bajos (barra inferior, pestañas, etiquetas, banner de Memo).
enum TypeRange {
    static let app: ClosedRange<DynamicTypeSize> = .xLarge ... .accessibility5
    static let fixedWidth: ClosedRange<DynamicTypeSize> = .xLarge ... .accessibility2
    static let tabBar: ClosedRange<DynamicTypeSize> = .xLarge ... .xxxLarge
}

extension View {
    /// En iPad el contenido no se estira de lado a lado: queda centrado a un ancho cómodo de leer.
    func readableWidth() -> some View {
        frame(maxWidth: Theme.readableWidth).frame(maxWidth: .infinity)
    }
}
