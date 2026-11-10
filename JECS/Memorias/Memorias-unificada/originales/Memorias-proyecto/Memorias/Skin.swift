import SwiftUI

// MARK: - Estilos de álbum vintage (prueba para el equipo)
// Estilo único de la app: «Juego» (tipo Duolingo). Los demás casos (sketch, black, kraft, cloth) son restos de las pruebas de estilo
// y ya no se pueden elegir; se pueden borrar de este archivo cuando el equipo quiera.
//  sketch  = dibujado a mano sobre acuarela (el estilo anterior, como referencia)
//  black   = páginas negras con esquinas de foto y tinta de gel crema
//  kraft   = álbum de cuero y papel kraft, etiquetas de máquina de escribir y puntadas
//  cloth   = álbum de tela azul, papel envejecido y filete dorado, sellos postales

enum SkinID: String, CaseIterable, Identifiable {
    case sketch, black, kraft, cloth, duo
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sketch: "Dibujado"
        case .black: "Páginas negras"
        case .kraft: "Cuero y kraft"
        case .cloth: "Tela y sellos"
        case .duo: "Juego (tipo Duolingo)"
        }
    }
}

private func c(_ hex: UInt32) -> Color { Color(UIColor(hex: hex)) }

enum Skin {
    static var current: SkinID = .duo   // único estilo de la app
    static var id: SkinID { current }

    // Texto y tinta sobre la página
    static var ink: Color {
        switch id { case .sketch: Pal.pen; case .black: c(0xF3EAD3); case .kraft: c(0x2B1D12); case .cloth: c(0x1B2A55) ; case .duo: c(0xFFFFFF) }
    }
    static var ink2: Color {
        switch id { case .sketch: Pal.text2; case .black: c(0xCFC6B0); case .kraft: c(0x5A4430); case .cloth: c(0x4A5578) ; case .duo: c(0xB7C4CB) }
    }
    /// Relleno de tarjetas y etiquetas
    static var card: Color {
        switch id { case .sketch: Color.white.opacity(0.78); case .black: c(0x232328); case .kraft: c(0xF6EEDC); case .cloth: c(0xFBF6E8) ; case .duo: c(0x1F2C34) }
    }
    /// Líneas y bordes
    static var line: Color {
        switch id { case .sketch: Pal.pen; case .black: c(0xB9B6AE); case .kraft: c(0x2B1D12); case .cloth: c(0x1B2A55) ; case .duo: c(0x37464F) }
    }
    /// Marcador de «ahora» y de lo elegido
    static var accent: Color {
        switch id { case .sketch: Pal.amber; case .black: c(0xE3B54A); case .kraft: c(0xA6261C); case .cloth: c(0xD4A63F) ; case .duo: c(0xFFC800) }
    }
    static var onAccent: Color {
        switch id { case .sketch: Pal.pen; case .black: c(0x121214); case .kraft: c(0xFFF7EA); case .cloth: c(0x1B2A55) ; case .duo: c(0x1F2C34) }
    }
    /// Barra inferior
    static var barFill: Color {
        switch id { case .sketch: Color.white.opacity(0.9); case .black: c(0x08080A); case .kraft: c(0x4A2E1B); case .cloth: c(0x1F3A78) ; case .duo: c(0x131F24) }
    }
    static var barText: Color {
        switch id { case .sketch: Pal.pen; case .black: c(0xF3EAD3); case .kraft: c(0xF2E3C4); case .cloth: c(0xF0D68A) ; case .duo: c(0xFFFFFF) }
    }

    // Tipografía: títulos y palabras personales (todo lo funcional sigue en SF)
    static func title(_ size: CGFloat, relativeTo style: Font.TextStyle = .title2) -> Font {
        switch id {
        case .sketch: Hand.font(size, relativeTo: style)
        case .black: .custom("SnellRoundhand-Bold", size: size * 1.12, relativeTo: style)
        case .kraft: .custom("AmericanTypewriter-Bold", size: size * 0.78, relativeTo: style)
        case .cloth: .custom("Baskerville-Bold", size: size * 0.86, relativeTo: style)
        case .duo: .custom("ArialRoundedMTBold", size: size * 0.9, relativeTo: style)
        }
    }

    static var bgName: String? {
        switch id { case .sketch: nil; case .black: "skin-black"; case .kraft: "skin-kraft"; case .cloth: "skin-cloth"; case .duo: nil }
    }
    static var fallbackBg: Color {
        switch id { case .sketch: Pal.bg; case .black: c(0x141417); case .kraft: c(0xC9A877); case .cloth: c(0xEFE3C6); case .duo: c(0x131F24) }
    }
}

// MARK: - Fondo

struct SkinBackground: View {
    var body: some View {
        if let name = Skin.bgName {
            GeometryReader { g in
                let file = name + (g.size.width / max(g.size.height, 1) < 0.6 ? "-portrait" : "-landscape")
                if let path = Bundle.main.path(forResource: file, ofType: "jpg"), let img = UIImage(contentsOfFile: path) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: g.size.width, height: g.size.height, alignment: .top).clipped()
                } else { Skin.fallbackBg }
            }
            .ignoresSafeArea()
        } else if Skin.id == .duo {
            Skin.fallbackBg.ignoresSafeArea()
        } else {
            PaperBackground()
        }
    }
}

