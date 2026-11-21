import UIKit

/// The wave loader: the logo mark whose white swoosh draws itself, the dot pops,
/// then the line flows away, on a 1.8 s loop. Same look and timing as the website
/// and Android loaders. Sits where the launch screen's logo sits (72 pt, centred),
/// so the launch screen hands over to it seamlessly.
/// With Reduce Motion on, it shows the still logo instead.
final class WaveLoaderView: UIView {

    private let mark = UIView()
    private let gradient = CAGradientLayer()
    private let swoosh = CAShapeLayer()
    private let dot = CAShapeLayer()
    private static let size: CGFloat = 72
    private static let duration: CFTimeInterval = 1.8

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(named: "Page") ?? .systemBackground
        isAccessibilityElement = true
        accessibilityLabel = "Loading"
        accessibilityTraits = .updatesFrequently

        let s = Self.size / 40   // the logo is drawn on a 40 x 40 grid
        mark.translatesAutoresizingMaskIntoConstraints = false
        mark.layer.cornerRadius = 12 * s
        mark.layer.cornerCurve = .continuous
        mark.clipsToBounds = true
        addSubview(mark)
        NSLayoutConstraint.activate([
            mark.centerXAnchor.constraint(equalTo: centerXAnchor),
            mark.centerYAnchor.constraint(equalTo: centerYAnchor),
            mark.widthAnchor.constraint(equalToConstant: Self.size),
            mark.heightAnchor.constraint(equalToConstant: Self.size),
        ])

        gradient.colors = [UIColor(rgb: 0x045FEA).cgColor, UIColor(rgb: 0x8549FF).cgColor, UIColor(rgb: 0xBB58FF).cgColor]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = CGRect(x: 0, y: 0, width: Self.size, height: Self.size)
        mark.layer.addSublayer(gradient)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 9 * s, y: 25.5 * s))
        path.addCurve(to: CGPoint(x: 19.5 * s, y: 18.5 * s),
                      controlPoint1: CGPoint(x: 12.5 * s, y: 13 * s), controlPoint2: CGPoint(x: 17 * s, y: 11.5 * s))
        path.addCurve(to: CGPoint(x: 31.5 * s, y: 14 * s),
                      controlPoint1: CGPoint(x: 21.5 * s, y: 24.5 * s), controlPoint2: CGPoint(x: 25 * s, y: 27.5 * s))
        swoosh.path = path.cgPath
        swoosh.fillColor = nil
        swoosh.strokeColor = UIColor.white.cgColor
        swoosh.lineWidth = 3.6 * s
        swoosh.lineCap = .round
        mark.layer.addSublayer(swoosh)

        let r = 2.6 * s
        dot.bounds = CGRect(x: 0, y: 0, width: r * 2, height: r * 2)
        dot.position = CGPoint(x: 31.5 * s, y: 14 * s)
        dot.path = UIBezierPath(ovalIn: dot.bounds).cgPath
        dot.fillColor = UIColor.white.cgColor
        mark.layer.addSublayer(dot)

        NotificationCenter.default.addObserver(self, selector: #selector(restart),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        // iOS drops running animations when the app goes to the background.
        NotificationCenter.default.addObserver(self, selector: #selector(restart),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restart()
    }

    override var isHidden: Bool {
        didSet { if isHidden != oldValue { restart() } }
    }

    /// Starts the loop, or shows the still logo when it is hidden or Reduce Motion is on.
    @objc private func restart() {
        swoosh.removeAllAnimations()
        dot.removeAllAnimations()
        guard window != nil, !isHidden, !UIAccessibility.isReduceMotionEnabled else { return }

        let ease = CAMediaTimingFunction(controlPoints: 0.65, 0, 0.35, 1)
        let linear = CAMediaTimingFunction(name: .linear)

        let end = CAKeyframeAnimation(keyPath: "strokeEnd")
        end.values = [0, 1, 1]
        end.keyTimes = [0, 0.46, 1]
        end.timingFunctions = [ease, linear]

        let start = CAKeyframeAnimation(keyPath: "strokeStart")
        start.values = [0, 0, 1]
        start.keyTimes = [0, 0.58, 1]
        start.timingFunctions = [linear, ease]

        let line = CAAnimationGroup()
        line.animations = [end, start]
        line.duration = Self.duration
        line.repeatCount = .infinity
        swoosh.add(line, forKey: "wave")

        let pop = CAKeyframeAnimation(keyPath: "transform.scale")
        pop.values = [0, 0, 1.3, 1, 1, 0, 0]
        pop.keyTimes = [0, 0.36, 0.46, 0.54, 0.84, 0.97, 1]
        pop.duration = Self.duration
        pop.repeatCount = .infinity
        dot.add(pop, forKey: "wave")
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
