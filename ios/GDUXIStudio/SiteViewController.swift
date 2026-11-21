import UIKit
import WebKit
import Network

final class SiteViewController: UIViewController {

    static let home = URL(string: "https://gduxi.studio/")!
    static let siteHosts: Set<String> = ["gduxi.studio", "www.gduxi.studio"]
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

    private var webView: WKWebView!
    private let progress = UIProgressView(progressViewStyle: .bar)
    private let offline = OfflineView()
    private let refresh = UIRefreshControl()
    private let monitor = NWPathMonitor()
    private var isOnline = true
    private var progressObserver: NSKeyValueObservation?

    private let page = UIColor(named: "Page") ?? .systemBackground
    private let purple = UIColor(named: "AccentColor") ?? .systemPurple

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

        progress.progressTintColor = purple
        progress.trackTintColor = .clear
        progress.isHidden = true

        offline.isHidden = true
        offline.retry.addTarget(self, action: #selector(retry), for: .touchUpInside)

        for v in [webView!, progress, offline] as [UIView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safe.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progress.topAnchor.constraint(equalTo: safe.topAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progress.heightAnchor.constraint(equalToConstant: 3),
            offline.topAnchor.constraint(equalTo: view.topAnchor),
            offline.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offline.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offline.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] web, _ in
            guard let self else { return }
            let value = Float(web.estimatedProgress)
            self.progress.setProgress(value, animated: value > self.progress.progress)
            self.progress.isHidden = value >= 1
        }

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
        if show { progress.isHidden = true }
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
        progress.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refresh.endRefreshing()
        progress.isHidden = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        refresh.endRefreshing()
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
