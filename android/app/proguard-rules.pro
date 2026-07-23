# REGRAS BASICAS PARA FLUTTER
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# FIREBASE
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.auth.** { *; }

# SEUS MODELOS
-keep class com.example.app_ponto.** { *; }
-keep class com.example.app_ponto.models.** { *; }

# LOCAL_AUTH (Biometria)
-keep class androidx.biometric.** { *; }

# GEOLOCATOR
-keep class com.google.android.gms.location.** { *; }

# CAMERA
-keep class android.hardware.camera2.** { *; }

# IMAGE_PICKER
-keep class android.provider.MediaStore** { *; }

# SHARE_PLUS
-keep class android.content.Intent** { *; }

# EVITAR WARNINGS DESNECESSARIOS
-dontwarn io.flutter.embedding.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**