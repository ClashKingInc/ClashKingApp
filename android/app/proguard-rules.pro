# Proguard rules for missing classes
-keep class com.google.errorprone.annotations.Immutable { *; }
-keep class javax.annotation.concurrent.GuardedBy { *; }

# Keep Tink classes
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
