import SwiftUI

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    var undo: (() -> Void)? = nil
}

/// Vista de la pantalla principal.
enum HomeMode { case day, calendar }

/// Secciones de la barra inferior. nil = «Mi día».
enum MainSection: String { case familia, recuerdos }

/// Pantallas que se abren encima de todo y se cierran con «Volver».
enum Screen: Identifiable, Equatable {
    case perdido, perfil
    var id: String { self == .perdido ? "perdido" : "perfil" }
}

@MainActor
final class AppState: ObservableObject {
    @Published var memories: [Memory] = Sample.memories
    /// Árbol genealógico de Carmen (se guarda en el dispositivo).
    let family = FamilyStore.shared
    @Published var done: Set<String> = []
    @Published var toast: Toast?
    @Published var section: MainSection? = {
        // Solo para capturas de pantalla: -screen album | familia | asistente
        let a = CommandLine.arguments
        guard let i = a.firstIndex(of: "-screen"), i + 1 < a.count else { return nil }
        switch a[i + 1] {
        case "album": return .recuerdos
        case "familia": return .familia
        default: return nil
        }
    }()
    @Published var albumStart = 0
    @Published var homeMode: HomeMode = CommandLine.arguments.contains("-mode") ? .calendar : .day   // -mode: solo capturas
    /// Citas y medicamentos. Los agrega la app espejo del cuidador.
    @Published var events: [CalEvent] = Sample.events()
    /// Sesiones con el asistente ya terminadas -> página del álbum que generaron.
    @Published var doneSessions: [String: UUID] = ["s-casa": Sample.memories[2].id]
    @Published var screen: Screen? = {
        let a = CommandLine.arguments
        guard let i = a.firstIndex(of: "-screen"), i + 1 < a.count else { return nil }
        switch a[i + 1] { case "perdido": return .perdido; case "perfil": return .perfil; default: return nil }
    }()

    func openAlbum(at i: Int) { albumStart = i; section = .recuerdos }

    /// Todo lo que pasa en un día: la rutina diaria más las citas de ese día, en orden de hora.
    func events(on d: Date) -> [CalEvent] {
        events.filter { $0.daily || $0.date.map { Fmt.cal.isDate($0, inSameDayAs: d) } == true }
            .sorted { $0.minutes < $1.minutes }
    }

    /// Solo las citas especiales del día (lo que se marca en el calendario; la rutina diaria no).
    func marks(on d: Date) -> [CalEvent] {
        events.filter { !$0.daily && $0.date.map { Fmt.cal.isDate($0, inSameDayAs: d) } == true }
    }

    func startSession(_ s: Session) { section = .recuerdos }

    func albumIndex(for s: Session) -> Int? {
        doneSessions[s.id].flatMap { id in memories.firstIndex { $0.id == id } }
    }

    private var toastTask: Task<Void, Never>?

    /// Confirmación visible tras cada acción. Dura 8 s: sin prisa.
    func confirm(_ message: String, undo: (() -> Void)? = nil) {
        toastTask?.cancel()
        toast = Toast(message: message, undo: undo)
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    func dismissToast() { toastTask?.cancel(); toast = nil }

    func toggleDone(_ key: String, title: String) {
        if done.contains(key) {
            done.remove(key)
        } else {
            done.insert(key)
            confirm("Listo: \(title)") { [weak self] in self?.done.remove(key) }
        }
    }

}

// MARK: - Fechas en español de México

enum Fmt {
    static let locale = Locale(identifier: "es_MX")
    static var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = locale
        c.firstWeekday = 2
        return c
    }()

    static func timeString(minutes m: Int) -> String {
        let h = m / 60, min = m % 60
        let h12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", h12, min, h < 12 ? "am" : "pm")
    }

}
