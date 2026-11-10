import SwiftUI
import Combine
import AVFoundation
import Speech

/// Salida de voz: hace las preguntas y narra la historia, frase por frase.
final class VoiceOutput: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isSpeaking = false
    @Published private(set) var isPaused = false
    @Published private(set) var progress: Double = 0
    /// Duración estimada de la narración, en segundos.
    @Published private(set) var estimatedDuration: Double = 0

    private let synth = AVSpeechSynthesizer()
    private var indexOf: [AVSpeechUtterance: Int] = [:]
    private var offsets: [Int] = []
    private var total = 1
    private var lastIndex = -1
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self
    }

    private func makeUtterance(_ text: String) -> AVSpeechUtterance {
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "es-MX") ?? AVSpeechSynthesisVoice(language: "es-ES")
        u.rate = 0.48
        u.postUtteranceDelay = 0.15
        return u
    }

    /// Dice una frase suelta (pregunta de la IA) y avisa al terminar.
    func say(_ text: String, completion: (() -> Void)? = nil) {
        stop()
        onFinish = completion
        isSpeaking = true
        synth.speak(makeUtterance(text))
    }

    /// Narra la historia completa desde la frase `start`.
    func narrate(_ sentences: [String], from start: Int = 0) {
        stop()
        guard !sentences.isEmpty else { return }
        var acc = 0
        offsets = sentences.map { s in defer { acc += s.count + 1 }; return acc }
        total = max(acc, 1)
        estimatedDuration = Double(total) / 14.5
        lastIndex = sentences.count - 1
        isSpeaking = true
        for (i, s) in sentences.enumerated() where i >= start {
            let u = makeUtterance(s)
            indexOf[u] = i
            synth.speak(u)
        }
    }

    func pause() {
        guard isSpeaking, !isPaused else { return }
        synth.pauseSpeaking(at: .word)
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        synth.continueSpeaking()
        isPaused = false
    }

    func stop() {
        onFinish = nil
        synth.stopSpeaking(at: .immediate)
        indexOf.removeAll()
        resetState()
    }

    private func resetState() {
        isSpeaking = false; isPaused = false; currentIndex = nil; progress = 0
    }

    // MARK: AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) {
        DispatchQueue.main.async { if let i = self.indexOf[u] { self.currentIndex = i } }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance u: AVSpeechUtterance) {
        DispatchQueue.main.async {
            if let i = self.indexOf[u], i < self.offsets.count {
                self.progress = min(Double(self.offsets[i] + r.location) / Double(self.total), 1)
            }
        }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        DispatchQueue.main.async {
            if let i = self.indexOf[u] {
                if i == self.lastIndex { self.indexOf.removeAll(); self.resetState() }
            } else {
                let done = self.onFinish
                self.onFinish = nil
                self.isSpeaking = false
                done?()
            }
        }
    }
}

/// Entrada de voz: reconoce lo que cuenta la persona (es-MX).
@MainActor
final class VoiceInput: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isListening = false
    @Published private(set) var unavailable = false

    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private func authorize() async -> Bool {
        let speech: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    func start() async {
        guard !isListening else { return }
        guard let recognizer, recognizer.isAvailable, await authorize() else {
            unavailable = true
            return
        }
        unavailable = false
        transcript = ""
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement,
                                    options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req
            task = recognizer.recognitionTask(with: req) { [weak self] result, _ in
                guard let text = result?.bestTranscription.formattedString else { return }
                Task { @MainActor in self?.transcript = text }
            }
            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                req.append(buffer)
            }
            engine.prepare()
            try engine.start()
            isListening = true
        } catch {
            unavailable = true
            stopEngine()
        }
    }

    /// Detiene la escucha y devuelve lo reconocido.
    @discardableResult
    func stop() -> String {
        stopEngine()
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stopEngine() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        request = nil; task = nil
        isListening = false
    }
}
