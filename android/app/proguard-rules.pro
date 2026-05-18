# MediaPipe warnings suppression
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
-dontwarn com.google.mediapipe.proto.**

# Keep all MediaPipe classes so R8 does not remove them
-keep class com.google.mediapipe.** { *; }

# Keep protobuf classes required by MediaPipe
-keep class com.google.protobuf.** { *; }

# Flutter engine rules
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# General safety rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# ObjectBox rules
-keep class io.objectbox.** { *; }
-keep class io.objectbox.relation.** { *; }
-dontwarn io.objectbox.**