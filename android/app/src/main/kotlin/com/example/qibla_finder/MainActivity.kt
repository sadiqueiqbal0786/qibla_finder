package com.example.qibla_finder

import android.app.AlertDialog
import android.os.Bundle
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val updates by lazy { AppUpdateManagerFactory.create(this) }
    private var checking = false
    private var restartDialog: AlertDialog? = null
    private val listener = InstallStateUpdatedListener { state ->
        if (state.installStatus() == InstallStatus.DOWNLOADED) offerRestart()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updates.registerListener(listener)
    }

    override fun onResume() {
        super.onResume()
        if (checking) return
        checking = true
        updates.appUpdateInfo.addOnSuccessListener { info ->
            checking = false
            if (isFinishing || isDestroyed) return@addOnSuccessListener
            if (info.installStatus() == InstallStatus.DOWNLOADED) {
                offerRestart()
            } else if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE) &&
                info.installStatus() != InstallStatus.DOWNLOADING &&
                info.installStatus() != InstallStatus.PENDING) {
                val prefs = getSharedPreferences("app_updates", MODE_PRIVATE)
                val now = System.currentTimeMillis()
                val last = prefs.getLong("prompted_at", 0)
                val newVersion = prefs.getInt("version", -1) != info.availableVersionCode()
                if (newVersion || now - last >= 24 * 60 * 60 * 1000L) {
                    try {
                        val started = updates.startUpdateFlowForResult(
                            info, this,
                            AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(), 8120
                        )
                        if (started) prefs.edit().putLong("prompted_at", now)
                            .putInt("version", info.availableVersionCode()).apply()
                    } catch (error: Exception) {
                        Log.d("AppUpdate", "Update flow unavailable", error)
                    }
                }
            }
        }.addOnFailureListener { error ->
            checking = false
            Log.d("AppUpdate", "Update check unavailable", error)
        }
    }

    private fun offerRestart() {
        if (isFinishing || isDestroyed || restartDialog != null) return
        restartDialog = AlertDialog.Builder(this)
            .setTitle("Update ready")
            .setMessage("Restart Qibla Finder to finish installing the update.")
            .setPositiveButton("Restart") { _, _ ->
                updates.completeUpdate().addOnFailureListener { error ->
                    Log.d("AppUpdate", "Could not complete update", error)
                }
            }
            .setNegativeButton("Later", null)
            .create().also { dialog ->
                dialog.setOnDismissListener { restartDialog = null }
                dialog.show()
            }
    }

    override fun onDestroy() {
        updates.unregisterListener(listener)
        restartDialog?.dismiss()
        super.onDestroy()
    }
}
