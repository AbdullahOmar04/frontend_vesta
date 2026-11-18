package co.vestaapp.app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Opens Vesta's page in the phone's notification settings, for when
        // notifications were turned off and Android won't ask again
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "co.vestaapp.app/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNotificationSettings") {
                    startActivity(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    )
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
