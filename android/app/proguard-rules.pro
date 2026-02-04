# Keep GMS Credentials classes
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-dontwarn com.google.android.gms.auth.api.credentials.**

# Keep TensorFlow Lite GPU classes
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

-keep class androidx.window.extensions.** { *; }
-dontwarn androidx.window.extensions.**

-keep class androidx.window.sidecar.** { *; }
-dontwarn androidx.window.sidecar.**