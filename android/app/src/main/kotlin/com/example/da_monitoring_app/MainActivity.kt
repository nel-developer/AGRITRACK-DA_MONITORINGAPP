package com.example.da_monitoring_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.exifinterface.media.ExifInterface

class MainActivity : FlutterActivity() {
    private val STORAGE_CHANNEL = "com.example.da_monitoring_app/storage"
    private val EXIF_CHANNEL = "com.example.da_monitoring_app/exif"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Storage method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getExternalFilesDir" -> {
                    val externalFilesDir = getExternalFilesDir(null)
                    if (externalFilesDir != null) {
                        result.success(externalFilesDir.absolutePath)
                    } else {
                        result.error("UNAVAILABLE", "External files directory not available", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // EXIF method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXIF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setExifGPS" -> {
                    try {
                        val imagePath = call.argument<String>("imagePath") ?: ""
                        val latitude = call.argument<Double>("latitude") ?: 0.0
                        val longitude = call.argument<Double>("longitude") ?: 0.0
                        val accuracy = call.argument<Double>("accuracy") ?: 0.0
                        
                        android.util.Log.d("EXIF_CHANNEL", "📍 [EXIF] Setting GPS for: $imagePath")
                        android.util.Log.d("EXIF_CHANNEL", "📍 [EXIF] Coordinates: lat=$latitude, lon=$longitude, acc=$accuracy")
                        
                        val imageFile = java.io.File(imagePath)
                        if (!imageFile.exists()) {
                            android.util.Log.e("EXIF_CHANNEL", "❌ [EXIF] File not found: $imagePath")
                            result.error("FILE_NOT_FOUND", "Image file does not exist", null)
                            return@setMethodCallHandler
                        }
                        
                        val exif = ExifInterface(imagePath)
                        
                        // Validate coordinates
                        if (latitude.isNaN() || longitude.isNaN() || !latitude.isFinite() || !longitude.isFinite()) {
                            android.util.Log.w("EXIF_CHANNEL", "⚠️ [EXIF] Invalid coordinates: lat=$latitude, lon=$longitude")
                            result.success("Skipped - invalid coordinates")
                            return@setMethodCallHandler
                        }
                        
                        // Set GPS attributes using proper DMS format
                        exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, if (latitude >= 0) "N" else "S")
                        exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, convertToDMS(kotlin.math.abs(latitude)))
                        exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, if (longitude >= 0) "E" else "W")
                        exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, convertToDMS(kotlin.math.abs(longitude)))
                        
                        exif.saveAttributes()
                        
                        val latDMS = convertToDMS(kotlin.math.abs(latitude))
                        val lonDMS = convertToDMS(kotlin.math.abs(longitude))
                        android.util.Log.d("EXIF_CHANNEL", "✅ [EXIF] GPS saved successfully: lat=$latDMS, lon=$lonDMS")
                        result.success("GPS data saved successfully")
                    } catch (e: Exception) {
                        android.util.Log.e("EXIF_CHANNEL", "❌ [EXIF] Exception: ${e.message}")
                        e.printStackTrace()
                        result.error("EXIF_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    
    private fun convertToDMS(coordinate: Double): String {
        val degrees = coordinate.toInt()
        val minutes = ((coordinate - degrees) * 60).toInt()
        val seconds = ((coordinate - degrees) * 60 - minutes) * 60
        return "$degrees/1,$minutes/1,${(seconds * 100).toInt()}/100"
    }
}

