import AppKit
import AVFoundation

let W = 1920, H = 1080, FPS = 30.0
let home = NSHomeDirectory()
let appDir = home + "/Documents/Memorias/Memorias-unificada/Memorias/"
let outDir = "/private/tmp/claude-501/ad3/"

func C(_ h: UInt32, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: CGFloat((h>>16)&255)/255, green: CGFloat((h>>8)&255)/255, blue: CGFloat(h&255)/255, alpha: a) }
let navy = C(0x0F1B2D), card = C(0x1A2D4A), cardDark = C(0x142640), line = C(0x2B4468), blue = C(0x4DA3FF), gold = C(0xFFC83D), green = C(0x3FD08F), soft = C(0x8FA6C4), white = NSColor.white
func bold(_ s: CGFloat) -> NSFont { NSFont(name: "ArialRoundedMTBold", size: s) ?? .boldSystemFont(ofSize: s) }
func rounded(_ s: CGFloat, _ w: NSFont.Weight = .medium) -> NSFont { let f = NSFont.systemFont(ofSize: s, weight: w); if let d = f.fontDescriptor.withDesign(.rounded) { return NSFont(descriptor: d, size: s) ?? f }; return f }

// MARK: audio
struct Line { var who: Int; var text: String; var start = 0.0; var dur = 0.0; var env: [Float] = [] }
func envelope(_ path: String) -> ([Float], Double) {
  let f = try! AVAudioFile(forReading: URL(fileURLWithPath: path))
  let fmt = f.processingFormat
  let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(f.length))!
  try! f.read(into: buf)
  let sr = fmt.sampleRate, ch = buf.floatChannelData![0], n = Int(buf.frameLength), win = Int(sr / 60)
  var out = [Float](); var i = 0
  while i + win <= n { var s: Float = 0; for k in 0..<win { s += ch[i+k]*ch[i+k] }; out.append(sqrt(s / Float(win))); i += win }
  let mx = max(out.max() ?? 1, 0.0001)
  var sm = [Float](); var prev: Float = 0
  for v in out { let x = pow(v / mx, 0.75); prev = max(x, prev * 0.82); sm.append(prev) }
  return (sm, Double(n) / sr)
}
var lines = [
  Line(who: 0, text: "Carmen, mira esta foto. ¿Quién está contigo?"),
  Line(who: 1, text: "Es Ramón… mi esposo."),
  Line(who: 0, text: "Qué sonrisa tiene. ¿Te acuerdas dónde fue?"),
  Line(who: 1, text: "Mmm… no recuerdo bien dónde."),
  Line(who: 0, text: "No te preocupes. Mejor cuéntame del velo. Se ve muy largo."),
  Line(who: 1, text: "Sí… era de mi abuela."),
  Line(who: 0, text: "Qué bonito detalle. Ya lo guardé en tu historia."),
  Line(who: 0, text: "Y Ramón sale en muchas fotos. ¿Qué le gustaba hacer?"),
]
let gaps = [1.3, 0.5, 0.35, 0.8, 0.45, 0.5, 0.35, 0.35]
var clock = 0.0
for i in 0..<lines.count {
  let (e, d) = envelope(home + "/Downloads/\(i+1).mp3")
  lines[i].env = e; lines[i].dur = d; clock += gaps[i]; lines[i].start = clock; clock += d
}
let total = clock + 1.5
try! lines.map { String(Int($0.start * 1000)) }.joined(separator: "\n").write(toFile: outDir + "starts.txt", atomically: true, encoding: .utf8)
try! String(total).write(toFile: outDir + "total.txt", atomically: true, encoding: .utf8)

func amp(_ t: Double) -> (Int, Double)? {
  for L in lines where t >= L.start && t <= L.start + L.dur {
    let i = Int((t - L.start) * 60); return (L.who, Double(L.env[min(max(i, 0), L.env.count - 1)]))
  }
  return nil
}
func activeIndex(_ t: Double) -> Int? { lines.firstIndex { t >= $0.start && t <= $0.start + $0.dur } }

// MARK: drawing setup
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
ctx.interpolationQuality = .high
let gc = NSGraphicsContext(cgContext: ctx, flipped: true)
gc.imageInterpolation = .high
NSGraphicsContext.current = gc

