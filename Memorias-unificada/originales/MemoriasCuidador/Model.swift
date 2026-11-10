import Foundation
import CoreLocation
import Observation

// MARK: - Modelos
// Todo es dato de ejemplo. Este archivo es el contrato compartido con el equipo:
// si el álbum o el camino usan otros nombres, se ajustan aquí.

enum AppTab: Hashable { case inicio, calendario, alertas, recuerdos, familia }
enum Route: Hashable { case perfil }

struct Person: Identifiable, Hashable {
    let id: String
    var name: String
    var relation: String
    var hasWatch: Bool
    var battery: Int?
    var heartRate: Int?
    var steps: Int
    var sleepText: String
    var latitude: Double
    var longitude: Double

    var initial: String { String(name.prefix(1)) }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Medication: Identifiable, Hashable {
    let id: UUID
    var name: String
    var personID: String
    var hour: Int
    var minute: Int
    var weekdays: Set<Int>   // 1 = domingo ... 7 = sábado (como Calendar)

    init(id: UUID = UUID(), name: String, personID: String, hour: Int, minute: Int, weekdays: Set<Int> = Set(1...7)) {
        self.id = id
        self.name = name
        self.personID = personID
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }

    var timeText: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, hour < 12 ? "am" : "pm")
    }
}

struct CareEvent: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var personID: String
    var date: Date
}

struct CareAlert: Identifiable, Hashable {
    enum Kind { case help, pendingDose, info }
    let id: String
    var kind: Kind
    var personID: String
    var title: String
    var detail: String
    var needsAttention: Bool
    var resolved = false
}

struct Album: Identifiable, Hashable {
    enum Kind { case person, experience }
    let id: String
    var name: String
    var subtitle: String
    var kind: Kind
    var calms: Bool?          // nil = sin datos del reloj todavía
    var photoData: Data? = nil
}

/// Una persona del árbol de Carmen. Es la ÚNICA lista de personas conocidas:
/// el árbol, los álbumes "Por persona" y "¿Quién aparece?" salen de aquí.
struct Relative: Identifiable, Hashable {
    enum Role: Hashable { case me, partner, child, childPartner, grandchild, friend }
    enum Gender: Hashable { case female, male }

    let id: String
    var name: String
    var role: Role
    var gender: Gender
    /// Pareja de un hijo o nieto: el id del hijo o hija de Carmen al que pertenece.
    var linkedTo: String? = nil
    /// Amigos y vecinos: quién es ("vecina", "amiga de la iglesia").
    var detail: String = ""
    /// Se agrega al final de la narración ("Viene a verte los domingos.").
    var note: String = ""
    var samplePhotos: Int = 0
    var calms: Bool? = nil
    var photoData: Data? = nil

    func g(_ female: String, _ male: String) -> String { gender == .female ? female : male }
}

/// Ficha de un recuerdo: es el contrato con el álbum y el narrador con IA.
/// La narración debe usar SOLO estos datos, para que la IA no invente.
struct MemoryRecord: Identifiable {
    let id = UUID()
    var photoData: Data?
    var people: [String]
    var when: String
    var place: String
    var phrase: String
    var narrateWithMyVoice: Bool
}

struct UndoNotice: Identifiable {
    let id = UUID()
    let message: String
    let undo: @MainActor () -> Void
}

// MARK: - Datos de ejemplo

