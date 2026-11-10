import SwiftUI

enum MemoryTheme {
    static let darkBackground = Color(red: 0x0F / 255, green: 0x1B / 255, blue: 0x2D / 255)
    static let darkSurface = Color(red: 0x1A / 255, green: 0x2D / 255, blue: 0x4A / 255)
    static let darkAction = Color(red: 0x4D / 255, green: 0xA3 / 255, blue: 0xFF / 255)
    static let amber = Color(red: 1, green: 200 / 255, blue: 0x3D / 255)
}

/// Estilo «juego»: botón gordo con borde inferior que se hunde al tocarlo.
struct ChunkyPress: ButtonStyle {
    var edge: Color = MemoryTheme.edgeAmber
    func makeBody(configuration: Configuration) -> some View {
        let p = configuration.isPressed
        configuration.label
            .compositingGroup()
            .shadow(color: edge, radius: 0, x: 0, y: p ? 1 : 5)
            .offset(y: p ? 4 : 0)
            .animation(.easeOut(duration: 0.08), value: p)
    }
}

extension MemoryTheme {
    static let edgeAmber = Color(red: 0xCC / 255, green: 0x9F / 255, blue: 0)
    static let edgeBlue = Color(red: 0x2F / 255, green: 0x7F / 255, blue: 0xD6 / 255)
    static let edgeGray = Color(red: 0x2B / 255, green: 0x44 / 255, blue: 0x68 / 255)
    static let onAccent = Color(red: 0x0A / 255, green: 0x16 / 255, blue: 0x26 / 255)
    static let red = Color(red: 1, green: 200 / 255, blue: 0x3D / 255)   // antes coral; ahora dorado
}
