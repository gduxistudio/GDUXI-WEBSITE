import UIKit

/// Shown when there is no internet. Matches the Android app's offline screen.
final class OfflineView: UIView {

    let retry = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(named: "Page") ?? .systemBackground

        let ink = UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: 0xF2EFFA) : UIColor(rgb: 0x1D1933) }
        let muted = UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: 0xB2ABCA) : UIColor(rgb: 0x5E5874) }

        let mark = UIImageView(image: UIImage(named: "LogoMark"))
        mark.contentMode = .scaleAspectFit
        mark.isAccessibilityElement = false
        mark.widthAnchor.constraint(equalToConstant: 72).isActive = true
        mark.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let title = UILabel()
        title.text = "You're offline"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = ink
        title.textAlignment = .center
        title.accessibilityTraits = .header

        let body = UILabel()
        body.text = "Connect to Wi-Fi or mobile data, then try again to see our work."
        body.font = .systemFont(ofSize: 16)
        body.textColor = muted
        body.textAlignment = .center
        body.numberOfLines = 0

        var cfg = UIButton.Configuration.filled()
        cfg.title = "Try again"
        cfg.baseBackgroundColor = UIColor(rgb: 0xFFBE2E)
        cfg.baseForegroundColor = UIColor(rgb: 0x1D1933)
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 28, bottom: 15, trailing: 28)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var a = $0; a.font = .systemFont(ofSize: 15, weight: .bold); return a
        }
        retry.configuration = cfg

        let copyright = UILabel()
        copyright.text = "© 2026 GDUXI Studio. All rights reserved."
        copyright.font = .systemFont(ofSize: 13)
        copyright.textColor = muted
        copyright.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [mark, title, body, retry, copyright])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(24, after: mark)
        stack.setCustomSpacing(28, after: body)
        stack.setCustomSpacing(40, after: retry)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}
