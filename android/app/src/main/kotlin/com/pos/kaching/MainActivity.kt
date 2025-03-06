package com.pos.kaching

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.pos.kaching/channel"
    
    var IntentResult = "SampleResult";
    var IntentResultCode = "[]";
    var IntentResultMessage = "";
    var IntentResultData = "";

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            
            if (call.method == "launchAddpayIntent") {
                IntentResult = "";
                val parameters = call.arguments<String>() ?: return@setMethodCallHandler
                Log.d("--- Main.KT", "launchAddpayIntent Init:"+parameters.toString())
                val response = launchAddpayIntent(parameters)
                Log.d("--- Main.Kt.MethodChannel:", response.toString());
                result.success(response)
            } else 
            if (call.method == "checkResult") {
                //launchSampleWorkingIntent()
                result.success(""+IntentResult);
            } else
            if (call.method == "checkResultCode") {
                //launchSampleWorkingIntent()
                result.success(""+IntentResultCode);
            } else
            if (call.method == "checkResultMessage") {
                //launchSampleWorkingIntent()
                result.success(""+IntentResultMessage);
            } else
            if (call.method == "checkResultData") {
                //launchSampleWorkingIntent()
                result.success(""+IntentResultData);
            } else
            {
                result.notImplemented()
            }
        }
    }
   
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1) {
            this.IntentResult = "here is the Onactivity Result"
            data?.let {
                val result = it.getStringExtra("result") ?: ""
                val resultMsg = it.getStringExtra("resultMsg") ?: ""
                val transData = it.getStringExtra("transData") ?: ""
                IntentResult = "Result: $result, Result Message: $resultMsg, Transaction Data: $transData"
                IntentResultCode = result.toString();
                IntentResultMessage = resultMsg.toString();
                IntentResultData = transData.toString();
                Log.d("--- Main.Kt.OnactivityResult", "Result: $result, Result Message: $resultMsg, Transaction Data: $transData")
            }
        }
    }

    private fun launchAddpayIntent(jsonString: String): String {
        Log.d("--- launchAddPayIntent with params:", jsonString.toString());
        val intent = Intent();

        intent.setPackage("com.wiseasy.cashier");
        intent.setAction("com.wiseasy.transaction.call");
        intent.putExtra("version", "A01");
        intent.putExtra("appId", ""); //Secret removed, populate with app ID
        intent.putExtra("transType", "SALE");
        intent.putExtra("transData", jsonString.toString()); 
        
        var r = startActivityForResult(intent, 1);
        
        Log.d("--- launchAddPayIntent Result:", r.toString());
        return r.toString();
    }
}

