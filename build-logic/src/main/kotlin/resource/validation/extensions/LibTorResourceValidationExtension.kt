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
 * Resource validation and configuration for module `:library:resource-lib-tor-gpl`,
 * `tor` compiled with `--enable-gpl`.
 * */
abstract class LibTorResourceValidationExtension @Inject internal constructor(
    project: Project,
): AbstractResourceValidationExtension(
    project = project,
    moduleName = "resource-lib-tor-gpl",
    packageName = "io.matthewnelson.kmp.tor.resource.lib.tor",
) {

    private val jvmLinuxLibcAarch64: String = "89d61dbf027845e72dee651a2588a2889ea2f20fe3e347e0abb1aac64ed3188e"
    private val jvmLinuxLibcX86_64: String = "4cb62ee9c300fc2ef86cf15757c83e5315b1d03b595f2cb681fd8d30b4820146"

    private val jvmMacosAarch64: String = "f2541e538fd5429771b21d966a80d578c5bac76f83085caa37c120fc2a33a871"
    private val jvmMacosX86_64: String = "1906c7f0ad4b9dd21e986b8c12a0c4d115882e4bd3f710e2b455c3432bc1dc91"

    private val jvmMingwX86_64: String = "7831d6e4d4e9145d2e092f1aec0ec0eeac0d580564deec433b9cd08d8f716872"

    fun jvmNativeLibResourcesSrcDir(): File = jvmNativeLibsResourcesSrcDirProtected()
    fun errorReportJvmNativeLibResources(): String = errorReportJvmNativeLibsProtected()

    final override val hashes: Set<ValidationHash> by lazy { setOf(
        // jvm linux-libc
        ValidationHash.LibJvm(
            osName = "linux",
            osSubtype = "libc",
            arch = "aarch64",
            libName = "libtor.so.gz",
            hash = jvmLinuxLibcAarch64,
        ),
        ValidationHash.LibJvm(
            osName = "linux",
            osSubtype = "libc",
            arch = "x86_64",
            libName = "libtor.so.gz",
            hash = jvmLinuxLibcX86_64,
        ),

        // jvm macos
        ValidationHash.LibJvm(
            osName = "macos",
            arch = "aarch64",
            libName = "libtor.dylib.gz",
            hash = jvmMacosAarch64,
        ),
        ValidationHash.LibJvm(
            osName = "macos",
            arch = "x86_64",
            libName = "libtor.dylib.gz",
            hash = jvmMacosX86_64,
        ),

        // jvm mingw
        ValidationHash.LibJvm(
            osName = "mingw",
            arch = "x86_64",
            libName = "tor.dll.gz",
            hash = jvmMingwX86_64,
        ),
    ) }

    internal companion object {
        internal const val NAME = "libTorResourceValidation"
    }
}
