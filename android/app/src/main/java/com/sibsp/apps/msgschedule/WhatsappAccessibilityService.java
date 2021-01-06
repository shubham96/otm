package com.sibsp.apps.msgschedule;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;

import androidx.core.view.accessibility.AccessibilityNodeInfoCompat;

import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.os.Bundle;
import java.util.List;
import android.content.Intent;


public class WhatsappAccessibilityService extends AccessibilityService {
    private static String TAG = String.valueOf(System.currentTimeMillis() - 5000);

    @Override
    protected void onServiceConnected() {
        System.out.println("1234567890");
        super.onServiceConnected();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        super.onStartCommand(intent, flags, startId);
        String data="";
        System.out.println("abcdef");
        System.out.println(intent.getExtras().containsKey(String.valueOf(System.currentTimeMillis() / 1000L )));
//        System.out.println(intent.getStringExtra(String.valueOf(System.currentTimeMillis() / 1000L )));
//        TAG = intent.getStringExtra("data");
        if(intent.getExtras().containsKey(String.valueOf(System.currentTimeMillis() / 1000L )))
            TAG = String.valueOf(System.currentTimeMillis());
        return START_STICKY;
    }

    @Override
    public void onAccessibilityEvent (AccessibilityEvent event) {
        System.out.println("1234567890");
        if (getRootInActiveWindow () == null) {
            return;
        }

        AccessibilityNodeInfoCompat rootInActiveWindow = AccessibilityNodeInfoCompat.wrap (getRootInActiveWindow ());
        System.out.println("0");
        System.out.println(event.toString());

        // Whatsapp Message EditText id
        //might need to uncomment below shit
//        List<AccessibilityNodeInfoCompat> messageNodeList = rootInActiveWindow.findAccessibilityNodeInfosByViewId ("com.whatsapp:id/entry");
//        System.out.println(messageNodeList.toString());
//        if (messageNodeList == null || messageNodeList.isEmpty ()) {
//            return;
//        }
//        if(TAG=='yourData')
        System.out.println("1");
//        long epochtime = System.currentTimeMillis();
        System.out.println(TAG);

        long triggerTime = Long.parseLong(TAG);
        System.out.println(triggerTime);
        System.out.println(String.valueOf(System.currentTimeMillis()));

        if(!((System.currentTimeMillis() - triggerTime) < 10000 )){
            return;
        }

        // check if the whatsapp message EditText field is filled with text and ending with your suffix (explanation above)
//        AccessibilityNodeInfoCompat messageField = messageNodeList.get (0);
//        if (messageField.getText () == null || messageField.getText ().length () == 0
//                || !messageField.getText ().toString ().endsWith (getApplicationContext ().getString (R.string.whatsapp_suffix))) { // So your service doesn't process any message, but the ones ending your apps suffix
//            return;
//        }

        // Whatsapp send button id
        try {
            Thread.sleep (1000); // hack for certain devices in which the immediate back click is too fast to handle
        } catch (InterruptedException ignored) {}
        List<AccessibilityNodeInfoCompat> sendMessageNodeInfoList = rootInActiveWindow.findAccessibilityNodeInfosByViewId ("com.whatsapp:id/send");
        if (sendMessageNodeInfoList == null || sendMessageNodeInfoList.isEmpty ()) {
            return;
        }
        System.out.println("2");

        AccessibilityNodeInfoCompat sendMessageButton = sendMessageNodeInfoList.get (0);
        if (!sendMessageButton.isVisibleToUser ()) {
            return;
        }
        System.out.println("3");

        System.out.println(sendMessageButton);


        // Now fire a click on the send button
        sendMessageButton.performAction (AccessibilityNodeInfo.ACTION_CLICK);

        // Now go back to your app by clicking on the Android back button twice:
        // First one to leave the conversation screen
        // Second one to leave whatsapp
        try {
            Thread.sleep (500); // hack for certain devices in which the immediate back click is too fast to handle
            performGlobalAction (GLOBAL_ACTION_BACK);
            Thread.sleep (500);  // same hack as above
        } catch (InterruptedException ignored) {}
        performGlobalAction (GLOBAL_ACTION_BACK);
//        disableSelf();
    }

    @Override
    public void onInterrupt() {

    }

    @Override
    public void onDestroy() {
        System.out.println("onDestroy called");
    }

}
