# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Dart classes
-keep class **.dart.** { *; }

# Keep models for JSON serialization
-keep class com.chatorai.app.models.** { *; }

# Dio HTTP client
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Keep generic signatures for Dio
-keepattributes Signature
-keepattributes *Annotation*

# Speech to text plugin
-keep class com.csdcorp.speech_to_text.** { *; }

# Image picker
-keep class com.yalantis.ucrop.** { *; }

# Share Plus
-keep class com.shareplus.** { *; }

# Connectivity Plus
-keep class com.flutter.plugins.connectivity.** { *; }

# Shared Preferences
-keep class com.tencent.hawk.** { *; }

# R8 full mode rules
-allowaccessmodification
-repackageclasses
-overloadaggressively
-dontusemixedcaseclassnames

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep data classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Path provider
-keep class androidx.** { *; }
-keep class org.gradle.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep annotation
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
