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
@file:Suppress("PrivatePropertyName")

package resource.validation.extensions

import org.gradle.api.Project
import resource.validation.extensions.internal.ValidationHash
import java.io.File
import javax.inject.Inject

/**
 * Resource validation and configuration for module `:library:resource-exec-tor-gpl`,
 * `tor` compiled with `--enable-gpl`.
 * */
abstract class ExecTorResourceValidationExtension @Inject internal constructor(
    project: Project,
): AbstractResourceValidationExtension(
    project = project,
    moduleName = "resource-exec-tor-gpl",
    packageName = "io.matthewnelson.kmp.tor.resource.exec.tor",
) {

    private val jvmLinuxLibcAarch64: String = "67d64240c27d4571935ab5d5a05ac870cf880b1f6f8189b06ef52d09979270cd"
    private val jvmLinuxLibcX86_64: String = "eb6ac226e3e542b5ad039252ebbfd363ba7b5993e03179ccf78a8f1c0b113ea8"

    private val jvmMacosAarch64: String = "a74191dce6c166b4a124605a805ebe1cd7477c85364ec513473f778b95bcf993"
    private val jvmMacosX86_64: String = "f5a6156d072ccb8ed2bc643593341b40901d7566ed6e606346077d1734793be9"

    private val jvmMingwX86_64: String = "93b21caf51934686fdda954b31466f496f3aa71cd0c4a1458cc8823fab261a43"

    fun jvmNativeLibResourcesSrcDir(): File = jvmNativeLibsResourcesSrcDirProtected()
    fun errorReportJvmNativeLibResources(): String = errorReportJvmNativeLibsProtected()

    final override val hashes: Set<ValidationHash> by lazy { setOf(
        // jvm linux-libc
        ValidationHash.LibJvm(
            osName = "linux",
            osSubtype = "libc",
            arch = "aarch64",
            libName = "tor.gz",
            hash = jvmLinuxLibcAarch64,
        ),
        ValidationHash.LibJvm(
            osName = "linux",
            osSubtype = "libc",
            arch = "x86_64",
            libName = "tor.gz",
            hash = jvmLinuxLibcX86_64,
        ),

        // jvm macos
        ValidationHash.LibJvm(
            osName = "macos",
            arch = "aarch64",
            libName = "tor.gz",
            hash = jvmMacosAarch64,
        ),
        ValidationHash.LibJvm(
            osName = "macos",
            arch = "x86_64",
            libName = "tor.gz",
            hash = jvmMacosX86_64,
        ),

        // jvm mingw
        ValidationHash.LibJvm(
            osName = "mingw",
            arch = "x86_64",
            libName = "tor.exe.gz",
            hash = jvmMingwX86_64,
        ),
    ) }

    internal companion object {
        internal const val NAME = "execTorResourceValidation"
    }
}
