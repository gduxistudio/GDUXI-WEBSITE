package studio.gduxi.app

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import java.util.Calendar

/**
 * Switches the home-screen icon by date, so nobody has to rebuild or reinstall each season.
 * Holiday icon (Santa hat on the wave's dot) from Nov 24 to Jan 6, the normal icon the rest of the year.
 * Same window as SEASON in the website's index.html.
 *
 * The two icons are two launcher entries (activity-alias) in AndroidManifest.xml; only one is enabled.
 * Called when the app goes to the background, so the switch never interrupts what's on screen.
 */
object SeasonalIcon {
    private const val FROM = 1124   // month * 100 + day
    private const val TO = 106

    fun isHoliday(now: Calendar = Calendar.getInstance()): Boolean {
        val k = (now.get(Calendar.MONTH) + 1) * 100 + now.get(Calendar.DAY_OF_MONTH)
        return if (FROM <= TO) k in FROM..TO else k >= FROM || k <= TO
    }

    fun apply(context: Context) {
        val pm = context.packageManager
        val holiday = ComponentName(context, "${context.packageName}.LauncherHoliday")
        val normal = ComponentName(context, "${context.packageName}.LauncherDefault")
        val (on, off) = if (isHoliday()) holiday to normal else normal to holiday
        if (isEnabled(pm, on, defaultOn = on == normal) && !isEnabled(pm, off, defaultOn = off == normal)) return
        // Enable the new entry first, so there is never a moment without an icon.
        pm.setComponentEnabledSetting(on, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
        pm.setComponentEnabledSetting(off, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
    }

    private fun isEnabled(pm: PackageManager, c: ComponentName, defaultOn: Boolean): Boolean =
        when (pm.getComponentEnabledSetting(c)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> defaultOn
        }
}
