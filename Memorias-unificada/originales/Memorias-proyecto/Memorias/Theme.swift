import SwiftUI
import UIKit
import AVFoundation

// MARK: - Color tokens
// Oscuro = carcasa negra del cassette + tinta azul vibrante. Claro = inlay blanco + tinta azul profunda.
// Todo el texto cumple >= 7:1 (AAA) contra su fondo.

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

enum Pal {
    static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    // Páginas negras: un solo tema oscuro (papel negro, tinta crema, marcador dorado)
    static var bg: Color { Skin.id == .duo ? Color(UIColor(hex: 0x131F24)) : Color(UIColor(hex: 0x121214)) }
    static var surface: Color { Skin.id == .duo ? Color(UIColor(hex: 0x1F2C34)) : Color(UIColor(hex: 0x232328)) }
    static var surface2: Color { Skin.id == .duo ? Color(UIColor(hex: 0x2A3A44)) : Color(UIColor(hex: 0x2C2C32)) }
    static let line     = Color(UIColor(hex: 0xB9B6AE))
    static var text: Color { Skin.id == .duo ? .white : Color(UIColor(hex: 0xF3EAD3)) }
    static var text2: Color { Skin.id == .duo ? Color(UIColor(hex: 0xB7C4CB)) : Color(UIColor(hex: 0xCFC6B0)) }
    static var ink: Color { Skin.id == .duo ? Color(UIColor(hex: 0x1CB0F6)) : Color(UIColor(hex: 0xE3B54A)) }   // acción principal
    static var onInk: Color { Skin.id == .duo ? Color(UIColor(hex: 0x0B1A22)) : Color(UIColor(hex: 0x121214)) }
    static let cover    = Color(UIColor(hex: 0x232328))
    static let stripe   = Color(UIColor(hex: 0xE3B54A))
    static let onStripe = Color(UIColor(hex: 0x121214))
    static let pen      = Color(UIColor(hex: 0xF3EAD3))     // tinta crema
    static var amber: Color { Skin.id == .duo ? Color(UIColor(hex: 0xFFC800)) : Color(UIColor(hex: 0xE3B54A)) }
    static let onAmber  = Color(UIColor(hex: 0x121214))

    // Fotos de ejemplo en sepia (sustituir por fotos reales con PhotosPicker)
    static var tones: [(bg: Color, fg: Color)] {
        if Skin.id == .duo { return [
            (Color(UIColor(hex: 0x1CB0F6)), Color(UIColor(hex: 0x0B1A22))),
            (Color(UIColor(hex: 0x58CC02)), Color(UIColor(hex: 0x0B1A22))),
            (Color(UIColor(hex: 0xFFC800)), Color(UIColor(hex: 0x0B1A22))),
            (Color(UIColor(hex: 0xCE82FF)), Color(UIColor(hex: 0x0B1A22))),
        ] }
        return sepia
    }
    static let sepia: [(bg: Color, fg: Color)] = [
        (Color(UIColor(hex: 0x5B4632)), Color(UIColor(hex: 0xF3EAD3))),
        (Color(UIColor(hex: 0x33404F)), Color(UIColor(hex: 0xF3EAD3))),
        (Color(UIColor(hex: 0x8C7455)), Color(UIColor(hex: 0x121214))),
        (Color(UIColor(hex: 0xB89A63)), Color(UIColor(hex: 0x121214))),
    ]
}

// MARK: - Tipografía
// SF Pro con Dynamic Type (mínimo xLarge, hasta accessibility5).
// La letra a mano solo aparece en palabras personales: título "Mi día", pies de foto, relatos.

enum Hand {
    static func font(_ size: CGFloat, relativeTo style: Font.TextStyle = .title2) -> Font {
        Skin.id == .duo ? .custom("ArialRoundedMTBold", size: size * 0.9, relativeTo: style)
                        : .custom("BradleyHandITCTT-Bold", size: size, relativeTo: style)
    }
}

// MARK: - Botones (confirmación visual en cada toque)

struct BigButton: ButtonStyle {
    enum Kind { case primary, outline }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        if Skin.id == .duo {   // botón gordo: se hunde al tocarlo
            let edge = kind == .primary ? Color(UIColor(hex: 0x1899D6)) : Color(UIColor(hex: 0x37464F))
            let depth: CGFloat = configuration.isPressed ? 1 : 6
            configuration.label
                .font(.title2.weight(.heavy))
                .multilineTextAlignment(.center)
                .lineLimit(3).minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: 72)
                .padding(.horizontal, 20)
                .foregroundStyle(kind == .primary ? Pal.onInk : Pal.ink)
                .background(shape.fill(kind == .primary ? Pal.ink : Color(UIColor(hex: 0x1F2C34))))
                .overlay(shape.strokeBorder(kind == .primary ? Color.clear : edge, lineWidth: 2))
                .background(shape.fill(edge).offset(y: depth))
                .offset(y: 6 - depth)
                .padding(.bottom, 6)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
        } else {
        configuration.label
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)
            .lineLimit(3).minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 20)
            .foregroundStyle(kind == .primary ? Pal.onInk : Pal.ink)
            .background(kind == .primary ? Pal.ink : Color.clear, in: shape)
            .overlay(shape.strokeBorder(Pal.ink, lineWidth: kind == .outline ? 3 : 0))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

/// Pastilla compacta de contorno (volver, estoy perdido).
struct OutlinePill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .lineLimit(2).minimumScaleFactor(0.8)
            .padding(.horizontal, 18).padding(.vertical, 10)
            .frame(minHeight: 60)
            .foregroundStyle(Pal.ink)
            .background(Pal.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Pal.ink, lineWidth: 3))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

/// Pastilla rellena pequeña (Deshacer en el aviso).
struct FilledPill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            .lineLimit(1).minimumScaleFactor(0.7)      // «Deshacer» nunca se parte con guion
            .padding(.horizontal, 20)
            .frame(minHeight: 60)
            .foregroundStyle(Pal.onInk)
            .background(Pal.ink, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

// MARK: - Habla (es-MX)

final class Speaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    @Published var speaking = false

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String) {
        stop()
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "es-MX")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85   // más pausado
        synth.speak(u)
        speaking = true
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        speaking = false
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { speaking = false }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { speaking = false }
}

// MARK: - Fondo: papel acuarela (arena arriba, blanco abajo)
// Se genera con tools/make_paper.py. Los textos van sobre blanco o sobre etiquetas, nunca sobre lo más oscuro del pigmento.

struct PaperBackground: View {
    var body: some View {
        GeometryReader { g in
            let name = g.size.width / max(g.size.height, 1) < 0.6 ? "paper-portrait" : "paper-landscape"
            if let path = Bundle.main.path(forResource: name, ofType: "jpg"), let img = UIImage(contentsOfFile: path) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: g.size.width, height: g.size.height, alignment: .top)
                    .clipped()
            } else {
                Pal.bg
            }
        }
        .ignoresSafeArea()
    }
}

/// Sombra de papel recortado: pequeña, con desplazamiento y desenfoque.
extension View {
    func paperShadow(_ strength: Double = 1) -> some View {
        shadow(color: Color.black.opacity(0.22 * strength), radius: 9, x: 0, y: 6)
    }
}
