package com.example.project_thera

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout).apply {
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Set currently reading book title
                val title = widgetData.getString("currently_reading_title", null)
                    ?: "No book in progress"
                setTextViewText(R.id.widget_title, title)

                // Set author
                val author = widgetData.getString("currently_reading_author", null) ?: ""
                setTextViewText(R.id.widget_author, author)

                // Set progress
                val currentPage = widgetData.getInt("currently_reading_current_page", 0)
                val totalPages = widgetData.getInt("currently_reading_total_pages", 0)
                if (totalPages > 0) {
                    val progressText = "Page $currentPage / $totalPages"
                    setTextViewText(R.id.widget_progress, progressText)
                    setViewVisibility(R.id.widget_progress, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_progress, View.GONE)
                }

                // Set streak
                val streak = widgetData.getInt("streak_count", 0)
                val streakText = if (streak > 0) {
                    "$streak day${if (streak != 1) "s" else ""} streak"
                } else {
                    "No streak"
                }
                setTextViewText(R.id.widget_streak, streakText)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
