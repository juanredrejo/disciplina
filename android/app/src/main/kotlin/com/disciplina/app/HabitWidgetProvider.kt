package com.disciplina.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de la pantalla de inicio: muestra los hábitos de hoy y permite
 * marcarlos con un toque (el toque ejecuta Dart en segundo plano vía
 * HomeWidgetBackgroundIntent → callback registrado en WidgetService).
 *
 * Los datos los escribe Flutter con HomeWidget.saveWidgetData (SharedPreferences
 * "HomeWidgetPreferences"): dateLabel, progress, habits (JSON).
 */
class HabitWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val dateLabel = widgetData.getString("dateLabel", null) ?: "Disciplina"
    val progress = widgetData.getString("progress", null) ?: ""
    val habitsJson = widgetData.getString("habits", null) ?: "[]"

    val habits = JSONArray(habitsJson)
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.widget_habits).apply {
            setTextViewText(R.id.widget_date, dateLabel)
            setTextViewText(R.id.widget_progress, progress)

            // Tocar la cabecera abre la app.
            val openApp =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_header, openApp)

            // Fila por hábito (máx. MAX_ROWS).
            for (i in 0 until MAX_ROWS) {
              val rowId = ROW_IDS[i]
              if (i < habits.length()) {
                val h = habits.getJSONObject(i)
                val id = h.optString("id")
                val name = h.optString("name")
                val emoji = h.optString("emoji", "✅")
                val done = h.optBoolean("done", false)

                setViewVisibility(rowId, View.VISIBLE)
                setTextViewText(EMOJI_IDS[i], emoji)
                setTextViewText(NAME_IDS[i], name)
                setTextViewText(CHECK_IDS[i], if (done) "✓" else "○")

                // Tocar la fila marca/desmarca el hábito (Dart en 2º plano).
                val uri = Uri.parse("disciplina://toggle?id=$id")
                setOnClickPendingIntent(
                    rowId,
                    HomeWidgetBackgroundIntent.getBroadcast(context, uri),
                )
              } else {
                setViewVisibility(rowId, View.GONE)
              }
            }
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  companion object {
    const val MAX_ROWS = 6

    val ROW_IDS =
        intArrayOf(
            R.id.habit_row_0,
            R.id.habit_row_1,
            R.id.habit_row_2,
            R.id.habit_row_3,
            R.id.habit_row_4,
            R.id.habit_row_5,
        )
    val EMOJI_IDS =
        intArrayOf(
            R.id.habit_emoji_0,
            R.id.habit_emoji_1,
            R.id.habit_emoji_2,
            R.id.habit_emoji_3,
            R.id.habit_emoji_4,
            R.id.habit_emoji_5,
        )
    val NAME_IDS =
        intArrayOf(
            R.id.habit_name_0,
            R.id.habit_name_1,
            R.id.habit_name_2,
            R.id.habit_name_3,
            R.id.habit_name_4,
            R.id.habit_name_5,
        )
    val CHECK_IDS =
        intArrayOf(
            R.id.habit_check_0,
            R.id.habit_check_1,
            R.id.habit_check_2,
            R.id.habit_check_3,
            R.id.habit_check_4,
            R.id.habit_check_5,
        )
  }
}
