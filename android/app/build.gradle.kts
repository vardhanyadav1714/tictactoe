import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadKeyFile = rootProject.file("tictactoe.properties")
val uploadKeyProperties = Properties()
if (uploadKeyFile.exists()) {
    uploadKeyFile.inputStream().use { uploadKeyProperties.load(it) }
}
val releaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseRequested && !uploadKeyFile.exists()) {
    throw GradleException("Release signing requires android/tictactoe.properties and tictactoe.jks. See docs/signing.md.")
}
fun uploadKeyValue(name: String): String =
    uploadKeyProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("Missing $name in android/tictactoe.properties")

android {
    namespace = "innovatixhub.in.tictactoe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "innovatixhub.in.tictactoe"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadKeyFile.exists()) {
            create("release") {
                storeFile = rootProject.file(uploadKeyValue("storeFile"))
                if (!storeFile!!.isFile) {
                    throw GradleException("The configured upload keystore is missing. Restore tictactoe.jks; see docs/signing.md.")
                }
                storeType = "JKS"
                storePassword = uploadKeyValue("storePassword")
                keyAlias = uploadKeyValue("keyAlias")
                keyPassword = uploadKeyValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
