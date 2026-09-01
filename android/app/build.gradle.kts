import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The release keystore, which is not in this repository and never will be.
//
// `android/key.properties` names the store, the alias and the two passwords;
// it is gitignored, and CI writes it from secrets before it builds. When the
// file is absent the release build falls back to the debug key below, which is
// what makes `flutter run --release` work on a machine that has no keystore —
// and the fallback announces itself, because an APK signed with the debug key
// that looked like a release is the one mistake this file exists to prevent.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
} else {
    logger.lifecycle(
        "android/key.properties is absent: a release build will be signed with the debug key",
    )
}

android {
    namespace = "dev.quire.atril"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // A federated identifier is `@local_name:server`, and the reverse-DNS
        // name here is the same claim in Android's namespace: it is the
        // domain the project is published under, and it matches the iOS bundle
        // identifier, the macOS one and the GTK application id so that one
        // string names this application on every target that wants one.
        applicationId = "dev.quire.atril"

        // Pinned rather than tracking `flutter.minSdkVersion`, which is 24 in
        // this release of Flutter and is the floor the dependencies actually
        // need: flutter_secure_storage asks for 23, connectivity_plus for 21,
        // and flutter_inappwebview for 19. What a pin buys is that a Flutter
        // upgrade cannot silently drop the devices this app runs on — raising
        // the floor is a decision, and a decision belongs in a diff.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion

        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
