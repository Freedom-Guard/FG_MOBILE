package com.freedom.guard

import android.content.Context
import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.content.IntentFilter
import android.content.BroadcastReceiver

class VpnTileService : TileService() {
    private val CHANNEL = "vpn_quick_tile"

    override fun onStartListening() {
        super.onStartListening()
        val prefs = getSharedPreferences("vpn_tile", Context.MODE_PRIVATE)
        val isOn = prefs.getBoolean("vpn_state", false)
        updateTile(isOn)
    }

    override fun onClick() {
        super.onClick()
        val prefs = getSharedPreferences("vpn_tile", Context.MODE_PRIVATE)
        val isOn = !prefs.getBoolean("vpn_state", false)
        prefs.edit().putBoolean("vpn_state", isOn).apply()
        qsTile.state = if (isOn) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        qsTile.updateTile()
        val intent = Intent("com.freedom.guard.VPN_TILE_TOGGLE")
        intent.putExtra("vpn_state", isOn)
        sendBroadcast(intent)

    }

    private fun updateTile(isOn: Boolean) {
        qsTile.label = if (isOn) "VPN ON" else "VPN OFF"
        qsTile.state = if (isOn) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE // Corrected state
        qsTile.updateTile()
    }

}