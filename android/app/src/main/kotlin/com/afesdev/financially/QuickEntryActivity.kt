package com.afesdev.financially

import android.content.Intent
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Hoja de registro rápido que abren los mosaicos de Ajustes rápidos. Es una
// actividad transparente, aparte de la app (su propia tarea, fuera de
// recientes), que arranca Flutter en `quickEntryMain` (main.dart) en vez de
// la app completa. Fragment porque local_auth lo necesita para la huella.
class QuickEntryActivity : FlutterFragmentActivity() {

    companion object {
        const val EXTRA_TIPO = "tipo" // "GASTO" o "INGRESO"
    }

    override fun getDartEntrypointFunctionName() = "quickEntryMain"

    override fun getDartEntrypointArgs() =
        listOf(intent?.getStringExtra(EXTRA_TIPO) ?: "GASTO")

    // Se ve lo que había detrás, oscurecido
    override fun getBackgroundMode() = BackgroundMode.transparent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Flutter deja la ventana transparente; se oscurece desde ya para que
        // el toque se note mientras arranca el motor (casi un segundo en frío).
        // La hoja de Flutter no pone su propia sombra encima de esta.
        window.setBackgroundDrawable(ColorDrawable(0x73000000))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "financially/quick_entry")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Sin sesión: abrir la app completa para iniciarla
                    "abrirApp" -> {
                        packageManager.getLaunchIntentForPackage(packageName)?.let {
                            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(it)
                        }
                        finish()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Sin animación de ventana: la hoja anima su propia entrada
    override fun finish() {
        super.finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }
}
