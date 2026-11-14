plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.galaxyandsun.daidatanhhung"
    // TODO(pre-release): raise compileSdk/targetSdk to 36 before any Play upload
    // (Play requires API 36 for new apps and updates since 2026-08-31). Luan: 35 for now.
    compileSdk = 35

    defaultConfig {
        applicationId = "com.galaxyandsun.daidatanhhung"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures { buildConfig = true }

    // Shared content (ADR-0001): data/ ships in every build; the sample hero only in debug builds.
    sourceSets {
        getByName("main") { assets.srcDirs("../../content/data") }
        getByName("debug") { assets.srcDirs("../../content/samples") }
    }
}

kotlin {
    jvmToolchain(17)
}

/**
 * R11 + R12 at build time (content/README.md): a release build fails if any claim cited by a
 * bundled hero's Text is not approved, or if any content file's schema MAJOR is newer than this
 * app supports. Debug builds skip it (they show UNSIGNED badges instead).
 */
abstract class ContentGateTask : DefaultTask() {
    @get:InputDirectory abstract val dataDir: DirectoryProperty
    @get:Input abstract val supportedMajor: Property<Int>

    @TaskAction
    fun check() {
        val dir = dataDir.get().asFile
        val slurper = groovy.json.JsonSlurper()
        val problems = mutableListOf<String>()
        dir.walkTopDown().filter { it.isFile && it.extension == "json" }.forEach { f ->
            val v = (slurper.parse(f) as Map<*, *>)["schema_version"] as? String ?: return@forEach
            if (v.substringBefore('.').toInt() > supportedMajor.get()) problems += "R11 ${f.relativeTo(dir)}: schema_version $v is newer than ${supportedMajor.get()}.x"
        }
        @Suppress("UNCHECKED_CAST")
        val heroes = (slurper.parse(File(dir, "index.json")) as Map<String, Any?>)["heroes"] as List<String>
        fun cited(node: Any?, out: MutableSet<String>) {
            when (node) {
                is Map<*, *> -> { if (node.containsKey("vi") && node.containsKey("en")) (node["claims"] as? List<*>)?.forEach { out += it.toString() }
                    node.values.forEach { cited(it, out) } }
                is List<*> -> node.forEach { cited(it, out) }
            }
        }
        for (h in heroes) {
            val claims = (slurper.parse(File(dir, "heroes/$h/claims.json")) as Map<*, *>)["claims"] as List<*>
            val status = claims.associate { c -> (c as Map<*, *>)["id"].toString() to ((c["signoff"] as Map<*, *>)["status"]).toString() }
            val ids = mutableSetOf<String>()
            cited(slurper.parse(File(dir, "heroes/$h/mission.json")), ids)
            cited(slurper.parse(File(dir, "heroes/$h/quiz.json")), ids)
            val unsigned = ids.filter { status[it] != "approved" }.sorted()
            if (unsigned.isNotEmpty()) problems += "R12 hero $h: claims not approved: ${unsigned.joinToString(", ")}"
        }
        if (problems.isNotEmpty()) throw GradleException("Content gate failed (release builds need signed-off content):\n" + problems.joinToString("\n"))
        logger.lifecycle("Content gate passed: ${heroes.size} hero(es)")
    }
}

val contentGate = tasks.register<ContentGateTask>("contentGate") {
    dataDir.set(rootProject.layout.projectDirectory.dir("../content/data"))
    supportedMajor.set(1)
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach { dependsOn(contentGate) }

dependencies {
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
}