func rr(_ r: CGRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }
func fill(_ r: CGRect, _ rad: CGFloat, _ c: NSColor) { c.setFill(); rr(r, rad).fill() }
func stroke(_ r: CGRect, _ rad: CGFloat, _ c: NSColor, _ w: CGFloat, dash: [CGFloat]? = nil, phase: CGFloat = 0) {
  let p = rr(r, rad); p.lineWidth = w; if let d = dash { p.setLineDash(d, count: d.count, phase: phase) }; c.setStroke(); p.stroke()
}
func attrs(_ f: NSFont, _ c: NSColor, _ al: NSTextAlignment = .left, lh: CGFloat = 0) -> [NSAttributedString.Key: Any] {
  let ps = NSMutableParagraphStyle(); ps.alignment = al; if lh > 0 { ps.minimumLineHeight = lh; ps.maximumLineHeight = lh }
  return [.font: f, .foregroundColor: c, .paragraphStyle: ps]
}
func text(_ s: String, _ r: CGRect, _ f: NSFont, _ c: NSColor, _ al: NSTextAlignment = .left, lh: CGFloat = 0) {
  (s as NSString).draw(with: r, options: [.usesLineFragmentOrigin], attributes: attrs(f, c, al, lh: lh), context: nil)
}
func ctext(_ s: String, _ cx: CGFloat, _ cy: CGFloat, _ f: NSFont, _ c: NSColor) {
  let sz = (s as NSString).size(withAttributes: [.font: f]); (s as NSString).draw(at: CGPoint(x: cx - sz.width/2, y: cy - sz.height/2), withAttributes: [.font: f, .foregroundColor: c])
}
func measure(_ s: String, _ w: CGFloat, _ f: NSFont, lh: CGFloat = 0) -> CGSize {
  let b = (s as NSString).boundingRect(with: CGSize(width: w, height: 10000), options: [.usesLineFragmentOrigin], attributes: attrs(f, white, .left, lh: lh)); return CGSize(width: ceil(b.width), height: ceil(b.height))
}
func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
func prog(_ t: Double, _ from: Double, _ dur: Double) -> Double { clamp((t - from) / dur) }
func eo(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
func eb(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }
func eio(_ x: Double) -> Double { x < 0.5 ? 4*x*x*x : 1 - pow(-2*x + 2, 3) / 2 }
func layer(alpha: Double, scale: Double = 1, anchor: CGPoint = .zero, dx: CGFloat = 0, dy: CGFloat = 0, _ body: () -> Void) {
  if alpha <= 0.002 { return }
  ctx.saveGState()
  ctx.translateBy(x: dx + anchor.x, y: dy + anchor.y); ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale)); ctx.translateBy(x: -anchor.x, y: -anchor.y)
  ctx.setAlpha(CGFloat(min(alpha, 1))); ctx.beginTransparencyLayer(auxiliaryInfo: nil)
  body()
  ctx.endTransparencyLayer(); ctx.restoreGState()
}
var symCache: [String: NSImage] = [:]
func drawSym(_ name: String, _ c: CGPoint, _ size: CGFloat, _ color: NSColor) {
  let key = "\(name)|\(size)|\(color.hashValue)"
  if symCache[key] == nil {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: size, weight: .bold)) else { return }
    symCache[key] = NSImage(size: base.size, flipped: false) { r in base.draw(in: r); color.set(); r.fill(using: .sourceAtop); return true }
  }
  let im = symCache[key]!
  im.draw(in: CGRect(x: c.x - im.size.width/2, y: c.y - im.size.height/2, width: im.size.width, height: im.size.height), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}
let photo = NSImage(contentsOfFile: appDir + "pesca-3.jpg")!
let memo = NSImage(contentsOfFile: appDir + "memo.png")!
func circleAvatar(_ c: CGPoint, _ d: CGFloat, _ bg: NSColor, _ scale: CGFloat = 1, letter: String? = nil) {
  let r = CGRect(x: c.x - d/2, y: c.y - d/2, width: d, height: d)
  ctx.saveGState(); NSBezierPath(ovalIn: r).addClip(); bg.setFill(); NSBezierPath(ovalIn: r).fill()
  if let l = letter { ctext(l, c.x, c.y + 2, bold(d * 0.5), navy) }
  else { let iw = d * 0.95 * scale, ih = iw * memo.size.height / memo.size.width
    memo.draw(in: CGRect(x: c.x - iw/2, y: c.y - ih/2 + d*0.05, width: iw, height: ih), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil) }
  ctx.restoreGState()
  let ring = NSBezierPath(ovalIn: r.insetBy(dx: 1.5, dy: 1.5)); ring.lineWidth = 3; line.setStroke(); ring.stroke()
}

