import UIKit

/// Switches the home-screen icon by date, so nobody has to rebuild or reinstall each season.
/// Holiday icon (Santa hat on the wave's dot, asset "AppIconHoliday") from Nov 24 to Jan 6,
/// the normal icon the rest of the year. Same window as SEASON in the website's index.html.
///
/// iOS always shows a short "You have changed the icon" note when an app swaps its icon;
/// that only happens on the two days a year the icon actually changes.
enum SeasonalIcon {
    private static let from = 1124   // month * 100 + day
    private static let to = 106
    private static let holidayIcon = "AppIconHoliday"

    static var isHoliday: Bool {
        let c = Calendar.current.dateComponents([.month, .day], from: Date())
        let k = (c.month ?? 1) * 100 + (c.day ?? 1)
        return from <= to ? (k >= from && k <= to) : (k >= from || k <= to)
    }

    static func apply() {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons, app.applicationState == .active else { return }
        let wanted: String? = isHoliday ? holidayIcon : nil
        guard app.alternateIconName != wanted else { return }
        app.setAlternateIconName(wanted) { _ in }
    }
}
