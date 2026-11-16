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
@file:Suppress("NOTHING_TO_INLINE", "SameParameterValue")

package resource.validation.extensions

import org.gradle.api.Project
import resource.validation.extensions.internal.ERROR
import resource.validation.extensions.internal.SourceSetName.Companion.toSourceSetName
import resource.validation.extensions.internal.ValidationHash
import java.io.File

/**
 * Base abstraction for validating reproducibility of packaged
 * resources located in the `external/build/package` directory.
 *
 * e.g. (terminal)
 *
 *     ./external/task.sh build:all
 *     ./external/task.sh package:all
 *     ./external/task.sh validate
 * */
sealed class AbstractResourceValidationExtension(
    protected val project: Project,
    protected val moduleName: String,
    protected val packageName: String,
) {

    protected val dirProjectRoot: File = project
        .rootProject
        .projectDir

    protected abstract val hashes: Set<ValidationHash>

    private val errLibJvm = mutableSetOf<ERROR>()
    private val errResJvm = mutableSetOf<ERROR>()

    private var isConfiguredLibJvm = false
    private var isConfiguredResJvm = false

    private val dirModuleMock: File by lazy {
        dirProjectRoot
            .resolve("mock-resources")
            .resolve(moduleName)
    }
    private val dirModulePackage: File by lazy {
        dirProjectRoot
            .resolve("external")
            .resolve("build")
            .resolve("package")
            .resolve(moduleName)
    }
    private val dirReport: File by lazy {
        project.layout.buildDirectory.get().asFile
            .resolve("reports")
            .resolve("resource-validation")
            .resolve(moduleName)
    }

    ///////////////////////
    // JVM - NATIVE LIBS //
    ///////////////////////

    @Throws(IllegalStateException::class)
    protected fun jvmNativeLibsResourcesSrcDirProtected(): File {
        val hashes = hashes.filterIsInstance<ValidationHash.LibJvm>()
        check(hashes.isNotEmpty()) { "No hashes to validate, no jvm resources" }

        val name = "jvm".toSourceSetName()
        val srcResMock = name.sourceSetDir(dirModuleMock)
            .resolve("resources")
        val srcResPackage = name.sourceSetDir(dirModulePackage)
            .resolve("resources")

        if (!isConfiguredLibJvm) {
            val dirResNative = srcResPackage
                .resolve(packageName.replace('.', '/'))
                .resolve("native")

            hashes.forEach { libHash ->
                val error = libHash.validate(dirResNative) ?: return@forEach
                errLibJvm.add(error)
            }

            isConfiguredLibJvm = true
            generateReport("jvm", errLibJvm)
        }

        return if (errLibJvm.isEmpty()) srcResPackage else srcResMock
    }

    @Throws(IllegalStateException::class)
    protected fun errorReportJvmNativeLibsProtected(): String {
        if (isConfiguredLibJvm) return errLibJvm.buildString()

        val hashes = hashes.filterIsInstance<ValidationHash.LibJvm>()
        check(hashes.isNotEmpty()) { "No hashes to validate, no jvm resources" }

        val name = "jvm".toSourceSetName()
        val srcResPackage = name.sourceSetDir(dirModulePackage)
            .resolve("resources")

        val dirResNative = srcResPackage
            .resolve(packageName.replace('.', '/'))
            .resolve("native")

        return hashes.mapNotNullTo(LinkedHashSet()) { libHash ->
            libHash.validate(dirResNative)
        }.buildString()
    }

    @Throws(IllegalStateException::class)
    protected fun jvmResourcesSrcDirProtected(reportName: String): File {
        val hashes = hashes.filterIsInstance<ValidationHash.ResourceJvm>()
        check(hashes.isNotEmpty()) { "No hashes to validate, no jvm resources" }

        val name = "jvm".toSourceSetName()
        val srcResMock = name.sourceSetDir(dirModuleMock)
            .resolve("resources")
        val srcResPackage = name.sourceSetDir(dirModulePackage)
            .resolve("resources")

        if (!isConfiguredResJvm) {
            hashes.forEach { res ->
                val error = res.validate(dirModulePackage, packageName) ?: return@forEach
                errResJvm.add(error)
            }

            isConfiguredResJvm = true
            generateReport(reportName, errResJvm)
        }

        return if (errResJvm.isEmpty()) srcResPackage else srcResMock
    }

    @Throws(IllegalStateException::class)
    protected fun errorReportJvmResourcesProtected(): String {
        if (isConfiguredResJvm) return errResJvm.buildString()

        val hashes = hashes.filterIsInstance<ValidationHash.ResourceJvm>()
        check(hashes.isNotEmpty()) { "No hashes to validate, no jvm resources" }

        return hashes.mapNotNullTo(LinkedHashSet()) { res ->
            res.validate(dirModulePackage, packageName)
        }.buildString()
    }

    private fun generateReport(fileName: String, errors: Set<ERROR>) {
        if (!dirReport.exists()) dirReport.mkdirs()

        val report = errors.buildString()
        dirReport.resolve("$fileName.err").writeText(report)
    }

    private inline fun Set<ERROR>.buildString(): String = buildString build@ {
        this@buildString.forEach { err -> appendLine(err) }
    }
}