// MARK: layout constants
let P = CGRect(x: 110, y: 205, width: 800, height: 702)
func fr(_ n: (Double, Double, Double, Double)) -> CGRect { CGRect(x: P.minX + n.0 * P.width, y: P.minY + n.1 * P.height, width: n.2 * P.width, height: n.3 * P.height) }
let carmenN = (0.279, 0.185, 0.208, 0.317), ramonN = (0.483, 0.065, 0.252, 0.457), veilN = (0.0, 0.02, 0.44, 0.30)
let feed = CGRect(x: 1020, y: 478, width: 780, height: 330)
let entryFont = rounded(34, .semibold)
let entryW: CGFloat = 760
let entryH: [CGFloat] = lines.map { 38 + 10 + measure($0.text, entryW, entryFont, lh: 44).height + 30 }
var tops = [CGFloat](), acc: CGFloat = 0
for h in entryH { tops.append(acc); acc += h }
func offsetFor(_ n: Int) -> CGFloat { n == 0 ? 0 : max(0, tops[n-1] + entryH[n-1] - 30 - feed.height) }
func scrollAt(_ t: Double) -> CGFloat {
  var k = 0; for (i, L) in lines.enumerated() where t >= L.start - 0.05 { k = i + 1 }
  if k == 0 { return 0 }
  let p = eio(prog(t, lines[k-1].start - 0.05, 0.55)); return offsetFor(k-1) + (offsetFor(k) - offsetFor(k-1)) * CGFloat(p)
}
func revealed(_ L: Line, _ t: Double) -> NSAttributedString {
  let words = L.text.components(separatedBy: " ")
  let p = clamp((t - L.start) / (L.dur * 0.88)); let n = Int((p * Double(words.count)).rounded(.up))
  let base = L.who == 0 ? white : C(0xBFDCFF)
  let ps = NSMutableParagraphStyle(); ps.minimumLineHeight = 44; ps.maximumLineHeight = 44
  let out = NSMutableAttributedString()
  for (i, w) in words.enumerated() {
    let col: NSColor = i >= n ? .clear : ((i == n - 1 && p < 1) ? gold : base)
    out.append(NSAttributedString(string: w + (i < words.count - 1 ? " " : ""), attributes: [.font: entryFont, .foregroundColor: col, .paragraphStyle: ps]))
  }
  return out
}

// MARK: pieces
func drawBackground(_ t: Double) {
  navy.setFill(); CGRect(x: 0, y: 0, width: W, height: H).fill()
  let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [C(0x3B5C86, 0.55).cgColor, C(0x3B5C86, 0).cgColor] as CFArray, locations: [0, 1])!
  ctx.drawRadialGradient(g, startCenter: CGPoint(x: 960, y: -60), startRadius: 0, endCenter: CGPoint(x: 960, y: -60), endRadius: 1150, options: [])
  let g2 = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [gold.withAlphaComponent(0.10).cgColor, gold.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
  ctx.drawRadialGradient(g2, startCenter: CGPoint(x: 1700, y: 1050), startRadius: 0, endCenter: CGPoint(x: 1700, y: 1050), endRadius: 700, options: [])
}
func drawHeader(_ t: Double) {
  let a = eo(prog(t, 0.1, 0.5))
  layer(alpha: a, dy: CGFloat((1 - a) * -16)) {
    let c = CGPoint(x: 130, y: 112)
    NSBezierPath(ovalIn: CGRect(x: c.x - 38, y: c.y - 32, width: 76, height: 76)).fill(with: C(0x0C1626))
    card.setFill(); NSBezierPath(ovalIn: CGRect(x: c.x - 38, y: c.y - 38, width: 76, height: 76)).fill()
    drawSym("xmark", c, 30, white)
    text("El día de la boda", CGRect(x: 194, y: 84, width: 900, height: 60), bold(46), white)
  }
}
extension NSBezierPath { func fill(with c: NSColor) { c.setFill(); fill() } }