enum SampleData {
    // Coordenadas de ejemplo (no son de nadie real).
    static let home = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)

    static let people: [Person] = [
        Person(id: "carmen", name: "Carmen", relation: "Mamá", hasWatch: true, battery: 64,
               heartRate: 74, steps: 1240, sleepText: "6 h 40 min",
               latitude: 19.4328, longitude: -99.1334),
        Person(id: "ernesto", name: "Don Ernesto", relation: "Abuelo", hasWatch: false, battery: nil,
               heartRate: nil, steps: 0, sleepText: "—",
               latitude: 19.4378, longitude: -99.1262)
    ]

    static let medications: [Medication] = [
        Medication(name: "Losartán", personID: "carmen", hour: 8, minute: 0),
        Medication(name: "Metformina", personID: "carmen", hour: 14, minute: 0),
        Medication(name: "Donepezilo 5 mg", personID: "carmen", hour: 21, minute: 0),
        Medication(name: "Metformina", personID: "ernesto", hour: 14, minute: 0)
    ]

    static let alerts: [CareAlert] = [
        CareAlert(id: "ayuda-carmen", kind: .help, personID: "carmen",
                  title: "Carmen pidió ayuda",
                  detail: "Botón «Estoy perdido» · hace 3 min.\nA 400 m de casa, fuera de la zona segura.",
                  needsAttention: true),
        CareAlert(id: "pastilla-ernesto", kind: .pendingDose, personID: "ernesto",
                  title: "Pastilla pendiente",
                  detail: "Don Ernesto · Metformina · 2:00 pm",
                  needsAttention: true),
        CareAlert(id: "volvio-carmen", kind: .info, personID: "carmen",
                  title: "Carmen volvió a casa", detail: "11:40 am · zona segura", needsAttention: false),
        CareAlert(id: "tomo-carmen", kind: .info, personID: "carmen",
                  title: "Carmen tomó su pastilla", detail: "Losartán · 8:02 am", needsAttention: false),
        CareAlert(id: "tomo-ernesto", kind: .info, personID: "ernesto",
                  title: "Don Ernesto tomó su pastilla", detail: "Enalapril · 8:15 am", needsAttention: false)
    ]

    static let relatives: [Relative] = [
        Relative(id: "carmen", name: "Carmen", role: .me, gender: .female),
        Relative(id: "ana", name: "Ana", role: .child, gender: .female,
                 note: "Viene a verte los domingos.", samplePhotos: 12, calms: true),
        Relative(id: "mateo", name: "Mateo", role: .grandchild, gender: .male, linkedTo: "ana",
                 samplePhotos: 8, calms: true),
        Relative(id: "andres", name: "Andrés", role: .child, gender: .male, samplePhotos: 5),
        Relative(id: "sofia", name: "Sofía", role: .friend, gender: .female, detail: "vecina", samplePhotos: 3),
        Relative(id: "roberto", name: "Roberto", role: .partner, gender: .male),
        Relative(id: "javier", name: "Javier", role: .childPartner, gender: .male, linkedTo: "ana"),
        Relative(id: "marta", name: "Marta", role: .childPartner, gender: .female, linkedTo: "andres"),
        Relative(id: "lucia", name: "Lucía", role: .grandchild, gender: .female, linkedTo: "ana"),
        Relative(id: "pablo", name: "Pablo", role: .grandchild, gender: .male, linkedTo: "andres")
    ]

    /// Álbumes de experiencias. Los de persona salen de `relatives`.
    static let albums: [Album] = [
        Album(id: "navidad", name: "Navidad 1998", subtitle: "14 fotos · 4 personas", kind: .experience, calms: true),
        Album(id: "boda", name: "La boda", subtitle: "9 fotos · 6 personas", kind: .experience, calms: nil)
    ]
}

// MARK: - Estado de la app

enum DayMark { case none, taken, missed, event }

@MainActor
@Observable
final class AppStore {
    var people: [Person] = SampleData.people
    var medications: [Medication] = SampleData.medications
    var events: [CareEvent] = []
    var alerts: [CareAlert] = SampleData.alerts
    var albums: [Album] = SampleData.albums
    var relatives: [Relative] = SampleData.relatives
    /// Persona elegida en el árbol (compartida para poder saltar al árbol desde otras pantallas).
    var familySelectedID = "ana"
    var memories: [MemoryRecord] = []

    /// nil = "Todos"
    var selectedPersonID: String? = "carmen"
    var selectedTab: AppTab = .inicio
    var notice: UndoNotice?

    // MARK: Derivados

    var visiblePeople: [Person] {
        guard let id = selectedPersonID else { return people }
        return people.filter { $0.id == id }
    }

    /// La persona sobre la que se muestran signos vitales.
    var focusPerson: Person {
        if let id = selectedPersonID, let p = people.first(where: { $0.id == id }) { return p }
        return people[0]
    }

    var attentionAlerts: [CareAlert] { alerts.filter { $0.needsAttention && !$0.resolved } }
    var todayAlerts: [CareAlert] { alerts.filter { !$0.needsAttention || $0.resolved } }
    var attentionCount: Int { attentionAlerts.count }

    func person(_ id: String) -> Person? { people.first { $0.id == id } }

    func nextMedication() -> Medication? {
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let list = medications
            .filter { selectedPersonID == nil || $0.personID == selectedPersonID }
            .sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
        return list.first { $0.hour * 60 + $0.minute >= nowMinutes } ?? list.first
    }

    /// Marca de cada día del calendario (de ejemplo, relativa a hoy).
    func mark(for date: Date, calendar: Calendar) -> DayMark {
        let diff = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: Date()),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        if diff < 0 { return diff == -4 ? .missed : (diff >= -8 ? .taken : .none) }
        if diff == 3 || diff == 8 { return .event }
        if events.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) { return .event }
        return .none
    }

    // MARK: Acciones (todas reversibles durante 8 segundos)

    func notify(_ message: String, undo: @escaping @MainActor () -> Void) {
        let n = UndoNotice(message: message, undo: undo)
        notice = n
        Task {
            try? await Task.sleep(for: .seconds(8))
            if notice?.id == n.id { notice = nil }
        }
    }

    func undoNotice() {
        notice?.undo()
        notice = nil
    }

    func addMedication(_ med: Medication) {
        medications.append(med)
        notify("Pastilla agregada") { [weak self] in
            self?.medications.removeAll { $0.id == med.id }
        }
    }

    func addEvent(_ event: CareEvent) {
        events.append(event)
        notify("Evento agregado") { [weak self] in
            self?.events.removeAll { $0.id == event.id }
        }
    }

    func addMemory(_ record: MemoryRecord) {
        memories.append(record)
        notify("Recuerdo guardado") { [weak self] in
            self?.memories.removeAll { $0.id == record.id }
        }
    }

    func markDoseTaken(alertID: String) {
        guard let i = alerts.firstIndex(where: { $0.id == alertID }) else { return }
        alerts[i].resolved = true
        notify("Marcada como tomada") { [weak self] in
            if let j = self?.alerts.firstIndex(where: { $0.id == alertID }) {
                self?.alerts[j].resolved = false
            }
        }
    }
}