// MARK: - Marco de tarjeta / etiqueta / botón

struct PhotoCorners: Shape {
    var size: CGFloat = 15
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.minX + size, y: r.minY)); p.addLine(to: CGPoint(x: r.minX, y: r.minY + size)); p.closeSubpath()
        p.move(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX - size, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY + size)); p.closeSubpath()
        p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX + size, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY - size)); p.closeSubpath()
        p.move(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX - size, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - size)); p.closeSubpath()
        return p
    }
}

struct SkinFrame: View {
    var radius: CGFloat = 14
    var seed: Double = 0
    var fill: Double = 0.78
    var line: CGFloat = 3
    var selected = false
    var tape = false              // cinta adhesiva (kraft)

    var body: some View {
        let pill = radius >= 24
        switch Skin.id {
        case .sketch:
            HandFrame(radius: radius, seed: seed, fill: fill, line: line, tint: selected ? Pal.amber.opacity(0.92) : nil)
        case .black:
            let r = RoundedRectangle(cornerRadius: pill ? radius : 3, style: .continuous)
            ZStack {
                r.fill(selected ? Skin.accent : Skin.card)
                r.strokeBorder(selected ? Skin.accent : Skin.line, lineWidth: 1.6)
                if !pill {
                    PhotoCorners().fill(selected ? Skin.onAccent.opacity(0.85) : Skin.ink.opacity(0.92)).padding(1)
                }
            }
        case .kraft:
            let r = RoundedRectangle(cornerRadius: pill ? radius : 4, style: .continuous)
            ZStack {
                r.fill(selected ? Skin.accent : Skin.card)
                r.strokeBorder(selected ? Skin.onAccent.opacity(0.6) : Skin.line.opacity(0.75), lineWidth: 1.4)
                r.strokeBorder(selected ? Skin.onAccent.opacity(0.4) : Skin.line.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])).padding(5)   // puntada
            }
            .shadow(color: .black.opacity(0.28), radius: 5, x: 0, y: 3)
            .overlay(alignment: .top) {
                if tape && !pill {
                    Rectangle().fill(Skin.accent.opacity(0.55)).frame(width: 54, height: 17)
                        .overlay(Rectangle().strokeBorder(Skin.line.opacity(0.18), lineWidth: 0.8))
                        .rotationEffect(.degrees(-4)).offset(y: -9)
                }
            }
        case .duo:   // tarjeta con «borde grueso» abajo, como un botón que se hunde
            let r = RoundedRectangle(cornerRadius: pill ? radius : 18, style: .continuous)
            ZStack {
                r.fill(selected ? Color(UIColor(hex: 0xC9A000)) : Skin.line).offset(y: 5)
                r.fill(selected ? Skin.accent : Skin.card)
                r.strokeBorder(selected ? Color(UIColor(hex: 0xC9A000)) : Skin.line, lineWidth: 2)
            }
        case .cloth:
            let r = RoundedRectangle(cornerRadius: pill ? radius : 2, style: .continuous)
            ZStack {
                r.fill(selected ? Skin.accent : Skin.card)
                r.strokeBorder(Skin.line, lineWidth: 2.2)
                r.strokeBorder(selected ? Skin.onAccent.opacity(0.5) : Color(UIColor(hex: 0xB8892B)), lineWidth: 1).padding(4.5)   // filete dorado
            }
            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Medallón de cada momento del día

struct ScallopCircle: Shape {
    var bumps = 26
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), rad = min(r.width, r.height) / 2
        let br = rad * 0.075
        p.addEllipse(in: CGRect(x: c.x - (rad - br), y: c.y - (rad - br), width: (rad - br) * 2, height: (rad - br) * 2))
        for i in 0..<bumps {
            let a = CGFloat(i) / CGFloat(bumps) * 2 * .pi
            p.addEllipse(in: CGRect(x: c.x + (rad - br) * cos(a) - br, y: c.y + (rad - br) * sin(a) - br, width: br * 2, height: br * 2))
        }
        return p
    }
}

/// Fondo + marco del medallón. El icono se pone encima. `current` = ahora, `done` = hecho, `pending` = pide un toque.
struct Medallion: View {
    var seed: Double = 0
    var current = false
    var done = false
    var pending = false
    var line: CGFloat = 3.5