func drawTag(_ r: CGRect, _ name: String, _ p: Double, _ color: NSColor = gold) {
  let a = clamp(p * 1.4); let s = 1.1 - 0.1 * eb(p)
  layer(alpha: a, scale: s, anchor: CGPoint(x: r.midX, y: r.midY)) {
    let o = rr(r, 12); o.lineWidth = 5; white.setStroke(); o.stroke()
    let f = bold(34); let tw = (name as NSString).size(withAttributes: [.font: f]).width + 36
    let cap = CGRect(x: r.midX - tw/2, y: r.minY - 54, width: tw, height: 44)
    fill(cap, 22, color); ctext(name, cap.midX, cap.midY + 1, f, navy)
  }
}
func drawCardLeft(_ t: Double) {
  let a = eo(prog(t, 0.2, 0.6))
  layer(alpha: a, scale: 0.97 + 0.03 * a, anchor: CGPoint(x: 510, y: 600)) {
    fill(CGRect(x: 80, y: 186, width: 860, height: 840), 34, C(0x0C1626))
    fill(CGRect(x: 80, y: 180, width: 860, height: 840), 34, card)
    stroke(CGRect(x: 80, y: 180, width: 860, height: 840), 34, line, 4)
    ctx.saveGState(); rr(P, 22).addClip()
    let sh = photo.size.width * P.height / P.width
    photo.draw(in: P, from: NSRect(x: 0, y: (photo.size.height - sh) / 2, width: photo.size.width, height: sh), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    navy.withAlphaComponent(0.55 * (1 - eo(prog(t, 0.5, 1.0)))).setFill(); P.fill()
    ctx.restoreGState()
    ctext("El día de la boda", P.midX, 950, bold(40), white)
    // etiquetas que se van llenando
    let s1 = lines[0].start, s2 = lines[1].start, s5 = lines[4].start, s6 = lines[5].start
    if t >= s1 + 0.25 { drawTag(fr(carmenN), "Carmen", prog(t, s1 + 0.25, 0.45)) }
    let rR = fr(ramonN)
    if t >= s1 + 1.8 && t < s2 + 0.9 {   // buscando a la persona
      let pulse = 0.55 + 0.45 * sin(t * 7)
      layer(alpha: min(prog(t, s1 + 1.8, 0.3), 1) * pulse) { stroke(rR, 12, gold, 5, dash: [16, 11], phase: CGFloat(t * 60)) }
    }
    if t >= s2 + 0.9 { drawTag(rR, "Ramón", prog(t, s2 + 0.9, 0.45)) }
    if t >= s5 + 1.9 {   // el velo
      let r = fr(veilN), p = prog(t, s5 + 1.9, 0.5), pulse = 0.75 + 0.25 * sin(t * 4)
      layer(alpha: p) {
        gold.withAlphaComponent(0.13 * pulse).setFill(); rr(r, 18).fill()
        stroke(r, 18, gold, 4, dash: [14, 10], phase: CGFloat(t * 40))
        let label = t >= s6 + 0.9 ? "Velo de tu abuela" : "El velo"; let f = bold(30)
        let tw = (label as NSString).size(withAttributes: [.font: f]).width + 34
        let cap = CGRect(x: r.minX + 14, y: r.maxY - 56, width: tw, height: 42)
        fill(cap, 21, gold); ctext(label, cap.midX, cap.midY + 1, f, navy)
      }
    }
  }
}
func audioState(_ t: Double) -> (who: Int, speaking: Bool, idle: Bool) {
  if let i = activeIndex(t) { return (lines[i].who, true, false) }
  if t < lines[0].start - 0.2 { return (0, false, true) }
  if let n = lines.first(where: { $0.start > t }) { return (n.who, false, false) }
  return (1, false, false)
}
func drawPanel(_ t: Double) {
  let a = eo(prog(t, 0.4, 0.6))
  layer(alpha: a, scale: 0.97 + 0.03 * a, anchor: CGPoint(x: 1410, y: 600)) {
    let panel = CGRect(x: 980, y: 180, width: 860, height: 840)
    fill(panel.offsetBy(dx: 0, dy: 6), 34, C(0x0C1626)); fill(panel, 34, card); stroke(panel, 34, line, 4)
    let st = audioState(t); let live = amp(t)
    // encabezado de Memo
    let memoScale = 1 + 0.07 * CGFloat((live?.0 == 0 ? live!.1 : 0))
    circleAvatar(CGPoint(x: 1062, y: 240), 84, C(0x26405F), memoScale)
    text("Memo", CGRect(x: 1120, y: 205, width: 500, height: 46), bold(38), white)
    text("te ayudo a recordar ese día", CGRect(x: 1120, y: 254, width: 600, height: 36), rounded(26), soft)
    line.setFill(); CGRect(x: 1000, y: 304, width: 820, height: 3).fill()
    // tarjeta de audio
    let ac = CGRect(x: 1020, y: 324, width: 780, height: 100)
    fill(ac, 26, cardDark); stroke(ac, 26, line, 3)
    let col = st.who == 0 ? gold : blue
    let bc = CGPoint(x: 1070, y: ac.midY)
    if st.speaking, let l = live {
      let r1 = 36 + CGFloat(l.1) * 12; layer(alpha: 0.5) { let p = NSBezierPath(ovalIn: CGRect(x: bc.x - r1, y: bc.y - r1, width: r1*2, height: r1*2)); p.lineWidth = 4; col.setStroke(); p.stroke() }
    }
    col.setFill(); NSBezierPath(ovalIn: CGRect(x: bc.x - 33, y: bc.y - 33, width: 66, height: 66)).fill()
    drawSym(st.idle ? "play.fill" : (st.who == 0 ? "speaker.wave.2.fill" : "mic.fill"), CGPoint(x: bc.x + (st.idle ? 3 : 0), y: bc.y), 28, navy)
    let label = st.idle ? "Escuchar historia" : (st.who == 0 ? (st.speaking ? "Memo está hablando" : "Memo está pensando…") : (st.speaking ? "Recibiendo la voz de Carmen" : "Escuchando a Carmen…"))
    text(label, CGRect(x: 1126, y: ac.minY + 14, width: 560, height: 34), bold(26), white)
    // forma de onda: historial de la señal que entra
    let N = 34
    for k in 0..<N {
      let tk = t - Double(N - 1 - k) * 0.03
      var h: CGFloat
      if let l = amp(tk) { h = 6 + 36 * CGFloat(pow(l.1, 0.9)) } else if st.idle { h = 6 } else { h = 6 + 4 * CGFloat(sin(t * 4 + Double(k) * 0.55) + 1) }
      let bx = 1128 + CGFloat(k) * 15.5
      fill(CGRect(x: bx, y: ac.maxY - 18 - h, width: 8, height: h), 4, col.withAlphaComponent(0.55 + 0.45 * CGFloat(k) / CGFloat(N)))
    }
    var el = 0.0; if let i = activeIndex(t) { el = t - lines[i].start }
    text("0:0\(Int(el))", CGRect(x: 1700, y: ac.midY - 17, width: 80, height: 34), NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .semibold), soft, .right)
    // transcripción
    text("transcripción", CGRect(x: 1020, y: 440, width: 400, height: 32), rounded(26, .semibold), soft)
    if !st.idle || t > lines[0].start - 0.5 {
      let pulse = 0.6 + 0.4 * sin(t * 6)
      green.withAlphaComponent(CGFloat(pulse)).setFill(); NSBezierPath(ovalIn: CGRect(x: 1700, y: 449, width: 14, height: 14)).fill()
      text("en vivo", CGRect(x: 1722, y: 440, width: 90, height: 32), rounded(24, .semibold), green)
    }
    // zona de conversación
    let sc = scrollAt(t)
    ctx.saveGState(); ctx.clip(to: feed)
    let ph = 1 - prog(t, lines[0].start - 0.1, 0.3)
    layer(alpha: ph * eo(prog(t, 0.9, 0.5))) {
      drawSym("text.bubble", CGPoint(x: feed.midX, y: feed.midY - 40), 54, soft.withAlphaComponent(0.6))
      text("Aquí irá tu conversación con Memo", CGRect(x: feed.minX, y: feed.midY + 6, width: feed.width, height: 40), rounded(28), soft, .center)
    }
    for (i, L) in lines.enumerated() where t >= L.start - 0.05 {
      let y = feed.minY + tops[i] - sc
      if y + entryH[i] < feed.minY - 10 || y > feed.maxY { continue }
      let a = eo(prog(t, L.start - 0.05, 0.3))
      layer(alpha: a, dy: CGFloat((1 - a) * 16)) {
        let nm = L.who == 0 ? "MEMO" : "CARMEN"; let pw = (nm as NSString).size(withAttributes: [.font: bold(20)]).width + 28
        fill(CGRect(x: 1020, y: y, width: pw, height: 34), 17, L.who == 0 ? gold : blue); ctext(nm, 1020 + pw/2, y + 17, bold(20), navy)
        if L.who == 1 { layer(alpha: 1) { drawSym("mic.fill", CGPoint(x: 1020 + pw + 22, y: y + 17), 18, blue) } }
        revealed(L, t).draw(with: CGRect(x: 1020, y: y + 46, width: entryW, height: 400), options: [.usesLineFragmentOrigin], context: nil)
      }
    }
    ctx.restoreGState()
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [card.cgColor, card.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
    ctx.saveGState(); ctx.clip(to: CGRect(x: feed.minX - 4, y: feed.minY, width: feed.width + 8, height: 44))
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: feed.minY), end: CGPoint(x: 0, y: feed.minY + 44), options: []); ctx.restoreGState()
    // «Tu historia» se llena al guardar
    let slot = CGRect(x: 1020, y: 822, width: 780, height: 92), ts = lines[6].start + 1.3, sp = prog(t, ts, 0.5)
    if sp <= 0 { stroke(slot, 22, line, 3, dash: [12, 9]); text("Tu historia se va guardando aquí", slot.insetBy(dx: 0, dy: 30), rounded(26), soft, .center) }
    else {
      layer(alpha: clamp(sp * 1.5), scale: 0.9 + 0.1 * eb(sp), anchor: CGPoint(x: slot.midX, y: slot.midY)) {
        fill(slot, 22, C(0x243E63)); stroke(slot, 22, gold, 3)
        text("TU HISTORIA · GUARDADO", CGRect(x: slot.minX + 24, y: slot.minY + 10, width: 560, height: 26), bold(20), gold)
        text("Llevabas el velo largo que había sido de tu abuela.", CGRect(x: slot.minX + 24, y: slot.minY + 40, width: 700, height: 40), rounded(27, .semibold), white)
        green.setFill(); NSBezierPath(ovalIn: CGRect(x: slot.maxX - 62, y: slot.minY + 14, width: 40, height: 40)).fill(); drawSym("checkmark", CGPoint(x: slot.maxX - 42, y: slot.minY + 34), 20, navy)
      }
    }
    // entrada de texto
    text("¿Se te olvidó algo?", CGRect(x: 1030, y: 950, width: 600, height: 40), rounded(30), soft)
    fill(CGRect(x: 1736, y: 940, width: 64, height: 6).offsetBy(dx: 0, dy: 56), 3, C(0xC9961A))
    gold.setFill(); NSBezierPath(ovalIn: CGRect(x: 1736, y: 934, width: 64, height: 64)).fill(); drawSym("plus", CGPoint(x: 1768, y: 966), 28, navy)
  }
}
func drawBubble(_ i: Int, _ t: Double) {
  let L = lines[i], memoSide = L.who == 0
  let nextSame = i + 1 < lines.count && lines[i+1].who == L.who, isLast = i == lines.count - 1
  let a1 = prog(t, L.start - 0.2, 0.4), vanish = L.start + L.dur + (nextSame ? 0.1 : 0.9)
  var a = eo(a1); var vy: CGFloat = 0
  if !isLast { let v = prog(t, vanish, 0.5); a *= 1 - v; vy = -CGFloat(eio(v)) * 70 }
  if a <= 0.01 { return }
  let f = bold(38), tw = min(measure(L.text, 10000, f).width + 4, 520), sz = measure(L.text, tw, f)
  let bw = tw + 56, bh = sz.height + 36 + 30
  let bottom: CGFloat = memoSide ? 800 : 890
  let rise = CGFloat((1 - eb(a1)) * 40), bob = CGFloat(sin(t * 2 * Double.pi / 2.6 + Double(i)) * 5)
  let rect = CGRect(x: memoSide ? 214 : 800 - bw, y: bottom - bh + rise + bob + vy, width: bw, height: bh)
  let avC = CGPoint(x: memoSide ? 162 : 852, y: rect.maxY - 42)
  let live = amp(t), speaking = live != nil && activeIndex(t) == i, v = speaking ? live!.1 : 0
  layer(alpha: a, scale: 0.8 + 0.2 * min(eb(a1), 1.08), anchor: CGPoint(x: memoSide ? rect.minX : rect.maxX, y: rect.maxY)) {
    let col = memoSide ? gold : blue
    for k in 0..<2 {   // anillos que laten con el audio
      let r = 50 + CGFloat(k) * 12 + CGFloat(v) * (14 + CGFloat(k) * 14)
      layer(alpha: speaking ? 0.55 - Double(k) * 0.25 : 0) { let p = NSBezierPath(ovalIn: CGRect(x: avC.x - r, y: avC.y - r, width: r*2, height: r*2)); p.lineWidth = 4; col.setStroke(); p.stroke() }
    }
    for k in (1...3).reversed() { C(0x000000, 0.10).setFill(); rr(rect.offsetBy(dx: 0, dy: CGFloat(k) * 5), 30).fill() }
    let bg = memoSide ? C(0xFFFFFF, 0.98) : gold
    bg.setFill(); rr(rect, 30).fill()
    let tail = NSBezierPath()
    if memoSide { tail.move(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 58)); tail.line(to: CGPoint(x: rect.minX - 18, y: rect.maxY - 40)); tail.line(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 24)) }
    else { tail.move(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - 58)); tail.line(to: CGPoint(x: rect.maxX + 18, y: rect.maxY - 40)); tail.line(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - 24)) }
    bg.setFill(); tail.fill()
    text(memoSide ? "MEMO" : "CARMEN", CGRect(x: rect.minX + 28, y: rect.minY + 16, width: 200, height: 24), bold(19), navy.withAlphaComponent(0.5))
    text(L.text, CGRect(x: rect.minX + 28, y: rect.minY + 42, width: tw + 4, height: sz.height + 4), f, navy)
    circleAvatar(avC, 84, memoSide ? C(0x26405F) : blue, 1 + 0.07 * CGFloat(v), letter: memoSide ? nil : "C")
    let bdg = CGPoint(x: avC.x + 30, y: avC.y + 30)
    white.setFill(); NSBezierPath(ovalIn: CGRect(x: bdg.x - 17, y: bdg.y - 17, width: 34, height: 34)).fill()
    drawSym(memoSide ? "speaker.wave.2.fill" : "mic.fill", bdg, 17, navy)
  }
}
func render(_ t: Double) {
  drawBackground(t); drawHeader(t); drawCardLeft(t); drawPanel(t)
  for i in 0..<lines.count { drawBubble(i, t) }
  let fade = max(1 - prog(t, 0, 0.35), prog(t, total - 0.7, 0.7))
  navy.withAlphaComponent(CGFloat(fade)).setFill(); CGRect(x: 0, y: 0, width: W, height: H).fill()
}

// MARK: salida
let args = CommandLine.arguments
if args.count > 1 && args[1] == "still" {
  for s in args.dropFirst(2) {
    render(Double(s)!)
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outDir + "still_\(s).png"))
  }
} else {
  let ff = Process(); ff.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
  ff.arguments = ["-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgra", "-s", "\(W)x\(H)", "-r", "30", "-i", "-", "-an", "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p", "-c:v", "libx264", "-crf", "16", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", outDir + "video_mute.mp4"]
  let pipe = Pipe(); ff.standardInput = pipe; try! ff.run()
  let n = Int(ceil(total * FPS))
  for f in 0..<n { render(Double(f) / FPS); pipe.fileHandleForWriting.write(Data(bytesNoCopy: ctx.data!, count: W * H * 4, deallocator: .none)) }
  pipe.fileHandleForWriting.closeFile(); ff.waitUntilExit()
}
print("total", total, "starts", lines.map { $0.start })
