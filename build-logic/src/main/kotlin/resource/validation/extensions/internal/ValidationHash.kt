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
package resource.validation.extensions.internal

import resource.validation.extensions.internal.ERROR.Companion.toERROR
import resource.validation.extensions.internal.SourceSetName.Companion.toSourceSetName
import java.io.File

sealed class ValidationHash private constructor() {

    internal data class LibJvm internal constructor(
        val osName: String,
        val osSubtype: String = "",
        val arch: String,
        val libName: String,
        val hash: String,
    ): ValidationHash() {

        internal fun validate(nativeDir: File): ERROR? {
            val machineName = osSubtype.ifBlank { null }?.let { "$osName-$it" } ?: osName

            val lib = nativeDir
                .resolve(machineName)
                .resolve(arch)
                .resolve(libName)

            val rPath = lib.path.substringAfter("${File.separatorChar}kmp-tor-resource${File.separatorChar}")

            if (!lib.exists()) {
                return "Lib does not exist: $rPath".toERROR()
            }

            val actualHash = lib.sha256()
            if (hash != actualHash) {
                return "Lib ${formatHashMismatch(actualHash, hash, rPath)}".toERROR()
            }

            return null
        }
    }

    internal data class ResourceJvm internal constructor(
        val fileName: String,
        val hash: String,
    ): ValidationHash() {

        internal fun validate(
            packageModuleDir: File,
            packageName: String,
        ): ERROR? {
            val file = "jvm".toSourceSetName()
                .sourceSetDir(packageModuleDir)
                .resolve("resources")
                .resolve(packageName.replace('.', '/'))
                .resolve(fileName)

            val rPath = file.path.substringAfter("${File.separatorChar}kmp-tor-resource${File.separatorChar}")

            if (!file.exists()) {
                return "Resource does not exist: $rPath".toERROR()
            }

            val actualHash = file.sha256()
            if (hash != actualHash) {
                return "Resource ${formatHashMismatch(actualHash, hash, rPath)}".toERROR()
            }

            return null
        }
    }

    private companion object {

        // If modifying, update 'validate:update_hashes' task in 'task.sh'
        @JvmStatic
        private fun formatHashMismatch(
            actual: String,
            expected: String,
            path: String,
        ): String = "hash[$actual] did not match expected[$expected]: $path"
    }
}
