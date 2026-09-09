# Flutter and its plugins ship their own consumer rules; these cover the few
# libraries that use reflection and would otherwise be renamed away.

# Razorpay reads its classes reflectively during checkout.
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Firebase messaging.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep annotations that Flutter's embedding relies on.
-keepattributes *Annotation*
