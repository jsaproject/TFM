package com.tfm.animalspredictor

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class TinyClipClassifierInstrumentedTest {
    @Test
    fun classifiesBundledAnimalWithProductionPipeline() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val image = File(context.cacheDir, "tinyclip-device-test-vaca.jpg")
        context.assets.open("flutter_assets/assets/vaca.jpg").use { input ->
            image.outputStream().use(input::copyTo)
        }

        val startedAt = System.nanoTime()
        TinyClipClassifier(context).use { classifier ->
            classifier.load()
            val result = classifier.classify(image.absolutePath)
            val indices = result["indices"] as? List<*>

            assertFalse(result["rejected"] as Boolean)
            assertEquals(0, indices?.first())
            assertTrue((result["topSimilarity"] as Double).isFinite())
        }
        val elapsedMilliseconds = (System.nanoTime() - startedAt) / 1_000_000.0
        assertTrue("La prueba tardó $elapsedMilliseconds ms", elapsedMilliseconds < 10_000)
    }
}
