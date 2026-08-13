package com.animalspredictor.onnxsmoke;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.FloatBuffer;
import java.util.Arrays;
import java.util.Collections;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtSession;
import ai.onnxruntime.TensorInfo;

public final class MainActivity extends Activity {
    private static final String TAG = "ANIMAL_ONNX_SMOKE";
    private static final int WARMUP_RUNS = 5;
    private static final int MEASURED_RUNS = 30;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView statusView = new TextView(this);
        statusView.setPadding(32, 32, 32, 32);
        statusView.setText("Ejecutando TinyCLIP con ONNX Runtime…");
        setContentView(statusView);

        new Thread(() -> runSmoke(statusView), "onnx-smoke").start();
    }

    private void runSmoke(TextView statusView) {
        try (OrtEnvironment environment = OrtEnvironment.getEnvironment();
             OrtSession.SessionOptions options = new OrtSession.SessionOptions()) {
            options.setIntraOpNumThreads(4);
            byte[] model = readAsset("tinyclip.int8.onnx");
            long initStart = System.nanoTime();
            try (OrtSession session = environment.createSession(model, options)) {
                double initMs = elapsedMs(initStart);
                String inputName = session.getInputNames().iterator().next();
                float[] input = deterministicInput(1 * 3 * 224 * 224);
                long[] inputShape = {1, 3, 224, 224};

                try (OnnxTensor tensor = OnnxTensor.createTensor(
                        environment,
                        FloatBuffer.wrap(input),
                        inputShape)) {
                    for (int index = 0; index < WARMUP_RUNS; index++) {
                        invoke(session, inputName, tensor);
                    }

                    double[] timings = new double[MEASURED_RUNS];
                    long[] outputShape = null;
                    for (int index = 0; index < MEASURED_RUNS; index++) {
                        long start = System.nanoTime();
                        try (OrtSession.Result result = session.run(
                                Collections.singletonMap(inputName, tensor))) {
                            timings[index] = elapsedMs(start);
                            TensorInfo info = (TensorInfo) result.get(0).getInfo();
                            outputShape = info.getShape();
                        }
                    }

                    Arrays.sort(timings);
                    double median = percentile(timings, 0.50);
                    double p95 = percentile(timings, 0.95);
                    String report = String.format(
                            java.util.Locale.ROOT,
                            "PASS model_bytes=%d init_ms=%.3f median_ms=%.3f p95_ms=%.3f output=%s",
                            model.length,
                            initMs,
                            median,
                            p95,
                            Arrays.toString(outputShape));
                    Log.i(TAG, report);
                    runOnUiThread(() -> statusView.setText(report));
                }
            }
        } catch (Exception error) {
            String report = "FAIL " + error.getClass().getSimpleName() + ": " + error.getMessage();
            Log.e(TAG, report, error);
            runOnUiThread(() -> statusView.setText(report));
        }
    }

    private static void invoke(OrtSession session, String inputName, OnnxTensor tensor)
            throws Exception {
        try (OrtSession.Result ignored = session.run(
                Collections.singletonMap(inputName, tensor))) {
            // Closing the result releases the native output tensors after each run.
        }
    }

    private byte[] readAsset(String name) throws Exception {
        try (InputStream input = getAssets().open(name);
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[64 * 1024];
            int count;
            while ((count = input.read(buffer)) != -1) {
                output.write(buffer, 0, count);
            }
            return output.toByteArray();
        }
    }

    private static float[] deterministicInput(int count) {
        float[] values = new float[count];
        for (int index = 0; index < count; index++) {
            values[index] = ((index % 251) / 125.0f) - 1.0f;
        }
        return values;
    }

    private static double elapsedMs(long startNanos) {
        return (System.nanoTime() - startNanos) / 1_000_000.0;
    }

    private static double percentile(double[] sorted, double fraction) {
        int index = (int) Math.ceil(fraction * sorted.length) - 1;
        return sorted[Math.max(0, Math.min(index, sorted.length - 1))];
    }
}
