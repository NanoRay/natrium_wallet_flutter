package co.banano.natriumwallet;

import android.os.Bundle;
import android.view.ViewTreeObserver;
import android.view.WindowManager;

import io.flutter.app.FlutterFragmentActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterMain;

public class MainActivity extends FlutterFragmentActivity {
  private static final String CHANNEL = "fappchannel";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    FlutterMain.startInitialization(this);
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    // make transparent status bar
    getWindow().setStatusBarColor(0x00000000);
    // Remove full screen flag after load
    ViewTreeObserver vto = getFlutterView().getViewTreeObserver();
    vto.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
      @Override
      public void onGlobalLayout() {
        getFlutterView().getViewTreeObserver().removeOnGlobalLayoutListener(this);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
      }
    });

    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
          new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                  if (call.method.equals("getLegacySeed")) {
                      result.success(new MigrationStuff().getLegacySeed());
                  } else if (call.method.equals("getLegacyContacts")) {
                      result.success(new MigrationStuff().getLegacyContactsAsJson());
                  } else if (call.method.equals("clearLegacyData")) {
                      new MigrationStuff().clearLegacyData();
                  } else if (call.method.equals("getLegacyPin")) {
                      result.success(new MigrationStuff().getLegacyPin());
                  } else if (call.method.equals("getSecret")) {
                      result.success(new LegacyStorage().getSecret());
                  } else {
                      result.notImplemented();
                  }
              }
          }
     );
  }
}