// MARK: - Familia (árbol + álbumes por persona)

extension AppStore {
    func relative(_ id: String) -> Relative? { relatives.first { $0.id == id } }
    var me: Relative? { relatives.first { $0.role == .me } }
    var myPartner: Relative? { relatives.first { $0.role == .partner } }
    var children: [Relative] { relatives.filter { $0.role == .child } }
    var friends: [Relative] { relatives.filter { $0.role == .friend } }
    /// Todos menos Carmen: los que pueden salir en fotos y álbumes.
    var knownPeople: [Relative] { relatives.filter { $0.role != .me } }

    func partner(of childID: String) -> Relative? {
        relatives.first { $0.role == .childPartner && $0.linkedTo == childID }
    }
    func kids(of childID: String) -> [Relative] {
        relatives.filter { $0.role == .grandchild && $0.linkedTo == childID }
    }

    /// Nombre en la etiqueta del árbol: el árbol lo ve Carmen, así que ella es "Yo".
    func treeName(_ r: Relative) -> String { r.role == .me ? "Yo" : r.name }

    /// Lo que se lee debajo del nombre: "Tu hija", "Esposo de Ana"...
    func relationText(_ r: Relative) -> String {
        let parent = r.linkedTo.flatMap { relative($0)?.name } ?? ""
        switch r.role {
        case .me: return r.name
        case .partner: return "Tu " + r.g("esposa", "esposo")
        case .child: return "Tu " + r.g("hija", "hijo")
        case .childPartner: return r.g("Esposa", "Esposo") + " de \(parent)"
        case .grandchild: return "Tu " + r.g("nieta", "nieto")
        case .friend: return "Tu " + (r.detail.isEmpty ? r.g("amiga", "amigo") : r.detail)
        }
    }

    /// Etiqueta corta para los álbumes: "hija", "yerno", "vecina".
    func shortRelation(_ r: Relative) -> String {
        switch r.role {
        case .me: return "tú"
        case .partner: return r.g("esposa", "esposo")
        case .child: return r.g("hija", "hijo")
        case .childPartner: return r.g("nuera", "yerno")
        case .grandchild: return r.g("nieta", "nieto")
        case .friend: return r.detail.isEmpty ? r.g("amiga", "amigo") : r.detail
        }
    }

    /// Lo que dice "Escuchar quién es". Solo usa datos escritos por la familia.
    func narration(_ r: Relative) -> String {
        if r.role == .me { return "Tú eres \(r.name)." }
        let parent = r.linkedTo.flatMap { relative($0)?.name } ?? ""
        var text = "\(r.g("Ella", "Él")) es \(r.name), "
        switch r.role {
        case .childPartner: text += r.g("la esposa", "el esposo") + " de \(parent)."
        case .grandchild: text += "tu \(r.g("nieta", "nieto")), \(r.g("la hija", "el hijo")) de \(parent)."
        default:
            let rel = relationText(r)
            text += rel.prefix(1).lowercased() + rel.dropFirst() + "."
        }
        if !r.note.isEmpty { text += " " + r.note }
        return text
    }

    /// Álbumes "Por persona": uno por cada persona del árbol, siempre sincronizados.
    var personAlbums: [Album] {
        knownPeople.map { r in
            let n = r.samplePhotos + memories.filter { $0.people.contains(r.name) }.count
            let photos = n == 0 ? "Sin fotos" : (n == 1 ? "1 foto" : "\(n) fotos")
            return Album(id: r.id, name: r.name, subtitle: "\(photos) · \(shortRelation(r))",
                         kind: .person, calms: r.calms, photoData: r.photoData)
        }
    }

    /// Quién más se quita si se quita a esta persona (la pareja y los hijos de un hijo).
    func dependents(of id: String) -> [Relative] {
        guard relative(id)?.role == .child else { return [] }
        return relatives.filter { $0.linkedTo == id }
    }

    func addRelative(_ r: Relative) {
        relatives.append(r)
        familySelectedID = r.id
        notify("\(r.name) está en el árbol") { [weak self] in
            guard let self else { return }
            relatives.removeAll { $0.id == r.id }
            if familySelectedID == r.id { familySelectedID = me?.id ?? "" }
        }
    }

    func removeRelative(id: String) {
        guard let r = relative(id), r.role != .me else { return }
        let before = relatives
        let previousSelection = familySelectedID
        let gone = Set([id] + dependents(of: id).map(\.id))
        relatives.removeAll { gone.contains($0.id) }
        if gone.contains(familySelectedID) { familySelectedID = me?.id ?? "" }
        notify("Se quitó a \(r.name)") { [weak self] in
            self?.relatives = before
            self?.familySelectedID = previousSelection
        }
    }
}
