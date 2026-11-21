import SwiftUI

/// The whole app is one screen: the live GDUXI Studio website (https://gduxi.studio)
/// shown full screen, with the wave loader, pull to refresh, an offline screen,
/// and outside links (Figma, LinkedIn, email) opening in the right app.
///
/// Website changes show up in the app straight away. There is nothing to rebuild.
@main
struct GDUXIStudioApp: App {
    var body: some Scene {
        WindowGroup {
            SiteView()
                .background(Color("Page"))
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct SiteView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SiteViewController { SiteViewController() }
    func updateUIViewController(_ controller: SiteViewController, context: Context) {}
}
