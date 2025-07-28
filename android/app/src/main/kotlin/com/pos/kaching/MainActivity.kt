package com.pos.kaching

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.app.Activity
import android.content.Context
import androidx.annotation.RequiresApi
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pos.kaching/channel"
    private lateinit var printerController: PrinterController
    private val BLUETOOTH_PERMISSION_REQUEST_CODE = 1001
    private val ENABLE_BLUETOOTH_REQUEST_CODE = 1002
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    var IntentResult = "SampleResult"
    var IntentResultCode = "[]"
    var IntentResultMessage = ""
    var IntentResultData = ""

    var settlementResult = ""
    var settlementResultData = ""
    var settlementResultCode = "[]"
    var settlementResultMessage = ""


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            SDKInstance.initSDK(this.applicationContext, false, "DIRECT", false)
            Log.d("--- MainActivity", "SDKInstance.initSDK called")

            // Wait for SDKInstance.mPrinter to be initialized (max 5 seconds)
            var waited = 0
            while (SDKInstance.mPrinter == null && waited < 10) {
                Thread.sleep(500)
                waited++
                Log.d("--- MainActivity", "Waiting for SDKInstance.mPrinter... ($waited)")
            }

            if (SDKInstance.mPrinter == null) {
                Log.e("--- MainActivity", "SDKInstance.mPrinter is still null after waiting!")
            }

            requestBluetoothPermissions()
            coroutineScope.launch {
                printerController = PrinterController(this@MainActivity)
                Log.d("--- MainActivity", "PrinterController initialized")
            }
        } catch (e: Exception) {
            Log.e("--- MainActivity", "Failed to initialize PrinterController: ${e.message}")
        }
    }

    private fun requestBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.BLUETOOTH_CONNECT,
                        Manifest.permission.BLUETOOTH_SCAN
                    ),
                    BLUETOOTH_PERMISSION_REQUEST_CODE
                )
            }
        }

        // Check if Bluetooth is enabled
        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter

        if (bluetoothAdapter == null) {
            Log.e("--- MainActivity", "Bluetooth adapter not found")
            return
        }

        if (!bluetoothAdapter.isEnabled) {
            Log.d("--- MainActivity", "Bluetooth is not enabled, requesting enable")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                    val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                    startActivityForResult(enableBtIntent, ENABLE_BLUETOOTH_REQUEST_CODE)
                }
            } else {
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                startActivityForResult(enableBtIntent, ENABLE_BLUETOOTH_REQUEST_CODE)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == BLUETOOTH_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                Log.d("--- MainActivity", "Bluetooth permissions granted")
                // Recheck Bluetooth state after permissions are granted
                requestBluetoothPermissions()
            } else {
                Log.e("--- MainActivity", "Bluetooth permissions denied")
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            ENABLE_BLUETOOTH_REQUEST_CODE -> {
                if (resultCode == RESULT_OK) {
                    Log.d("--- MainActivity", "Bluetooth enabled successfully")
                    // Reinitialize printer controller after Bluetooth is enabled
                    coroutineScope.launch {
                        try {
                            printerController = PrinterController(this@MainActivity)
                            Log.d("--- MainActivity", "PrinterController reinitialized after Bluetooth enable")
                        } catch (e: Exception) {
                            Log.e("--- MainActivity", "Failed to reinitialize PrinterController: ${e.message}")
                        }
                    }
                } else {
                    Log.e("--- MainActivity", "Bluetooth enable request denied")
                }
            }
            1 -> {
                IntentResult = "here is the OnActivityResult"
                data?.let {
                    val result = it.getStringExtra("result") ?: ""
                    val resultMsg = it.getStringExtra("resultMsg") ?: ""
                    val transData = it.getStringExtra("transData") ?: ""
                    IntentResult = "Result: $result, Result Message: $resultMsg, Transaction Data: $transData"
                    IntentResultCode = result
                    IntentResultMessage = resultMsg
                    IntentResultData = transData
                    Log.d("--- Main.Kt.OnActivityResult", IntentResult)
                }
            }
            2 -> {
                settlementResult = "here is the OnActivityResult"
                data?.let {
                    val result = it.getStringExtra("result") ?: ""
                    val resultMsg = it.getStringExtra("resultMsg") ?: ""
                    val transData = it.getStringExtra("transData") ?: "{}"
                    Log.d("--- Main.Kt.OnActivityResult", "Settlement raw data:")
                    Log.d("--- Main.Kt.OnActivityResult", "result: $result")
                    Log.d("--- Main.Kt.OnActivityResult", "resultMsg: $resultMsg")
                    Log.d("--- Main.Kt.OnActivityResult", "transData: $transData")

                    // Create a JSON object with the settlement data
                    val settlementJson = JSONObject().apply {
                        put("transType", "CARD")
                        put("transCount", "0")
                        put("transAmount", "0.00")
                        put("currencyCode", "ZAR")
                        put("settlementTime", "")
                    }

                    settlementResult = "Result: $result, Result Message: $resultMsg, Transaction Data: $transData"
                    settlementResultCode = result
                    settlementResultMessage = resultMsg
                    settlementResultData = settlementJson.toString()
                    Log.d("--- Main.Kt.OnActivityResult", "Final settlement result: $settlementResult")
                    Log.d("--- Main.Kt.OnActivityResult", "Settlement data JSON: $settlementResultData")
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.DONUT)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAddpayIntent" -> {
                    IntentResult = ""
                    val parameters = call.arguments<String>() ?: return@setMethodCallHandler
                    Log.d("--- Main.KT", "launchAddpayIntent Init: $parameters")
                    val response = launchAddpayIntent(parameters)
                    Log.d("--- Main.Kt.MethodChannel:", response)
                    result.success(response)
                }
                "checkResult" -> result.success(IntentResult)
                "checkResultCode" -> result.success(IntentResultCode)
                "checkResultMessage" -> result.success(IntentResultMessage)
                "checkResultData" -> result.success(IntentResultData)
                "printCustomSlip" -> {
                    val slipData = call.arguments<String>() ?: "{}"
                    Log.d("--- Main.Kt", "printCustomSlip called with: $slipData")
                    coroutineScope.launch {
                        try {
                            val printResult = withContext(Dispatchers.IO) {
                                printerController.printCustomSlip(slipData)
                            }
                            Log.d("--- Main.Kt", "printCustomSlip result: $printResult")
                            result.success(printResult)
                        } catch (e: Exception) {
                            Log.e("--- Main.Kt", "printCustomSlip failed: ${e.message}")
                            result.error("PRINT_ERROR", "Failed to print: ${e.message}", null)
                        }
                    }
                }
                "checkPrinterStatus" -> {
                    try {
                        val printer = SDKInstance.mPrinter
                        if (printer == null) {
                            result.success("NOT_INITIALIZED")
                        } else {
                            val status = IntArray(1)
                            printer.getPrinterStatus(status)
                            when (status[0]) {
                                0 -> result.success("OK")
                                1 -> result.success("BUSY")
                                2 -> result.success("OUT_OF_PAPER")
                                3 -> result.success("OVERHEATED")
                                4 -> result.success("OUT_OF_BATTERY")
                                else -> result.success("UNKNOWN")
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("--- Main.Kt", "checkPrinterStatus failed: ${e.message}")
                        result.success("ERROR")
                    }
                }
                "launchSettlementIntent" -> {
                    result.success(launchSettlementIntent())
                }
                "checkSettlementResult" -> result.success(settlementResult)
                "checkSettlementResultData" -> result.success(settlementResultData)
                "checkSettlementResultCode" -> result.success(settlementResultCode)
                "checkSettlementResultMessage" -> result.success(settlementResultMessage)
                else -> {
                    Log.e("--- Main.Kt", "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.DONUT)
    private fun launchAddpayIntent(jsonString: String): String {
        Log.d("--- launchAddPayIntent with params:", jsonString)
        val intent = Intent()
        intent.setPackage("com.wiseasy.cashier")
        intent.setAction("com.wiseasy.transaction.call")
        intent.putExtra("version", "A01")
        intent.putExtra("appId", "wzbdd525151af914b1")
        intent.putExtra("transType", "SALE")
        intent.putExtra("transData", jsonString)
        try {
            startActivityForResult(intent, 1)
            return "Intent launched"
        } catch (e: Exception) {
            Log.e("--- Main.Kt", "Failed to launch intent: ${e.message}")
            return "Error: ${e.message}"
        }
    }

    @RequiresApi(Build.VERSION_CODES.DONUT)
    private fun launchSettlementIntent(): String {
        Log.d("--- MainActivity", "Launching settlement intent")
        val intent = Intent()
        intent.setPackage("com.wiseasy.cashier")
        intent.setAction("com.wiseasy.transaction.call")
        intent.putExtra("version", "A01")
        intent.putExtra("appId", "wzbdd525151af914b1")
        intent.putExtra("transType", "SETTLEMENT")
        try {
            startActivityForResult(intent, 2) // Using different request code (2) for settlement
            return "Settlement intent launched"
        } catch (e: Exception) {
            Log.e("--- MainActivity", "Failed to launch settlement intent: ${e.message}")
            return "Error: ${e.message}"
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("--- Main.Kt", "Destroying activity")
        try {
            // Clean up printer resources
            if (::printerController.isInitialized) {
                try {
                    SDKInstance.mPrinter?.printFinish()
                } catch (e: Exception) {
                    Log.e("--- Main.Kt", "Failed to finish print: ${e.message}")
                }
            }

            // Release SDK resources
            SDKInstance.releaseSDK()
            Log.d("--- Main.Kt", "SDK resources released")
        } catch (e: Exception) {
            Log.e("--- Main.Kt", "Failed to release SDK: ${e.message}")
        }
    }
}