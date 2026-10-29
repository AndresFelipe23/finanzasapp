package com.afesdev.financially

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// Widget de la pantalla de inicio. Los textos los guarda la app con
// HomeWidgetSync (Dart); los botones abren la app en el formulario indicado.
class FinanciallyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        fun abrir(destino: String?) = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            destino?.let { Uri.parse("financially://$it") },
        )

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.financially_widget).apply {
                setTextViewText(R.id.widget_mes, widgetData.getString("mes", "Abre la app"))
                setTextViewText(R.id.widget_gastado, widgetData.getString("gastado", "—"))
                setTextViewText(R.id.widget_ingresos, widgetData.getString("ingresos", "—"))
                setOnClickPendingIntent(R.id.widget_root, abrir(null))
                setOnClickPendingIntent(R.id.widget_btn_gasto, abrir("gasto"))
                setOnClickPendingIntent(R.id.widget_btn_ingreso, abrir("ingreso"))
                setOnClickPendingIntent(R.id.widget_btn_transfer, abrir("transferencia"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
