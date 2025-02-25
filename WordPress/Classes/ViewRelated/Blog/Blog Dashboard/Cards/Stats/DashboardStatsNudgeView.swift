import UIKit

final class DashboardStatsNudgeView: UIView {

    var onTap: (() -> Void)? {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
            addGestureRecognizer(tapGesture)
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.subheadline)
        label.textColor = .textSubtle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    // MARK: - Init

    convenience init(title: String, hint: String) {
        self.init(frame: .zero)

        setTitle(title: title, hint: hint)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - View setup

    private func setup() {
        addSubview(titleLabel)
        pinSubviewToAllEdges(titleLabel, insets: Constants.margins)

        prepareForVoiceOver()
    }

    @objc private func buttonTapped() {
        onTap?()
    }

    private func setTitle(title: String, hint: String) {
        let externalAttachment = NSTextAttachment(image: UIImage.gridicon(.external, size: Constants.iconSize).withTintColor(.primary))
        externalAttachment.bounds = Constants.iconBounds

        let attachmentString = NSAttributedString(attachment: externalAttachment)

        let titleString = NSMutableAttributedString(string: "\(title) \u{FEFF}")
        if let subStringRange = title.nsRange(of: hint) {
            titleString.addAttributes([
                .foregroundColor: UIColor.primary,
                .font: WPStyleGuide.fontForTextStyle(.subheadline).bold()
            ], range: subStringRange)
        }

        titleString.append(attachmentString)

        titleLabel.attributedText = titleString
    }

    private enum Constants {
        static let iconSize = CGSize(width: 16, height: 16)
        static let iconBounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        static let margins = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }

}

extension DashboardStatsNudgeView: Accessible {

    func prepareForVoiceOver() {
        isAccessibilityElement = false
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .button
    }
}
