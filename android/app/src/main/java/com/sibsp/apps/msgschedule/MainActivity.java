package com.sibsp.apps.msgschedule;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.accessibilityservice.AccessibilityService;
import android.content.Context;
import androidx.annotation.NonNull;
import com.sibsp.apps.msgschedule.*;
import android.provider.Settings;
//package WhatsappAccessibilityService;
import WhatsappAccessibilityService.WhatsappAccessibilityService;
import android.text.TextUtils;
public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "samples.flutter.dev/battery";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), CHANNEL)
            .setMethodCallHandler(
                    (call, result) -> {
                      if (call.method.equals("getBatteryLevel")) {
                        Context context = this;
                        if (!isAccessibilityOn (this, WhatsappAccessibilityService.class)) {
                          Intent intent = new Intent (Settings.ACTION_ACCESSIBILITY_SETTINGS);
                          context.startActivity (intent);
                        }

                      } else {
                        result.notImplemented();
                      }
                    }
            );
  }


  private boolean isAccessibilityOn (Context context, Class<? extends AccessibilityService> clazz) {
    int accessibilityEnabled = 0;
    final String service = context.getPackageName () + "/" + clazz.getCanonicalName ();
    System.out.println(service);
    try {
      accessibilityEnabled = Settings.Secure.getInt (context.getApplicationContext ().getContentResolver (), Settings.Secure.ACCESSIBILITY_ENABLED);
    } catch (Settings.SettingNotFoundException ignored) {  }

    TextUtils.SimpleStringSplitter colonSplitter = new TextUtils.SimpleStringSplitter(':');

    if (accessibilityEnabled == 1) {
      String settingValue = Settings.Secure.getString (context.getApplicationContext ().getContentResolver (), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
      if (settingValue != null) {
        colonSplitter.setString (settingValue);
        while (colonSplitter.hasNext ()) {
          String accessibilityService = colonSplitter.next ();

          if (accessibilityService.equalsIgnoreCase (service)) {
            return true;
          }
        }
      }
    }

    return false;
  }



}

