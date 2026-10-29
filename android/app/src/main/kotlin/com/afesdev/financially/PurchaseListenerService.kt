package com.afesdev.financially

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Registro automático de compras: con el permiso "Acceso a notificaciones"
 * (Perfil → Registrar compras automáticamente), mira las notificaciones de
 * pago (Google Wallet, apps de bancos) y le pasa a Dart (`compraDetectadaMain`
 * en main.dart) solo las que parecen una compra. El resto se ignora aquí
 * mismo: nada se guarda ni sale del teléfono.
 */
class PurchaseListenerService : NotificationListenerService() {

    companion object {
        // Apps de mensajería y correo: sus textos pueden traer montos que no
        // son compras ("te debo $20.000")
        private val IGNORADAS = setOf(
            "com.whatsapp", "com.whatsapp.w4b", "org.telegram.messenger",
            "com.google.android.apps.messaging", "com.android.mms",
            "com.samsung.android.messaging", "com.google.android.gm",
            "com.microsoft.office.outlook", "com.facebook.orca",
            "com.instagram.android", "com.android.systemui",
        )

        // Monto con símbolo o código de moneda: "$85.000", "COP 85,000.00"
        private val MONTO = Regex("""(?:\$|COP|USD|MXN|US\$)\s?\d[\d.,]*""", RegexOption.IGNORE_CASE)

        // Verbos de una compra o un pago ya hecho (no de una promoción)
        private val COMPRA = Regex(
            """compr(a|aste|ó)|pag(aste|o|ó)|transacci[oó]n|aprobad|d[eé]bito|cargo|consumo|purchase|paid""",
            RegexOption.IGNORE_CASE,
        )
        // Dinero que entra ("Recibiste $50.000 de…"): Dart decide si se
        // registra como ingreso (puede estar apagado en Perfil)
        private val INGRESO = Regex(
            """recib|te (envi|transfir|consign)|abono|consign|dep[oó]sit|reembols|devoluci|te lleg""",
            RegexOption.IGNORE_CASE,
        )
        private val PROMO = Regex("""descuento|oferta|promo|\d+\s?%|gana|cup[oó]n""", RegexOption.IGNORE_CASE)

        // Mismo monto avisado por varias apps (Wallet y el banco): se pasa
        // una sola vez a Dart, que además revisa duplicados contra la cuenta
        private val recientes = mutableMapOf<String, Long>()
        private const val VENTANA_MS = 10 * 60 * 1000L
    }

    private val main = Handler(Looper.getMainLooper())

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName || sbn.packageName in IGNORADAS) return
        if (sbn.isOngoing) return
        val extras = sbn.notification.extras ?: return
        val titulo = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val texto = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        val todo = "$titulo $texto"

        val monto = MONTO.find(todo)?.value ?: return
        if (!COMPRA.containsMatchIn(todo) &&
            !INGRESO.containsMatchIn(todo) &&
            !esBilletera(sbn.packageName)
        ) return
        if (PROMO.containsMatchIn(todo)) return

        val clave = monto.filter { it.isDigit() }
        val ahora = System.currentTimeMillis()
        synchronized(recientes) {
            recientes.entries.removeAll { ahora - it.value > VENTANA_MS }
            if (recientes.containsKey(clave)) return
            recientes[clave] = ahora
        }

        main.post { procesar(sbn.packageName, titulo, texto, sbn.postTime) }
    }

    // Google Wallet y Samsung Wallet avisan el pago sin decir "compra"
    private fun esBilletera(pkg: String) =
        pkg == "com.google.android.apps.walletnfcrel" || pkg == "com.samsung.android.spay"

    /** Arranca un motor de Flutter sin pantalla que registra la compra. */
    private fun procesar(pkg: String, titulo: String, texto: String, cuando: Long) {
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val engine = FlutterEngine(applicationContext)
            var terminado = false
            val cerrar = Runnable {
                if (!terminado) {
                    terminado = true
                    engine.destroy()
                }
            }
            MethodChannel(engine.dartExecutor.binaryMessenger, "financially/compras")
                .setMethodCallHandler { call, result ->
                    if (call.method == "terminado") {
                        result.success(null)
                        main.post(cerrar)
                    } else {
                        result.notImplemented()
                    }
                }
            // Por si Dart no avisa (sin red, error): se libera igual
            main.postDelayed(cerrar, 90_000)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "compraDetectadaMain"),
                listOf(pkg, titulo, texto, cuando.toString()),
            )
        } catch (e: Exception) {
            android.util.Log.e("Financially", "Compra no procesada", e)
        }
    }
}
