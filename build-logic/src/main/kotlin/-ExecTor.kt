/*
 * Copyright (c) 2024 Matthew Nelson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
import io.matthewnelson.kmp.configuration.extension.KmpConfigurationExtension
import io.matthewnelson.kmp.configuration.extension.container.target.KmpConfigurationContainerDsl
import org.gradle.accessors.dm.LibrariesForLibs
import org.gradle.api.Action
import org.gradle.configurationcache.extensions.capitalized
import org.gradle.kotlin.dsl.the
import org.jetbrains.kotlin.gradle.plugin.KotlinSourceSet
import resource.validation.extensions.ExecTorResourceValidationExtension
import resource.validation.extensions.LibTorResourceValidationExtension
import java.io.File

fun KmpConfigurationExtension.configureExecTor(
    action: Action<KmpConfigurationContainerDsl>,
) {
    require(project.name.startsWith("resource-exec-tor")) { "Invalid project" }

    val libs = project.the<LibrariesForLibs>()
    val isGpl = project.name.endsWith("gpl")
    val suffix = if (isGpl) "-gpl" else ""
    val packageName = "io.matthewnelson.kmp.tor.resource.exec.tor"
    val execResourceValidation by lazy {
        project.extensions.getByType(ExecTorResourceValidationExtension::class.java)
    }

    val buildDir = project.layout
        .buildDirectory
        .get().asFile

    configureShared(
        java9ModuleName = packageName,
        publish = true,
    ) {
        jvm {
            sourceSetMain {
                resources.srcDir(execResourceValidation.jvmNativeLibResourcesSrcDir())
            }
        }

        common {
            pluginIds("resource-validation")

            sourceSetMain {
                dependencies {
                    api(libs.kmp.tor.common.api)
                }
            }
        }

        // jvmAndroid is kmp-configuration's intermediate JVM source set; it exists without an
        // Android target, and holds code (lib-tor jvmAndroidMain) and tests (jvmAndroidTest).
        sourceSetConnect(
            newName = "exec",
            existingNames = listOf(
                "jvmAndroid",
            ),
            sourceSetMain = {
                dependencies {
                    implementation(libs.kmp.tor.common.core)
                    implementation(project(":library:resource-geoip"))
                }
            },
        )
        sourceSetConnect(
            newName = "jvmJs",
            existingNames = listOf(
                "jvm",
            ),
            dependencyName = "exec",
            sourceSetMain = {
                dependencies {
                    implementation(libs.kmp.tor.common.core)
                }
            },
        )

        kotlin {
            with(sourceSets) {
                listOf(
                    "jvmAndroid",
                ).forEach { name ->
                    findByName(name + "Main")?.apply {
                        dependencies {
                            implementation(project(":library:resource-lib-tor$suffix"))
                        }
                    }
                }
            }
        }

        kotlin {
            with(sourceSets) {
                val execTest = findByName("execTest") ?: return@kotlin

                val buildConfigDir = buildDir
                    .resolve("generated")
                    .resolve("sources")
                    .resolve("buildConfig")

                fun KotlinSourceSet.generateBuildConfig(areErrorReportsEmpty: () -> Boolean?) {
                    val kotlinSrcDir = buildConfigDir
                        .resolve(this.name)
                        .resolve("kotlin")

                    this.kotlin.srcDir(kotlinSrcDir)

                    val dir = kotlinSrcDir.resolve(packageName.replace('.', File.separatorChar))

                    dir.mkdirs()

                    val testResourcesDir = buildDir
                        .resolve("test-resources")
                        .resolve(this.name)
                        .path
                        .replace("\\", "\\\\")

                    val sourceSet = this
                    project.afterEvaluate {
                        val areErrorReportsEmptyResult = areErrorReportsEmpty.invoke()

                        var lineIsGpl = ""
                        var lineRunFullTests = "internal actual val CAN_RUN_FULL_TESTS: Boolean = $areErrorReportsEmptyResult"
                        var lineTestDir = "internal actual val TEST_DIR: String = \"$testResourcesDir\""

                        if (areErrorReportsEmptyResult == null) {
                            lineIsGpl = "internal const val IS_GPL: Boolean = $isGpl"
                            lineRunFullTests = "internal expect val CAN_RUN_FULL_TESTS: Boolean"
                            lineTestDir = "internal expect val TEST_DIR: String"
                        }

                        @Suppress("DEPRECATION")
                        dir.resolve("BuildConfig${sourceSet.name.capitalized()}.kt").writeText("""
                            package $packageName
    
                            $lineIsGpl
                            $lineRunFullTests
                            $lineTestDir
    
                        """.trimIndent())
                    }
                }

                // root
                execTest.generateBuildConfig(areErrorReportsEmpty = { null })

                val resourceValidationExecTor = execResourceValidation

                val resourceValidationLibTor = project.extensions
                    .getByType(LibTorResourceValidationExtension::class.java)

                val reportJvm by lazy {
                    val exec = resourceValidationExecTor.errorReportJvmNativeLibResources()
                    val lib = resourceValidationLibTor.errorReportJvmNativeLibResources()
                    exec + lib
                }

                // Full tests run only when the JVM resources are the real (packaged) ones.
                findByName("jvmTest")?.generateBuildConfig {
                    reportJvm.indexOfFirst { !it.isWhitespace() } == -1
                }
            }
        }

        action.execute(this)
    }
}
