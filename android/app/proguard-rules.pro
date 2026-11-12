# =============================================================================
# Vesta App ProGuard Rules
# =============================================================================

# Flutter, Firebase and AndroidX ship their own keep rules with their
# libraries. Blanket "-keep class io.flutter.** / com.google.firebase.** /
# androidx.** { *; }" rules here stopped R8 from shrinking anything and
# made the Java/Kotlin code 12.6 MB, so only specific rules stay below.

# freeRASP (Talsec)
-keep class com.aheaditec.** { *; }
-keep class com.talsec.** { *; }
-keepclassmembers class com.aheaditec.** { *; }
-keepclassmembers class com.talsec.** { *; }

# Firebase
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*

# Play Core (Deferred Components) - Not used but referenced by Flutter
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# local_auth (Biometrics)
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }

# OkHttp / Networking
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# General Android
-dontwarn androidx.**
-dontwarn android.**

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
