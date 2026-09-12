package com.example.qibla_finder

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.Date
import java.util.TimeZone

/**
 * The launcher face of the app.
 *
 * It reads the same 30-day schedule the reminders are built from, so it keeps
 * working with no network and no running Dart isolate, and it re-arms itself
 * for the exact moment the next prayer begins rather than waiting out the
 * 30-minute system update period.
 */
class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH || intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_TIME_CHANGED || intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            val manager = AppWidgetManager.getInstance(context)
            onUpdate(context, manager, manager.getAppWidgetIds(ComponentName(context, javaClass)))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, manager, id, options)
        onUpdate(context, manager, intArrayOf(id))
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        if (ids.isEmpty()) return
        val entries = try { JSONArray(data.getString("prayer_entries", "[]")) } catch (_: Exception) { JSONArray() }
        val all = (0 until entries.length()).map { entries.getJSONObject(it) }.sortedBy { it.optLong("at") }
        val now = System.currentTimeMillis()
        val upcoming = all.filter { it.optLong("at") > now }
        val next = upcoming.firstOrNull()
        val previous = all.lastOrNull { it.optLong("at") <= now }
        val language = data.getString("widget_language", "en") ?: "en"
        val locale = Locale.forLanguageTag(language)
        val zone = data.getString("prayer_zone", "") ?: ""
        val formatter = SimpleDateFormat(
            if (android.text.format.DateFormat.is24HourFormat(context)) "HH:mm" else "h:mm a", locale)
        if (zone.isNotEmpty()) formatter.timeZone = TimeZone.getTimeZone(zone)

        for (id in ids) {
            val view = RemoteViews(context.packageName, R.layout.prayer_widget)
            view.setInt(R.id.widget_root, "setLayoutDirection",
                if (language == "ur") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
            view.setTextViewText(R.id.widget_title, data.getString("widget_title", "Next prayer"))
            view.setTextViewText(R.id.widget_place, data.getString("prayer_place", ""))
            view.setContentDescription(R.id.widget_refresh,
                data.getString("widget_refresh_label", "Refresh"))

            val bearing = data.getString("qibla_bearing", "") ?: ""
            if (bearing.isEmpty()) {
                view.setViewVisibility(R.id.widget_qibla, View.GONE)
                view.setViewVisibility(R.id.widget_qibla_icon, View.GONE)
            } else {
                view.setViewVisibility(R.id.widget_qibla, View.VISIBLE)
                view.setViewVisibility(R.id.widget_qibla_icon, View.VISIBLE)
                view.setTextViewText(R.id.widget_qibla, "$bearing°")
                view.setContentDescription(R.id.widget_qibla,
                    "${data.getString("widget_qibla_label", "Qibla")} $bearing°")
            }

            view.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
            view.setOnClickPendingIntent(R.id.widget_refresh, refreshIntent(context))

            if (next == null) {
                view.setTextViewText(R.id.widget_prayer,
                    data.getString("widget_empty", "Open Qibla Finder to set your location"))
                view.setTextViewText(R.id.widget_time, "")
                view.setViewVisibility(R.id.widget_progress, View.GONE)
                view.setViewVisibility(R.id.widget_countdown_row, View.GONE)
                view.setViewVisibility(R.id.widget_upcoming, View.GONE)
            } else {
                val at = next.optLong("at")
                view.setTextViewText(R.id.widget_prayer, next.optString("name"))
                view.setTextViewText(R.id.widget_time, formatter.format(Date(at)))
                view.setViewVisibility(R.id.widget_countdown_row, View.VISIBLE)
                view.setChronometerCountDown(R.id.widget_countdown, true)
                view.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime() + at - now, null, true)

                // How far through the gap between the prayer that has started
                // and the one coming, so a glance reads "nearly there".
                val from = previous?.optLong("at")
                if (from != null && at > from) {
                    view.setViewVisibility(R.id.widget_progress, View.VISIBLE)
                    view.setProgressBar(R.id.widget_progress, 1000,
                        (((now - from).toDouble() / (at - from)) * 1000).toInt().coerceIn(0, 1000), false)
                } else {
                    view.setViewVisibility(R.id.widget_progress, View.GONE)
                }
                if (previous == null) {
                    view.setViewVisibility(R.id.widget_now, View.GONE)
                } else {
                    view.setViewVisibility(R.id.widget_now, View.VISIBLE)
                    view.setTextViewText(R.id.widget_now,
                        "${data.getString("widget_now_label", "Now")} · ${previous.optString("name")}")
                }
                fillUpcoming(view, upcoming.drop(1), formatter)
            }

            applySize(view, manager.getAppWidgetOptions(id), next != null)
            manager.updateAppWidget(id, view)
        }
        next?.let { schedule(context, it.optLong("at") + 1000) }
    }

    private fun fillUpcoming(view: RemoteViews, later: List<JSONObject>, formatter: SimpleDateFormat) {
        val slots = listOf(
            Triple(R.id.widget_up1, R.id.widget_up1_name, R.id.widget_up1_time),
            Triple(R.id.widget_up2, R.id.widget_up2_name, R.id.widget_up2_time),
            Triple(R.id.widget_up3, R.id.widget_up3_name, R.id.widget_up3_time))
        slots.forEachIndexed { index, (container, name, time) ->
            val entry = later.getOrNull(index)
            if (entry == null) {
                view.setViewVisibility(container, View.INVISIBLE)
            } else {
                view.setViewVisibility(container, View.VISIBLE)
                view.setTextViewText(name, entry.optString("name"))
                view.setTextViewText(time, formatter.format(Date(entry.optLong("at"))))
            }
        }
    }

    /**
     * Drops rows the widget is too short to show.
     *
     * A two-cell-tall widget only has room for the headline and countdown;
     * forcing the rest in clips them mid-glyph.
     */
    private fun applySize(view: RemoteViews, options: Bundle, hasNext: Boolean) {
        // MIN_HEIGHT is the height in the *shorter* orientation, so sizing
        // against it is what stops the rows clipping in landscape. Measured on
        // a 560dpi phone: a two-row placement reports 136dp and a three-row
        // one 210dp. The core block needs ~106dp, the footer another ~24dp and
        // the upcoming row another ~44dp. A missing Bundle means the picker
        // preview, which should show the design whole, so it falls back to the
        // target size.
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            .let { if (it <= 0) TARGET_HEIGHT_DP else it }
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            .let { if (it <= 0) TARGET_WIDTH_DP else it }
        val roomForFooter = height >= 128
        val roomForUpcoming = hasNext && height >= 172 && width >= 220
        view.setViewVisibility(R.id.widget_upcoming, if (roomForUpcoming) View.VISIBLE else View.GONE)
        view.setViewVisibility(R.id.widget_footer, if (roomForFooter) View.VISIBLE else View.GONE)
    }

    private fun launchIntent(context: Context): PendingIntent = PendingIntent.getActivity(
        context, 501,
        Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 502, Intent(context, PrayerWidgetProvider::class.java).setAction(ACTION_REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun schedule(context: Context, at: Long) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC, at, refreshIntent(context))
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC, at, refreshIntent(context))
            }
        } catch (_: SecurityException) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC, at, refreshIntent(context))
        }
    }

    override fun onDisabled(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(refreshIntent(context))
        super.onDisabled(context)
    }

    companion object {
        private const val ACTION_REFRESH = "com.qibla_finder.WIDGET_REFRESH"
        private const val TARGET_WIDTH_DP = 250
        private const val TARGET_HEIGHT_DP = 190
    }
}
