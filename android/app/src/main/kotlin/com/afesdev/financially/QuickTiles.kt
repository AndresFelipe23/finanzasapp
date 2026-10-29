package com.afesdev.financially

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

// Mosaicos del panel de Ajustes rápidos (junto al Wi-Fi y la linterna). Al
// tocarlos se abre la hoja de registro rápido (QuickEntryActivity) encima de
// lo que se esté viendo, sin abrir la app completa.
abstract class QuickTile(private val tipo: String) : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            // Es una acción, no un interruptor: siempre se ve igual
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        // Con el teléfono bloqueado, primero se pide desbloquear
        if (isLocked) unlockAndRun { abrir() } else abrir()
    }

    private fun abrir() {
        val intent = Intent(this, QuickEntryActivity::class.java).apply {
            putExtra(QuickEntryActivity.EXTRA_TIPO, tipo)
            // CLEAR_TASK: si ya había una hoja abierta, empezar de cero con
            // el tipo de este mosaico (los argumentos de Dart solo se leen al
            // arrancar)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        if (Build.VERSION.SDK_INT >= 34) {
            // Android 14+ solo acepta un PendingIntent
            val pending = PendingIntent.getActivity(
                this,
                tipo.hashCode(),
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}

class GastoTileService : QuickTile("GASTO")

class IngresoTileService : QuickTile("INGRESO")
