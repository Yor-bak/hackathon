import SwiftUI

// DATOS SINTÉTICOS de demostración. Reemplazar por datos reales (Fotos, Contactos, Calendario).

struct Memory: Identifiable, Equatable {
    let id: UUID
    var title: String
    var year: Int?
    var caption: String      // pie de foto, letra a mano
    var story: String
    var symbol: String
    var tone: Int
    var addedBy: String      // "Ana", "Tú"
    var isNew = false
    var dateText: String     // "23 de octubre"
    var people: [String]     // nombres que aparecen sobre la foto
    var duration: String?    // duración del audio, "3:12"

    var hasStory: Bool { !story.isEmpty }
    var fullDate: String { year.map { "\(dateText) de \($0)" } ?? dateText }

    init(title: String, year: Int?, caption: String, story: String, symbol: String,
         tone: Int, addedBy: String, isNew: Bool = false,
         dateText: String = "", people: [String] = [], duration: String? = nil) {
        id = UUID(); self.title = title; self.year = year; self.caption = caption
        self.story = story; self.symbol = symbol; self.tone = tone
        self.addedBy = addedBy; self.isNew = isNew
        self.dateText = dateText; self.people = people; self.duration = duration
    }
}

/// Tipos de cita que la app espejo del cuidador puede agregar al calendario.
enum EventKind { case medicine, doctor, visit, birthday, other }

struct CalEvent: Identifiable, Equatable {
    let id: String
    let date: Date?          // nil = todos los días (rutina: pastillas, comidas)
    let minutes: Int         // minutos desde medianoche
    let title: String
    let kind: EventKind
    var addedBy: String? = nil   // quién lo agregó (cuidador); nil = rutina de la app
    var daily: Bool { date == nil }
}

/// Una sesión con el asistente de IA: le hace preguntas sobre un tema y lo que cuenta se guarda como página del álbum.
struct Session: Identifiable, Equatable {
    let id: String
    let title: String
    let question: String
    let symbol: String      // símbolo del recuerdo que genera
    let sample: String      // respuesta de ejemplo para la demostración
}

enum Sample {
    static let sessions: [Session] = [
        Session(id: "s-casa", title: "La casa de Puebla",
                question: "¿Cómo era la casa donde crecieron Ana y Luis?",
                symbol: "house.fill",
                sample: "Era una casa con patio y una higuera. Los domingos comíamos todos bajo el árbol."),
        Session(id: "s-trabajo", title: "Tu primer trabajo",
                question: "¿En qué trabajaste primero?",
                symbol: "briefcase.fill",
                sample: "En una tienda de telas. Aprendí a medir con la vara y me reía todo el día con Elvira."),
    ]

    // En orden cronológico: el libro se lee como una vida.
    static let memories: [Memory] = [
        Memory(title: "Nuestra boda", year: 1971,
               caption: "El día más feliz, con Ramón",
               story: "Nos casamos en la iglesia del pueblo. Llovió por la mañana, pero al salir de misa ya había sol. Mi mamá me prestó su velo.",
               symbol: "heart.fill", tone: 0, addedBy: "Ana", isNew: true,
               dateText: "14 de febrero", people: ["Carmen", "Ramón"], duration: "3:12"),
        Memory(title: "Mi primer coche", year: 1976,
               caption: "Un vocho azul",
               story: "",   // página vacía: muestra «Comienza una nueva historia»
               symbol: "car.fill", tone: 3, addedBy: "Ana",
               dateText: "23 de octubre", people: ["Ramón"], duration: nil),
        Memory(title: "La casa de Puebla", year: 1980,
               caption: "Donde crecieron Ana y Luis",
               story: "Era una casa con patio y una higuera. Los domingos comíamos todos bajo el árbol.",
               symbol: "house.fill", tone: 1, addedBy: "Luis",
               dateText: "3 de mayo", people: ["Ana", "Luis"], duration: "1:48"),
        Memory(title: "Domingo en el parque", year: 1992,
               caption: "Papalotes con los niños",
               story: "Luis perdió su papalote y lloró un rato, pero Ramón le hizo uno nuevo esa misma tarde.",
               symbol: "tree.fill", tone: 2, addedBy: "Tú",
               dateText: "12 de octubre", people: ["Luis", "Ramón"], duration: "2:05"),
        Memory(title: "Cumpleaños de Sofía", year: 2019,
               caption: "Cinco velitas",
               story: "Sofía sopló las velas con tanta fuerza que apagó hasta la luz del pastel.",
               symbol: "birthday.cake.fill", tone: 0, addedBy: "Ana",
               dateText: "8 de noviembre", people: ["Sofía", "Ana"], duration: "1:20"),
    ]

    /// Citas de ejemplo, relativas a hoy para que siempre haya algo cerca. SINTÉTICAS.
    static func events(today: Date = Fmt.cal.startOfDay(for: .now)) -> [CalEvent] {
        func day(_ off: Int) -> Date { Fmt.cal.date(byAdding: .day, value: off, to: today)! }
        return [
            CalEvent(id: "pm", date: nil, minutes: 8 * 60, title: "Pastilla de la mañana", kind: .medicine),
            CalEvent(id: "pt", date: nil, minutes: 18 * 60, title: "Pastilla de la tarde", kind: .medicine),
            CalEvent(id: "ana-hoy", date: day(0), minutes: 15 * 60, title: "Videollamada con Ana", kind: .visit, addedBy: "Ana"),
            CalEvent(id: "luis", date: day(1), minutes: 17 * 60, title: "Visita de Luis, tu hijo", kind: .visit, addedBy: "Ana"),
            CalEvent(id: "doc", date: day(2), minutes: 10 * 60 + 30, title: "Cita con la doctora Ríos", kind: .doctor, addedBy: "Ana"),
            CalEvent(id: "sangre", date: day(6), minutes: 8 * 60 + 30, title: "Análisis de sangre (sin desayunar)", kind: .doctor, addedBy: "Ana"),
            CalEvent(id: "sofia", date: day(12), minutes: 16 * 60, title: "Cumpleaños de Sofía, tu nieta", kind: .birthday, addedBy: "Ana"),
            CalEvent(id: "vista", date: day(24), minutes: 11 * 60, title: "Revisión de la vista", kind: .doctor, addedBy: "Ana"),
            CalEvent(id: "ana-ayer", date: day(-3), minutes: 15 * 60, title: "Visita de Ana", kind: .visit, addedBy: "Ana"),
        ]
    }
}
