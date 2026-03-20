package com.example.move_runapp


import android.content.Context
import android.hardware.*
import androidx.core.content.ContextCompat.getSystemService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

class MainActivity: FlutterActivity(), SensorEventListener {

    private val CHANNEL = "movego_channel"
    private lateinit var channel: MethodChannel
    private lateinit var sensorManager: SensorManager
    private var last = 0.0
    private var current = 0.0
    private var accel = 0.0
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        current = SensorManager.GRAVITY_EARTH.toDouble()
        last = SensorManager.GRAVITY_EARTH.toDouble()
    }
    override fun onSensorChanged(e: SensorEvent) {
        val x = e.values[0]
        val y = e.values[1]
        val z = e.values[2]
        last = current
        current = sqrt((x*x + y*y + z*z).toDouble())
        val delta = current - last
        accel = accel * 0.9 + delta
        if (accel > 5) {
            channel.invokeMethod("step", null)
        }
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}