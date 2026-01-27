# R8/ProGuard rules for Book Butler

# Handle missing JPEG2000 decoder used by PDF libraries
-dontwarn com.gemalto.jp2.JP2Decoder

# Keep custom notification service
-keep class com.example.project_thera.NotificationGenie { *; }

# Keep Firebase and FCM classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter Firebase Messaging classes
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# If you encounter more missing classes, add them here:
# -dontwarn com.another.missing.class
