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
import com.sibsp.apps.msgschedule.R;
import android.provider.Settings;
import android.widget.Toast;
import android.util.Log;
import org.json.JSONObject;
import org.json.JSONException;
import android.net.Uri;
import java.io.File;
import androidx.core.content.FileProvider;
//package WhatsappAccessibilityService;
//import WhatsappAccessibilityService.WhatsappAccessibilityService;
import com.sibsp.apps.msgschedule.WhatsappAccessibilityService;

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
                      Log.d(CHANNEL, "onServiceConnected.");

//                      result.success(call.method);
//                      Toast.makeText(call.method.equals("getBatteryLevel"), "connectd", Toast.LENGTH_SHORT).show();

                      if(call.method.equals("checkAccessibility")) {
                        Context context1 = this;
                        if (!isAccessibilityOn (this, WhatsappAccessibilityService.class)) {
                          Intent intent = new Intent (Settings.ACTION_ACCESSIBILITY_SETTINGS);
                          context1.startActivity (intent);
                        }
                      }



                      if (call.method.equals("getBatteryLevel")) {
                        System.out.println("qwrtyuiop");
                        String endpoint = call.argument("endpoint").toString();
                        String content = call.argument("content").toString();
                        String attachment = call.argument("attachment").toString();
                        System.out.println(endpoint);
                        System.out.println(content);

                        Context context = this;
                        if (!isAccessibilityOn (this, WhatsappAccessibilityService.class)) {
                          Intent intent = new Intent (Settings.ACTION_ACCESSIBILITY_SETTINGS);
                            context.startActivity (intent);
//                          startActivity (intent);
                        }else{
                          try {
                            Thread.sleep (500); // hack for certain devices in which the immediate back click is too fast to handle
                          } catch (InterruptedException ignored) {}

                          Intent intent = new Intent(getApplicationContext(), WhatsappAccessibilityService.class);
                          intent.putExtra(String.valueOf(System.currentTimeMillis() / 1000L ), "does not matter");
                          context.startService(intent);
                          System.out.println("startedservice");

                          String toNumber = endpoint; //FormatStringAsPhoneNumber(endpoint.replace(" ", "")); // contains spaces.
                          toNumber = toNumber.replace("+", "").replace(" ", "");
                          Intent sendIntent = new Intent("android.intent.action.MAIN");
                          System.out.println(attachment);


                          sendIntent.putExtra("jid", toNumber + "@s.whatsapp.net");
                          sendIntent.putExtra(Intent.EXTRA_TEXT, content);
                          sendIntent.setAction(Intent.ACTION_SEND);
                          sendIntent.setPackage("com.whatsapp");
                          sendIntent.setType("text/plain");
                          if(attachment != null && attachment!= ""){
                            Uri uri = FileProvider.getUriForFile(MainActivity.this, BuildConfig.APPLICATION_ID + ".provider",new File(attachment));
                            sendIntent.putExtra(Intent.EXTRA_STREAM,  uri);//Uri.fromFile(new File(attachment)));
                            sendIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                            sendIntent.setType("image/jpg");

                          }
                          context.startActivity(sendIntent);

                          result.success("done");
                          System.out.println("here will trigger send");
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
    try {
      accessibilityEnabled = Settings.Secure.getInt (context.getApplicationContext ().getContentResolver (), Settings.Secure.ACCESSIBILITY_ENABLED);
    } catch (Settings.SettingNotFoundException ignored) {  }

    TextUtils.SimpleStringSplitter colonSplitter = new TextUtils.SimpleStringSplitter (':');

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

