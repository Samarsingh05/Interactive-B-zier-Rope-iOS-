//
//  BezierRopeView.swift
//  BezierRope
//
//  Created by Samar Singh on 10/11/25.
//

import UIKit
import CoreGraphics

fileprivate struct SpringPoint {
    var pos: CGPoint
    var vel: CGPoint
    var mass: CGFloat = 1.0

    mutating func apply(acc: CGPoint, dt: CGFloat) {
        vel.x += acc.x * dt
        vel.y += acc.y * dt
        pos.x += vel.x * dt
        pos.y += vel.y * dt
    }
}

class BezierRopeView: UIView {
    private var p0: CGPoint = .zero
    private var p3: CGPoint = .zero

    private var p1 = SpringPoint(pos: .zero, vel: .zero)
    private var p2 = SpringPoint(pos: .zero, vel: .zero)

    private let stiffness: CGFloat = 80.0
    private let damping: CGFloat = 12.0

    private let dtSample: CGFloat = 0.01  // step for t in [0,1]
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    private var draggingPoint: UnsafeMutablePointer<SpringPoint>? = nil
    private var dragOffset = CGPoint.zero

    private let motion = MotionManager.shared
    private var motionEnabled = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        backgroundColor = .black
        setupInitialPoints()
        isMultipleTouchEnabled = true
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(resetPositions))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInitialPoints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupInitialPoints()
    }

    private func setupInitialPoints() {
        let w = bounds.width
        let h = bounds.height
        let center = CGPoint(x: w/2, y: h/2)
        p0 = CGPoint(x: 40, y: center.y)
        p3 = CGPoint(x: w - 40, y: center.y)

        p1.pos = CGPoint(x: w * 0.33, y: center.y - 40)
        p2.pos = CGPoint(x: w * 0.66, y: center.y + 40)
        p1.vel = .zero
        p2.vel = .zero
    }

    func start() {
        motion.startUpdates()
        lastTimestamp = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(step(_:)))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        motion.stopUpdates()
    }

    @objc func resetPositions() {
        setupInitialPoints()
        setNeedsDisplay()
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = CGFloat(min(now - lastTimestamp, 1.0/30.0)) // clamp large dt
        lastTimestamp = now

        let motionOffset = motionEnabled ? motion.offset2D(scale: 120) : .zero

        let base1 = CGPoint(x: (p0.x + p3.x) * 0.25, y: (p0.y + p3.y) * 0.5)
        let base2 = CGPoint(x: (p0.x + p3.x) * 0.75, y: (p0.y + p3.y) * 0.5)

        let target1 = CGPoint(x: base1.x + motionOffset.x * 1.2, y: base1.y + motionOffset.y * 1.2)
        let target2 = CGPoint(x: base2.x + motionOffset.x * 0.8, y: base2.y + motionOffset.y * 0.8)

        var finalTarget1 = target1
        var finalTarget2 = target2
        if let dragging = draggingPoint {
        }

        do {
            let pos = p1.pos
            let dx = pos.x - finalTarget1.x
            let dy = pos.y - finalTarget1.y
            let ax = -stiffness * dx / p1.mass - damping * p1.vel.x / p1.mass
            let ay = -stiffness * dy / p1.mass - damping * p1.vel.y / p1.mass
            if draggingPoint != nil && draggingPoint == withUnsafeMutablePointer(to: &p1, { $0 }) {
            } else {
                p1.apply(acc: CGPoint(x: ax, y: ay), dt: dt)
            }
        }

        do {
            let pos = p2.pos
            let dx = pos.x - finalTarget2.x
            let dy = pos.y - finalTarget2.y
            let ax = -stiffness * dx / p2.mass - damping * p2.vel.x / p2.mass
            let ay = -stiffness * dy / p2.mass - damping * p2.vel.y / p2.mass
            if draggingPoint != nil && draggingPoint == withUnsafeMutablePointer(to: &p2, { $0 }) {
            } else {
                p2.apply(acc: CGPoint(x: ax, y: ay), dt: dt)
            }
        }

        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        let r: CGFloat = 30
        if distance(loc, p1.pos) < r {
            draggingPoint = withUnsafeMutablePointer(to: &p1, { $0 })
            dragOffset = CGPoint(x: p1.pos.x - loc.x, y: p1.pos.y - loc.y)
        } else if distance(loc, p2.pos) < r {
            draggingPoint = withUnsafeMutablePointer(to: &p2, { $0 })
            dragOffset = CGPoint(x: p2.pos.x - loc.x, y: p2.pos.y - loc.y)
        } else {
            draggingPoint = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let dragging = draggingPoint else { return }
        let loc = t.location(in: self)
        let newPos = CGPoint(x: loc.x + dragOffset.x, y: loc.y + dragOffset.y)
        dragging.pointee.pos = newPos
        dragging.pointee.vel = .zero
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingPoint = nil
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)

        drawBackground(in: ctx, rect: rect)

        let samples = sampleBezierPoints(step: dtSample)

        ctx.setLineWidth(3.0)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(UIColor.systemTeal.cgColor)
        if let first = samples.first {
            ctx.move(to: first)
            for p in samples.dropFirst() { ctx.addLine(to: p) }
            ctx.strokePath()
        }

        drawTangents(in: ctx, stepCount: max(2, Int(1.0 / dtSample)), pickEvery: 8)

        ctx.setLineWidth(1)
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
        ctx.move(to: p0); ctx.addLine(to: p1.pos); ctx.addLine(to: p2.pos); ctx.addLine(to: p3)
        ctx.strokePath()

        drawControlPoint(in: ctx, at: p0, color: UIColor.white, filled: false)
        drawControlPoint(in: ctx, at: p3, color: UIColor.white, filled: false)
        drawControlPoint(in: ctx, at: p1.pos, color: UIColor.systemYellow, filled: true)
        drawControlPoint(in: ctx, at: p2.pos, color: UIColor.systemOrange, filled: true)
    }

    private func drawBackground(in ctx: CGContext, rect: CGRect) {
        let colors = [UIColor.black.cgColor, UIColor(white: 0.05, alpha: 1).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = max(rect.width, rect.height)
            ctx.drawRadialGradient(grad, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
    }

    private func drawControlPoint(in ctx: CGContext, at point: CGPoint, color: UIColor, filled: Bool) {
        let r: CGFloat = 8.0
        ctx.setLineWidth(2)
        ctx.setStrokeColor(color.cgColor)
        if filled {
            ctx.setFillColor(color.withAlphaComponent(0.95).cgColor)
            ctx.addEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r*2, height: r*2))
            ctx.drawPath(using: .fillStroke)
        } else {
            ctx.addEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r*2, height: r*2))
            ctx.strokePath()
        }
    }

    private func drawTangents(in ctx: CGContext, stepCount: Int, pickEvery: Int) {
        var i = 0
        for t in stride(from: 0.0 as CGFloat, through: 1.0 as CGFloat, by: dtSample) {
            if i % pickEvery == 0 {
                let p = bezierPoint(t: t)
                let tangent = bezierTangent(t: t)
                let len: CGFloat = 20.0
                let tx = p.x + tangent.x * len
                let ty = p.y + tangent.y * len
                ctx.setLineWidth(1.0)
                ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
                ctx.move(to: p)
                ctx.addLine(to: CGPoint(x: tx, y: ty))
                ctx.strokePath()
            }
            i += 1
        }
    }

    private func sampleBezierPoints(step: CGFloat) -> [CGPoint] {
        var pts: [CGPoint] = []
        var t: CGFloat = 0
        while t <= 1.0 + 1e-6 {
            pts.append(bezierPoint(t: t))
            t += step
        }
        return pts
    }

    private func bezierPoint(t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t

        let x = mt3 * p0.x
            + 3 * mt2 * t * p1.pos.x
            + 3 * mt * t2 * p2.pos.x
            + t3 * p3.x

        let y = mt3 * p0.y
            + 3 * mt2 * t * p1.pos.y
            + 3 * mt * t2 * p2.pos.y
            + t3 * p3.y

        return CGPoint(x: x, y: y)
    }

    private func bezierTangent(t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let term1 = 3 * mt * mt
        let term2 = 6 * mt * t
        let term3 = 3 * t * t

        let x = term1 * (p1.pos.x - p0.x) + term2 * (p2.pos.x - p1.pos.x) + term3 * (p3.x - p2.pos.x)
        let y = term1 * (p1.pos.y - p0.y) + term2 * (p2.pos.y - p1.pos.y) + term3 * (p3.y - p2.pos.y)

        let v = CGPoint(x: x, y: y)
        let n = normalize(v)
        return n
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func normalize(_ v: CGPoint) -> CGPoint {
        let len = hypot(v.x, v.y)
        if len == 0 { return CGPoint.zero }
        return CGPoint(x: v.x / len, y: v.y / len)
    }
}

