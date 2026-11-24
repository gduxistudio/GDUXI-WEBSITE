import UIKit
import WebKit
import Network

final class SiteViewController: UIViewController {

    static let home = URL(string: "https://gduxi.studio/")!
    static let siteHosts: Set<String> = ["gduxi.studio", "www.gduxi.studio"]
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

    private var webView: WKWebView!
    private let loader = WaveLoaderView()
    private let offline = OfflineView()
    private let refresh = UIRefreshControl()
    private let monitor = NWPathMonitor()
    private var isOnline = true

    private let page = UIColor(named: "Page") ?? .systemBackground
    private let purple = UIColor(named: "AccentColor") ?? .systemPurple

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Holiday icon on/off by date, a moment after the app is on screen (iOS needs it active).
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { SeasonalIcon.apply() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = page

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.applicationNameForUserAgent = "Mobile/15E148 Safari/604.1 GDUXIApp/\(Self.appVersion)"
        config.websiteDataStore = .default()   // remembers the light/dark choice

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true   // swipe from the edge to go back
        webView.isOpaque = false
        webView.backgroundColor = page
        webView.scrollView.backgroundColor = page
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        refresh.tintColor = purple
        refresh.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refresh

        loader.isHidden = false   // covers the blank page until the site has drawn

        offline.isHidden = true
        offline.retry.addTarget(self, action: #selector(retry), for: .touchUpInside)

        for v in [webView!, loader, offline] as [UIView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safe.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loader.topAnchor.constraint(equalTo: view.topAnchor),
            loader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loader.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            offline.topAnchor.constraint(equalTo: view.topAnchor),
            offline.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offline.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offline.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isOnline = path.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "gduxi.network"))

        webView.load(URLRequest(url: Self.home))
    }

    deinit { monitor.cancel() }

    // MARK: - Actions

    @objc private func pulledToRefresh() {
        if webView.url == nil { webView.load(URLRequest(url: Self.home)) } else { webView.reload() }
    }

    @objc private func retry() {
        showOffline(false)
        if webView.url == nil || webView.url?.absoluteString == "about:blank" {
            webView.load(URLRequest(url: Self.home))
        } else {
            webView.reload()
        }
    }

    private func showOffline(_ show: Bool) {
        offline.isHidden = !show
        webView.isHidden = show
        if show { showLoader(false) }
    }

    /// The wave loader covers the page while it loads; the website then shows the same wave
    /// until its content is in, so the hand-over is seamless.
    private func showLoader(_ show: Bool) {
        if show {
            loader.layer.removeAllAnimations()
            loader.alpha = 1
            loader.isHidden = false
        } else if !loader.isHidden {
            UIView.animate(withDuration: 0.25, animations: { self.loader.alpha = 0 }) { done in
                if done { self.loader.isHidden = true }
            }
        }
    }

    // MARK: - Links

    /// gduxi.studio pages stay inside the app. Everything else opens outside.
    static func isSiteLink(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return false }
        return siteHosts.contains(host)
    }

    private func openOutside(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              ["http", "https", "mailto", "tel"].contains(scheme) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Navigation

extension SiteViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { return decisionHandler(.cancel) }
        let scheme = url.scheme?.lowercased() ?? ""

        // Inner page loads and pop-up frames (like the Figma prototypes) load in place.
        if scheme == "about" || scheme == "blob" || scheme == "data" { return decisionHandler(.allow) }
        if let frame = action.targetFrame, !frame.isMainFrame { return decisionHandler(.allow) }

        if Self.isSiteLink(url) { return decisionHandler(.allow) }   // stay in the app
        openOutside(url)                                             // Figma, LinkedIn, email, Gmail...
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Pull to refresh already shows its own spinner.
        if !refresh.isRefreshing { showLoader(true) }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        showLoader(false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refresh.endRefreshing()
        showLoader(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        refresh.endRefreshing()
        showLoader(false)
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }   // a link we sent outside
        if ns.domain == "WebKitErrorDomain" && ns.code == 102 { return }                 // frame load interrupted
        if ns.domain == NSURLErrorDomain || !isOnline { showOffline(true) }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

// MARK: - Links that open a new window (target="_blank")

extension SiteViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url {
            if Self.isSiteLink(url) { webView.load(action.request) } else { openOutside(url) }
        }
        return nil
    }
}
