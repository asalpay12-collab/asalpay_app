package com.asal.asalpay;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.common.api.Status;

public class SmsBroadcastReceiver extends BroadcastReceiver {
    private static final String TAG = "SmsBroadcastReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (SmsRetriever.SMS_RETRIEVED_ACTION.equals(intent.getAction())) {
            Status status = (Status) intent.getParcelableExtra(SmsRetriever.EXTRA_STATUS);
            switch (status.getStatusCode()) {
                case CommonStatusCodes.SUCCESS:
                    // SMS retrieved successfully
                    String message = intent.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE);
                    Log.d(TAG, "SMS retrieved: " + message);
                    // Send to Flutter
                    break;
                case CommonStatusCodes.TIMEOUT:
                    Log.w(TAG, "SMS retrieval timeout");
                    break;
            }
        }
    }
}