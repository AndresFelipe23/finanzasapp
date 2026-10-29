package com.afesdev.financially

import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth necesita FlutterFragmentActivity para mostrar el diálogo biométrico
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Perfil → "Agregar a Ajustes rápidos": el sistema pregunta si se
        // agrega el mosaico (Android 13+); antes solo se agrega a mano
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "financially/tiles")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "soportado" -> result.success(Build.VERSION.SDK_INT >= 33)
                    "agregar" -> {
                        if (Build.VERSION.SDK_INT < 33) {
                            result.success(-1)
                            return@setMethodCallHandler
                        }
                        val ingreso = call.argument<String>("tipo") == "INGRESO"
                        val servicio = if (ingreso) IngresoTileService::class.java else GastoTileService::class.java
                        val icono = if (ingreso) R.drawable.ic_tile_ingreso else R.drawable.ic_tile_gasto
                        getSystemService(StatusBarManager::class.java).requestAddTileService(
                            ComponentName(this, servicio),
                            if (ingreso) "Nuevo ingreso" else "Nuevo gasto",
                            Icon.createWithResource(this, icono),
                            mainExecutor,
                        ) { codigo -> result.success(codigo) }
                    }
                    else -> result.notImplemented()
                }
            }

        // Perfil → "Registrar compras automáticamente": el permiso de leer
        // notificaciones solo se da en los ajustes del sistema
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "financially/compras_ajustes")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tieneAcceso" -> result.success(
                        Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                            ?.split(':')
                            ?.any { it.startsWith("$packageName/") } == true,
                    )
                    "abrirAjuste" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
