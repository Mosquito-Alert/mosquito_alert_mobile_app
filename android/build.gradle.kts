allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    configurations.all {
        resolutionStrategy {
            // TODO: Remove when flutter_workmanager has been updated
            // See: https://github.com/fluttercommunity/flutter_workmanager/issues/666
            force("androidx.work:work-runtime:2.11.2")
        }
    }
}

// camera_android_camerax 0.7.2 compiles against camera-core 1.6.0, whose
// SurfaceRequest exposes a field of type CallbackToFutureAdapter.Completer
// (androidx.concurrent:concurrent-futures) that the plugin module does not
// declare. javac <= 17 tolerated the gap; the JDK 25 bundled with current
// Android Studio refuses to attach the jar's type annotations and fails
// :camera_android_camerax:compileReleaseJavaWithJavac with
//   "Cannot attach type annotations @NonNull to SurfaceRequest... class file
//    for androidx.concurrent.futures.CallbackToFutureAdapter not found".
// The library is already in the runtime APK via camera-core, so compileOnly
// changes nothing shipped. Remove this once camera_android_camerax is
// upgraded past 0.7.2.
subprojects {
    if (name == "camera_android_camerax") {
        plugins.withId("com.android.library") {
            dependencies.add("compileOnly", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
