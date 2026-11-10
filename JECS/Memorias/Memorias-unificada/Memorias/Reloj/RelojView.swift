import SwiftUI
import UIKit

// MARK: - Apple Watch de Carmen (solo interfaz)
// Pantalla pensada para 45 mm (198 × 242 pt). Se muestra dentro de un reloj para verla en el iPad.
// Todo es de ejemplo: no envía nada. Para pasarla a un target de watchOS, mover RelojScreen tal cual
// (solo cambiar los hápticos por WKInterfaceDevice.current().play).

private enum WatchPhase: String, CaseIterable, Identifiable {
    case soon = "En 5 min", now = "Ahora", taken = "Tomada"
    var id: String { rawValue }
}

struct RelojView: View {
    @State private var phase: WatchPhase = .soon
    @State private var secondsLeft = 300

    var body: some View {
        ZStack {
            SkinBackground()
            VStack(spacing: 26) {
                Text("Apple Watch de Carmen").font(Skin.title(26, relativeTo: .title2)).foregroundStyle(Skin.ink)
                RelojScreen(phase: $phase, secondsLeft: $secondsLeft)
                    .frame(width: 198, height: 242)
                    .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 56, style: .continuous).fill(.black))
                    .overlay(RoundedRectangle(cornerRadius: 56, style: .continuous).strokeBorder(Color.white.opacity(0.25), lineWidth: 4))
                    .shadow(color: .black.opacity(0.5), radius: 24, y: 14)
                    .scaleEffect(1.7)
                    .frame(height: 242 * 1.7 + 40)

                VStack(spacing: 8) {
                    Text("Vista previa de avisos").font(.caption.weight(.heavy)).foregroundStyle(Pal.text2)
                    Picker("Aviso", selection: $phase) {
                        ForEach(WatchPhase.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(maxWidth: 360)
                }
            }
            .padding(.vertical, 24)
        }
        .onChange(of: phase) { _, p in if p == .soon { secondsLeft = 300 } }
    }
}

/// Lo que se ve en la pantalla del reloj: tres páginas (aviso, lo que ve Ana, lo que sigue).
private struct RelojScreen: View {
    @Binding var phase: WatchPhase
    @Binding var secondsLeft: Int
    @State private var banner: String?
    @State private var bannerTask: Task<Void, Never>?
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let green = Color(red: 0x3F/255, green: 0xD0/255, blue: 0x8F/255)
    private var minutes: Int { max(1, Int((Double(secondsLeft) / 60).rounded(.up))) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
            TabView {
                alarmPage
                sharedPage
                nextPage
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            if let banner {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill").foregroundStyle(MemoryTheme.amber)
                    Text(banner).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.18)))
                .padding(.horizontal, 6).padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: banner)
        .onReceive(tick) { _ in
            guard phase == .soon else { return }
            if secondsLeft > 0 { secondsLeft -= 1 } else { phase = .now }
        }
        .onChange(of: phase) { _, p in
            switch p {
            case .soon: notify("En 5 minutos es hora de tomar tu pastilla", .light)
            case .now: notify("Es hora de tomar tu pastilla", .medium)
            case .taken: notify("Ana ya sabe que la tomaste", .success)
            }
        }
    }

    // MARK: Página 1: aviso

    private var alarmPage: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(tone.opacity(0.25), lineWidth: 6)
                if phase == .soon {
                    Circle().trim(from: 0, to: CGFloat(secondsLeft) / 300)
                        .stroke(tone, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                if phase == .soon {
                    Text(String(format: "%d:%02d", secondsLeft / 60, secondsLeft % 60))
                        .font(.system(size: 24, weight: .heavy, design: .rounded)).monospacedDigit()
                        .foregroundStyle(tone)
                } else {
                    Image(systemName: phase == .taken ? "checkmark" : "pills.fill")
                        .font(.system(size: 28, weight: .heavy)).foregroundStyle(tone)
                }
            }
            .frame(width: 84, height: 84)
            Text(title).font(.system(size: 14, weight: .heavy)).foregroundStyle(.white)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if phase != .taken {
                Button { phase = .taken } label: {
                    Label("Ya la tomé", systemImage: "checkmark").font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(MemoryTheme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(Capsule().fill(tone))
                }.buttonStyle(.plain)
            } else {
                Button { phase = .now } label: {
                    Label("Deshacer", systemImage: "arrow.uturn.backward").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 34)
                        .background(Capsule().fill(Color(white: 0.2)))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.top, banner == nil ? 8 : 52).padding(.bottom, 22)
    }

    private var tone: Color { phase == .taken ? green : MemoryTheme.amber }
    private var title: String {
        switch phase {
        case .soon: "En \(minutes) \(minutes == 1 ? "min" : "min") es hora de tu pastilla"
        case .now: "Es hora de tomar tu pastilla"
        case .taken: "¡Listo, Carmen!"
        }
    }

    // MARK: Página 2: lo que ve Ana

    private var sharedPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lo que ve Ana").font(.system(size: 15, weight: .heavy)).foregroundStyle(MemoryTheme.amber)
            miniRow("house.fill", "En casa")
            miniRow("heart.fill", "74 lpm")
            miniRow("figure.walk", "1,240 pasos")
            miniRow("pills.fill", phase == .taken ? "2 de 2 pastillas" : "1 de 2 pastillas")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func miniRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(MemoryTheme.darkAction).frame(width: 22)
            Text(text).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10).frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(white: 0.14)))
    }

    // MARK: Página 3: lo que sigue

    private var nextPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lo que sigue").font(.system(size: 15, weight: .heavy)).foregroundStyle(MemoryTheme.amber)
            miniRow(phase == .taken ? "checkmark.circle.fill" : "pills.fill", "6:00 pm Pastilla")
            miniRow("fork.knife", "8:00 pm Cena")
            miniRow("pills.fill", "10:00 pm Pastilla")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Aviso

    private enum Haptic { case light, medium, success }
    private func notify(_ text: String, _ h: Haptic) {
        switch h {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        banner = text
        bannerTask?.cancel()
        bannerTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if !Task.isCancelled { banner = nil }
        }
    }
}
