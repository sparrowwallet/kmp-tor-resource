/*
 * Copyright (c) 2023 Matthew Nelson
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
plugins {
    id("com.vanniktech.maven.publish")
}

mavenPublishing {
    pom {
        developers {
            // The first developer (the fork's maintainer) comes from POM_DEVELOPER_* in gradle.properties.
            developer {
                id.set("05nelsonm")
                name.set("Matthew Nelson")
                url.set("https://github.com/05nelsonm/")
            }
        }
    }
}

// A resource that doesn't match its validation hash doesn't fail the build: the module silently falls
// back to its mock resources (build-logic/src/main/kotlin/resource/validation). So nothing is published
// unless every published module's validation reports exist (validation ran) and are all empty (every
// hash matched). Each publish task waits for all modules' checks, not just its own, so a failure in one
// module can't leave the others published (Gradle runs projects in parallel).
val verifyResourceValidation = tasks.register("verifyResourceValidation") {
    val dirReports = layout.buildDirectory.dir("reports/resource-validation/${project.name}")
    doLast {
        val dir = dirReports.get().asFile
        val reports = dir.listFiles { file -> file.name.endsWith(".err") }.orEmpty().sortedBy { it.name }
        check(reports.isNotEmpty()) {
            "No resource validation reports in $dir, so the resources were not validated. " +
            "Don't run 'clean' in the same Gradle invocation as publishing."
        }
        val failed = reports.filter { it.length() > 0 }
        check(failed.isEmpty()) {
            "Resource validation failed; publishing would ship mock resources:\n" +
            failed.joinToString("\n") { "${it.name}:\n${it.readText()}" }
        }
    }
}

tasks.withType<AbstractPublishToMaven>().configureEach {
    dependsOn(provider {
        rootProject.subprojects
            .filter { it.plugins.hasPlugin("publication") }
            .map { "${it.path}:${verifyResourceValidation.name}" }
    })
}

tasks.withType<AbstractArchiveTask>().configureEach {
    isPreserveFileTimestamps = false
    isReproducibleFileOrder = true
}
