package studio.gduxi.app

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.drawable.Animatable
import android.graphics.Bitmap
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.ImageView
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.enableEdgeToEdge
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible

/**
 * The whole app is one screen: the live GDUXI Studio website (https://gduxi.studio)
 * shown full-screen, with a branded splash, the wave loader, an offline screen,
 * and outside links (Figma, LinkedIn, email) opening in the right app.
 *
 * Website changes show up in the app straight away. There is nothing to rebuild.
 */
class MainActivity : ComponentActivity() {

    private lateinit var webView: WebView
    private lateinit var loader: View
    private lateinit var loaderWave: ImageView
    private lateinit var offline: View

    /** Keeps the splash screen up only briefly; the wave loader takes over from it. */
    private var firstPageReady = false
    private val startedAt = SystemClock.uptimeMillis()

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        super.onCreate(savedInstanceState)
        splash.setKeepOnScreenCondition {
            !firstPageReady && SystemClock.uptimeMillis() - startedAt < 400
        }

        enableEdgeToEdge()
        setContentView(R.layout.activity_main)

        webView = findViewById(R.id.web)
        loader = findViewById(R.id.loader)
        loaderWave = findViewById(R.id.loader_wave)
        offline = findViewById(R.id.offline)
        findViewById<Button>(R.id.retry).setOnClickListener { retry() }

        // Keep content clear of the status bar, the navigation bar and the keyboard.
        val root = findViewById<View>(R.id.root)
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            val ime = insets.getInsets(WindowInsetsCompat.Type.ime())
            v.setPadding(bars.left, bars.top, bars.right, maxOf(bars.bottom, ime.bottom))
            WindowInsetsCompat.CONSUMED
        }

        with(webView.settings) {
            javaScriptEnabled = true          // the site's pages, menus and pop-ups need it
            domStorageEnabled = true          // remembers the light/dark choice
            cacheMode = WebSettings.LOAD_DEFAULT
            mediaPlaybackRequiresUserGesture = true
            setSupportZoom(false)
            userAgentString = "$userAgentString GDUXIApp/$APP_VERSION"
        }
        // The Figma prototypes inside the site's pop-ups need their own cookies.
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true)

        webView.webChromeClient = WebChromeClient()
        webView.webViewClient = SiteClient()

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (!offline.isVisible && webView.canGoBack()) {
                    webView.goBack()
                } else {
                    isEnabled = false
                    onBackPressedDispatcher.onBackPressed()
                }
            }
        })

        if (savedInstanceState != null && webView.restoreState(savedInstanceState) != null) {
            firstPageReady = true
        } else {
            openStart(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        openStart(intent)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        webView.saveState(outState)
    }

    override fun onResume() {
        super.onResume()
        webView.onResume()
    }

    override fun onPause() {
        webView.onPause()
        super.onPause()
    }

    override fun onStop() {
        super.onStop()
        // Holiday icon on/off by date; done in the background so it never interrupts the screen.
        runCatching { SeasonalIcon.apply(this) }
    }

    private fun openStart(intent: Intent?) {
        val link = intent?.data
        val url = if (link != null && isSiteLink(link)) link.toString() else HOME
        if (isOnline()) {
            showOffline(false)
            webView.loadUrl(url)
        } else {
            showOffline(true)
        }
    }

    private fun retry() {
        if (!isOnline()) return
        showOffline(false)
        if (webView.url.isNullOrEmpty() || webView.url == "about:blank") webView.loadUrl(HOME) else webView.reload()
    }

    private fun showOffline(show: Boolean) {
        offline.isVisible = show
        webView.isVisible = !show
        if (show) {
            showLoader(false)
            firstPageReady = true
        }
    }

    /**
     * The wave loader. With animations turned off on the phone (Settings > Accessibility
     * > Remove animations) it shows the still logo instead of moving.
     */
    private fun showLoader(show: Boolean) {
        if (show) {
            loader.animate().cancel()
            if (!loader.isVisible) {
                if (ValueAnimator.areAnimatorsEnabled()) {
                    loaderWave.setImageResource(R.drawable.wave_loader)
                    (loaderWave.drawable as? Animatable)?.start()
                } else {
                    loaderWave.setImageResource(R.drawable.splash_icon)
                }
            }
            loader.alpha = 1f
            loader.isVisible = true
        } else if (loader.isVisible) {
            loader.animate().alpha(0f).setDuration(250).withEndAction {
                loader.isVisible = false
                (loaderWave.drawable as? Animatable)?.stop()
            }.start()
        }
    }

    private fun isOnline(): Boolean {
        val cm = getSystemService(ConnectivityManager::class.java) ?: return true
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    /** gduxi.studio pages stay inside the app. Everything else opens outside. */
    private fun isSiteLink(uri: Uri): Boolean =
        (uri.scheme == "https" || uri.scheme == "http") &&
            uri.host?.lowercase()?.let { it in SITE_HOSTS } == true

    private fun openOutside(uri: Uri) {
        val intent = when (uri.scheme) {
            "mailto" -> Intent(Intent.ACTION_SENDTO, uri)
            else -> Intent(Intent.ACTION_VIEW, uri)
        }.addCategory(Intent.CATEGORY_BROWSABLE)
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            // No app on the phone can open this kind of link. Nothing to do.
        }
    }

    private inner class SiteClient : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            // Pages inside pop-ups (like the Figma prototypes) load in place.
            if (!request.isForMainFrame) return false
            val uri = request.url
            if (isSiteLink(uri)) return false   // stay in the app
            openOutside(uri)                     // Figma, LinkedIn, email, Gmail...
            return true
        }

        override fun onPageStarted(view: WebView, url: String?, favicon: Bitmap?) {
            showLoader(true)
        }

        // The page has drawn. The website shows the same wave until its content is in.
        override fun onPageCommitVisible(view: WebView, url: String?) {
            firstPageReady = true
            showLoader(false)
        }

        override fun onPageFinished(view: WebView, url: String?) {
            firstPageReady = true
            showLoader(false)
        }

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
            // Only the page itself failing counts; a missing image or font doesn't.
            if (request.isForMainFrame) showOffline(true)
        }
    }

    companion object {
        const val HOME = "https://gduxi.studio/"
        const val APP_VERSION = "1.0"
        val SITE_HOSTS = setOf("gduxi.studio", "www.gduxi.studio")
    }
}
