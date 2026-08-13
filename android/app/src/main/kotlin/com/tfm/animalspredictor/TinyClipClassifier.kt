package com.tfm.animalspredictor

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.util.Log
import org.json.JSONObject
import org.tensorflow.lite.Interpreter
import java.io.Closeable
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

internal class TinyClipClassifier(
    private val context: Context,
) : Closeable {
    private var interpreter: Interpreter? = null
    private var metadata: Metadata? = null

    @Synchronized
    fun load() {
        if (interpreter != null) return
        val parsedMetadata = readMetadata()
        val options = Interpreter.Options().apply {
            setNumThreads(INFERENCE_THREADS)
            setUseXNNPACK(true)
        }
        val loaded = Interpreter(readModel(), options)
        try {
            validateModelContract(loaded, parsedMetadata.classCount)
        } catch (error: Exception) {
            loaded.close()
            throw error
        }
        metadata = parsedMetadata
        interpreter = loaded
    }

    @Synchronized
    fun classify(imagePath: String): Map<String, Any> {
        val activeInterpreter = interpreter ?: error("El modelo todavía no está cargado.")
        val activeMetadata = metadata ?: error("Faltan los metadatos del modelo.")
        val input = preprocess(imagePath)
        val output = Array(1) { FloatArray(activeMetadata.classCount) }
        activeInterpreter.run(input, output)
        val similarities = output[0]
        if (similarities.any { !it.isFinite() }) {
            error("El modelo ha devuelto puntuaciones inválidas.")
        }
        val orderedIndices = similarities.indices
            .sortedByDescending { similarities[it] }
        val topIndex = orderedIndices[0]
        val secondIndex = orderedIndices[1]
        val topSimilarity = similarities[topIndex]
        val margin = topSimilarity - similarities[secondIndex]
        val rejected = topSimilarity < activeMetadata.minimumSimilarity ||
            margin < activeMetadata.minimumMargin
        val probabilities = softmax(similarities, activeMetadata.logitScale)
        val reportedIndices = orderedIndices.take(MAX_RESULTS)
        return mapOf(
            "rejected" to rejected,
            "indices" to reportedIndices,
            "scores" to reportedIndices.map { probabilities[it].toDouble() },
            "topSimilarity" to topSimilarity.toDouble(),
            "margin" to margin.toDouble(),
        )
    }

    @Synchronized
    override fun close() {
        interpreter?.close()
        interpreter = null
        metadata = null
    }

    /**
     * Copia el modelo a memoria directa. No se usa mapeo del fichero porque los
     * assets de Flutter pueden viajar comprimidos dentro de la APK.
     */
    private fun readModel(): ByteBuffer {
        val bytes = context.assets.open(MODEL_ASSET).use { it.readBytes() }
        return ByteBuffer.allocateDirect(bytes.size).apply {
            order(ByteOrder.nativeOrder())
            put(bytes)
            rewind()
        }
    }

    private fun readMetadata(): Metadata {
        val document = context.assets.open(METADATA_ASSET).bufferedReader().use {
            JSONObject(it.readText())
        }
        require(document.getInt("schema_version") == 1) {
            "Versión de metadatos no compatible."
        }
        val classIds = document.getJSONArray("class_ids")
        require(classIds.length() >= 2) { "El catálogo del modelo está vacío." }
        val output = document.getJSONObject("output")
        val rejection = document.getJSONObject("rejection")
        val logitScale = output.getDouble("softmax_logit_scale").toFloat()
        val minimumSimilarity = rejection.getDouble("minimum_similarity").toFloat()
        val minimumMargin = rejection.getDouble("minimum_margin").toFloat()
        require(
            logitScale.isFinite() && logitScale > 0 &&
                minimumSimilarity.isFinite() &&
                minimumMargin.isFinite() && minimumMargin >= 0
        ) { "Los umbrales del modelo no son válidos." }
        return Metadata(
            classCount = classIds.length(),
            logitScale = logitScale,
            minimumSimilarity = minimumSimilarity,
            minimumMargin = minimumMargin,
        )
    }

    private fun validateModelContract(active: Interpreter, classCount: Int) {
        require(active.inputTensorCount == 1 && active.outputTensorCount == 1) {
            "El grafo TFLite tiene entradas o salidas inesperadas."
        }
        require(
            active.getInputTensor(0).shape()
                .contentEquals(intArrayOf(1, INPUT_SIZE, INPUT_SIZE, CHANNELS))
        ) {
            "La forma de entrada TFLite no es compatible."
        }
        require(
            active.getOutputTensor(0).shape().contentEquals(intArrayOf(1, classCount))
        ) {
            "La forma de salida TFLite no coincide con el catálogo."
        }
    }

    private fun preprocess(imagePath: String): Array<Array<Array<FloatArray>>> {
        val file = File(imagePath)
        require(file.isFile && file.canRead()) { "No se puede leer la imagen seleccionada." }
        val decoded = BitmapFactory.decodeFile(file.absolutePath)
            ?: error("El formato de imagen no es compatible.")
        val oriented = applyExifOrientation(decoded, file.absolutePath)
        try {
            return bicubicCenterCrop(oriented)
        } finally {
            if (oriented !== decoded) oriented.recycle()
            decoded.recycle()
        }
    }

    private fun applyExifOrientation(bitmap: Bitmap, imagePath: String): Bitmap {
        val orientation = try {
            ExifInterface(imagePath).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (error: Exception) {
            // Algunas imágenes no contienen EXIF. La decodificación sigue siendo
            // válida y se usa su orientación original como recuperación segura.
            Log.w(TAG, "No se pudo leer la orientación EXIF.", error)
            ExifInterface.ORIENTATION_NORMAL
        }
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true,
        )
    }

    /**
     * Reproduce resize por lado corto + recorte central + bicúbico de CLIP.
     *
     * TFLite espera NHWC, a diferencia del NCHW que usaba el grafo ONNX.
     */
    private fun bicubicCenterCrop(bitmap: Bitmap): Array<Array<Array<FloatArray>>> {
        require(bitmap.width > 0 && bitmap.height > 0) { "La imagen está vacía." }
        val sourcePixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(
            sourcePixels,
            0,
            bitmap.width,
            0,
            0,
            bitmap.width,
            bitmap.height,
        )
        val scale = INPUT_SIZE.toDouble() / min(bitmap.width, bitmap.height)
        val resizedWidth = max(INPUT_SIZE, (bitmap.width * scale).roundToInt())
        val resizedHeight = max(INPUT_SIZE, (bitmap.height * scale).roundToInt())
        val cropLeft = (resizedWidth - INPUT_SIZE) / 2.0
        val cropTop = (resizedHeight - INPUT_SIZE) / 2.0
        val xSamples = samplingTable(INPUT_SIZE, cropLeft, scale, bitmap.width)
        val ySamples = samplingTable(INPUT_SIZE, cropTop, scale, bitmap.height)
        val output = Array(1) {
            Array(INPUT_SIZE) { Array(INPUT_SIZE) { FloatArray(CHANNELS) } }
        }
        for (y in 0 until INPUT_SIZE) {
            val ySample = ySamples[y]
            for (x in 0 until INPUT_SIZE) {
                val xSample = xSamples[x]
                var red = 0.0
                var green = 0.0
                var blue = 0.0
                for (yOffset in 0 until CUBIC_POINTS) {
                    val row = ySample.indices[yOffset] * bitmap.width
                    val yWeight = ySample.weights[yOffset]
                    for (xOffset in 0 until CUBIC_POINTS) {
                        val pixel = sourcePixels[row + xSample.indices[xOffset]]
                        val weight = yWeight * xSample.weights[xOffset]
                        red += ((pixel shr 16) and 0xff) * weight
                        green += ((pixel shr 8) and 0xff) * weight
                        blue += (pixel and 0xff) * weight
                    }
                }
                val pixel = output[0][y][x]
                pixel[0] = normalize(red, 0)
                pixel[1] = normalize(green, 1)
                pixel[2] = normalize(blue, 2)
            }
        }
        return output
    }

    private fun samplingTable(
        count: Int,
        cropOffset: Double,
        scale: Double,
        sourceSize: Int,
    ): Array<Sample> = Array(count) { destination ->
        val source = (destination + cropOffset + 0.5) / scale - 0.5
        val base = floor(source).toInt()
        val indices = IntArray(CUBIC_POINTS)
        val weights = DoubleArray(CUBIC_POINTS)
        var totalWeight = 0.0
        for (offset in -1..2) {
            val index = offset + 1
            indices[index] = (base + offset).coerceIn(0, sourceSize - 1)
            weights[index] = cubicWeight(source - (base + offset))
            totalWeight += weights[index]
        }
        if (totalWeight != 0.0) {
            for (index in weights.indices) weights[index] /= totalWeight
        }
        Sample(indices, weights)
    }

    private fun cubicWeight(distance: Double): Double {
        val value = kotlin.math.abs(distance)
        return when {
            value <= 1 -> (1.5 * value - 2.5) * value * value + 1
            value < 2 -> ((-0.5 * value + 2.5) * value - 4) * value + 2
            else -> 0.0
        }
    }

    private fun normalize(channel: Double, index: Int): Float {
        val scaled = channel.coerceIn(0.0, 255.0) / 255.0
        return ((scaled - MEAN[index]) / STANDARD_DEVIATION[index]).toFloat()
    }

    private fun softmax(values: FloatArray, scale: Float): FloatArray {
        val maximum = values.maxOrNull() ?: error("La salida del modelo está vacía.")
        val result = FloatArray(values.size)
        var sum = 0.0
        for (index in values.indices) {
            val value = exp(((values[index] - maximum) * scale).toDouble())
            result[index] = value.toFloat()
            sum += value
        }
        require(sum.isFinite() && sum > 0) { "No se pueden normalizar las puntuaciones." }
        for (index in result.indices) result[index] = (result[index] / sum).toFloat()
        return result
    }

    private data class Metadata(
        val classCount: Int,
        val logitScale: Float,
        val minimumSimilarity: Float,
        val minimumMargin: Float,
    )

    private data class Sample(
        val indices: IntArray,
        val weights: DoubleArray,
    )

    private companion object {
        const val MODEL_ASSET =
            "flutter_assets/assets/models/tinyclip_39m_classifier.tflite"
        const val METADATA_ASSET =
            "flutter_assets/assets/models/tinyclip_39m_classifier.metadata.json"
        const val TAG = "AnimalsPredictor"
        const val INPUT_SIZE = 224
        const val CHANNELS = 3
        const val CUBIC_POINTS = 4
        const val INFERENCE_THREADS = 4
        const val MAX_RESULTS = 3
        val MEAN = doubleArrayOf(0.48145466, 0.4578275, 0.40821073)
        val STANDARD_DEVIATION = doubleArrayOf(0.26862954, 0.26130258, 0.27577711)
    }
}
