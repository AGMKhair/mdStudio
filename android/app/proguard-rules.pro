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