    var body: some View {
        switch Skin.id {
        case .sketch:
            ZStack {
                if current { RoughCircle(seed: seed + 5).fill(Pal.amber.opacity(0.92)).padding(6).offset(x: -3, y: 3) }
                else { Circle().fill(Color.white.opacity(0.62)).padding(2) }
                SketchRing(seed: seed, line: current ? 4.5 : 3.5, hatch: done, dashed: pending)
            }
        case .black:   // montura de foto ovalada: aro plateado doble
            ZStack {
                Circle().fill(current ? Skin.accent : Skin.card)
                Circle().strokeBorder(Skin.line, lineWidth: 3)
                Circle().strokeBorder(current ? Skin.onAccent.opacity(0.5) : Skin.line.opacity(0.55), lineWidth: 1).padding(7)
                if done { Circle().fill(Skin.ink.opacity(0.1)).padding(9) }
                if pending { Circle().strokeBorder(Skin.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 7])).padding(-5) }
            }
        case .kraft:   // etiqueta redonda cosida
            ZStack {
                Circle().fill(current ? Skin.accent : Skin.card)
                Circle().strokeBorder(Skin.line, lineWidth: 3)
                Circle().strokeBorder(current ? Skin.onAccent.opacity(0.7) : Skin.line.opacity(0.7),
                                      style: StrokeStyle(lineWidth: 1.8, dash: [5, 5])).padding(8)
                if done { Circle().fill(Skin.ink.opacity(0.08)).padding(9) }
                if pending { Circle().strokeBorder(Skin.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 7])).padding(-5) }
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 3)
        case .duo:     // botón-nodo gordo: círculo de color con borde inferior, como el camino de Duolingo
            let top: Color = current ? Skin.accent : (done ? Color(UIColor(hex: 0x58CC02)) : Color(UIColor(hex: 0x3B4B54)))
            let edge: Color = current ? Color(UIColor(hex: 0xC9A000)) : (done ? Color(UIColor(hex: 0x46A302)) : Color(UIColor(hex: 0x2A363D)))
            GeometryReader { g in
                let d = min(g.size.width, g.size.height)
                ZStack {
                    Circle().fill(edge).frame(width: d * 0.94, height: d * 0.94).offset(y: d * 0.06)
                    Circle().fill(top).frame(width: d * 0.94, height: d * 0.94)
                    Circle().fill(Color.white.opacity(0.18)).frame(width: d * 0.5, height: d * 0.3).offset(y: -d * 0.26).blur(radius: 6)
                    if pending { Circle().strokeBorder(Skin.accent, style: StrokeStyle(lineWidth: 4, dash: [9, 7])).frame(width: d * 1.04, height: d * 1.04) }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        case .cloth:   // sello postal con dentado y filete dorado
            ZStack {
                ScallopCircle().fill(Skin.line)
                ScallopCircle().fill(current ? Skin.accent : Skin.card).scaleEffect(0.95)
                Circle().strokeBorder(current ? Skin.onAccent.opacity(0.6) : Color(UIColor(hex: 0xB8892B)), lineWidth: 1.6).padding(11)
                if done { Circle().fill(Skin.ink.opacity(0.07)).padding(12) }
                if pending { Circle().strokeBorder(Skin.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 7])).padding(-5) }
            }
            .shadow(color: .black.opacity(0.14), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Camino del día

struct SkinTrail: View {
    let start: CGPoint, c1: CGPoint, c2: CGPoint, end: CGPoint
    var walked = false
    var seed: Double = 0

    var body: some View {
        switch Skin.id {
        case .sketch:
            DotTrail(start: start, c1: c1, c2: c2, end: end, seed: seed).fill(Pal.pen.opacity(walked ? 0.9 : 0.35))
        case .black:
            DotTrail(start: start, c1: c1, c2: c2, end: end, spacing: 15, seed: seed)
                .fill(walked ? Skin.accent : Skin.ink.opacity(0.35))
        case .kraft:   // puntada de hilo
            curve.stroke(walked ? Skin.ink : Skin.ink.opacity(0.4), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: [11, 8]))
        case .duo:
            curve.stroke(walked ? Color(UIColor(hex: 0x58CC02)) : Color(UIColor(hex: 0x37464F)),
                         style: StrokeStyle(lineWidth: 9, lineCap: .round, dash: [0.1, 20]))
        case .cloth:   // filete dorado discontinuo
            curve.stroke(walked ? Color(UIColor(hex: 0xB8892B)) : Skin.ink.opacity(0.35), style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [2, 9]))
        }
    }

    private var curve: Path {
        var p = Path(); p.move(to: start); p.addCurve(to: end, control1: c1, control2: c2); return p
    }
}

// MARK: - Regla decorativa (bajo títulos y borde de la barra)

struct SkinRule: View {
    var seed: Double = 0
    var body: some View {
        switch Skin.id {
        case .sketch:
            WobbleLine(seed: seed).stroke(Pal.pen, style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(height: 8)
        case .black:
            ZStack { Rectangle().fill(Skin.line.opacity(0.7)).frame(height: 1.5)
                Rectangle().fill(Skin.accent).frame(width: 9, height: 9).rotationEffect(.degrees(45)) }
        case .kraft:
            Rectangle().fill(Color.clear).frame(height: 3)
                .overlay(Line().stroke(Skin.barText.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
        case .duo:
            Rectangle().fill(Skin.line).frame(height: 3)
        case .cloth:
            VStack(spacing: 2) {
                Rectangle().fill(Color(UIColor(hex: 0xD4A63F))).frame(height: 2)
                Rectangle().fill(Color(UIColor(hex: 0xD4A63F))).frame(height: 1)
            }
        }
    }
}

struct Line: Shape {
    func path(in r: CGRect) -> Path { var p = Path(); p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)); return p }
}
