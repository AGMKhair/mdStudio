# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLite ProGuard Rules
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }

# AdMob ProGuard Rules
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# In-App Purchase ProGuard Rules
-keep class com.android.billingclient.** { *; }

# Play Core ProGuard Rules to fix R8 missing classes error
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase Auth / Google Sign-In Rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-dontwarn com.google.firebase.**
