package com.tfm.animalspredictor

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private lateinit var classifier: TinyClipClassifier
    private lateinit var executor: ExecutorService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        classifier = TinyClipClassifier(applicationContext)
        executor = Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "tinyclip-inference")
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> runInBackground(result) {
                classifier.load()
                null
            }
            "classify" -> {
                val imagePath = call.argument<String>("imagePath")
                if (imagePath.isNullOrBlank()) {
                    result.error("INVALID_IMAGE", "La ruta de imagen no es válida.", null)
                    return
                }
                runInBackground(result) { classifier.classify(imagePath) }
            }
            "dispose" -> runInBackground(result) {
                classifier.close()
                null
            }
            else -> result.notImplemented()
        }
    }

    private fun runInBackground(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        executor.execute {
            try {
                result.success(operation())
            } catch (error: Exception) {
                Log.e(TAG, "Fallo en el clasificador local.", error)
                result.error(
                    "CLASSIFIER_ERROR",
                    error.message ?: "No se ha podido ejecutar el clasificador.",
                    null,
                )
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        if (::executor.isInitialized) {
            executor.execute { classifier.close() }
            executor.shutdown()
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private companion object {
        const val CHANNEL_NAME = "com.tfm.animalspredictor/tinyclip"
        const val TAG = "AnimalsPredictor"
    }
}
