# kmp-tor-resource (Sparrow fork)
[![badge-license]][url-license]
[![badge-latest-release]][url-latest-release]

[![badge-kotlin]][url-kotlin]
[![badge-kmp-tor-common]][url-kmp-tor-common]

![badge-platform-jvm]

This is a fork of [05nelsonm/kmp-tor-resource][url-upstream], maintained for [Sparrow Wallet][url-sparrow]. It
packages pre-compiled `tor` for the JVM, to be used with [kmp-tor][url-kmp-tor]. All credit for the project
goes to its author, Matthew Nelson.

How it differs from upstream:

- **JVM only**, for the five platforms Sparrow ships on (below). The Android, iOS, Kotlin/Native and
  JavaScript/npm publications, and the `noexec` variant, are not built.
- **GPL only:** `tor` is built with `--enable-gpl`. There is no non-GPL variant.
- **Published as `com.sparrowwallet`**, tracking current `tor`. The package, class and JPMS module names are
  unchanged, so it's a drop-in replacement for the `io.matthewnelson.kmp-tor` artifacts.
- **Build toolchains** are built from the [build-env](build-env) Dockerfiles in this repo and pinned by digest
  ([build-env/digests](build-env/digests)).
- **Code signing:** the macOS binaries are signed with Sparrow's Developer ID and notarized; the Windows binaries
  are signed with Craig Raw's code signing certificate.

### Build Reproducibility

See [DETERMINISTIC_BUILDS.md](docs/DETERMINISTIC_BUILDS.md)

### Compilations

Tor and its dependencies are compiled from source using the following versions

<!-- TAG_DEPENDENCIES -->

|          | git tag                 |
|----------|-------------------------|
| libevent | `release-2.1.12-stable` |
| openssl  | `openssl-3.5.9`         |
| tor      | `tor-0.4.9.16`          |
| xz       | `v5.8.4`                |
| zlib     | `v1.3.2`                |

**NOTE:** All `macOS` and `Windows` compilations are code signed so they work out of the box.

More details about how things are compiled can be found [HERE](docs/COMPILATION_DETAILS.md)

### Supported Operating Systems & Architectures

|              | aarch64 | x86_64 | Minimum              |
|--------------|---------|--------|----------------------|
| Windows      |         | ✔      |                      |
| macOS        | ✔       | ✔      | 11 (aarch64), 10.9 (x86_64) |
| Linux (libc) | ✔       | ✔      | glibc 2.23           |

### Get Started

<!-- TAG_VERSION -->

```kotlin
// build.gradle.kts
dependencies {
    implementation("com.sparrowwallet:resource-exec-tor-gpl:409.16.0")
}
```

`resource-exec-tor-gpl` provides `ResourceLoaderTorExec`, and depends on `resource-lib-tor-gpl` and
`resource-geoip`. Pass it into `TorRuntime.Environment.Builder` when using [kmp-tor][url-kmp-tor]:

```kotlin
val env = TorRuntime.Environment.Builder(myWorkDir, myCacheDir, ResourceLoaderTorExec::getOrCreate)
```

**Don't mix** these with upstream's `io.matthewnelson.kmp-tor:resource-*` artifacts. They contain the same JPMS
modules, which conflict. Check with `gradle dependencies` that nothing still pulls them in.

The jars contain the `tor` compilations for all five platforms. To ship only the one for the host, use the
[gradle-filterjar-plugin][url-filterjar] with `filterGroup("com.sparrowwallet")`, filtering the `resource-exec-tor`
and `resource-lib-tor` artifacts (the prefix also matches `-gpl`). Keep `/<host>/<arch>/` and, on Windows,
`/mingw/tor.exe.local`.

### License

The build tooling is licensed under the Apache License 2.0. The published `resource-exec-tor-gpl` and
`resource-lib-tor-gpl` artifacts contain `tor` built with `--enable-gpl`, and are licensed under the
GNU General Public License, Version 3.0.

<!-- TAG_VERSION -->
[badge-latest-release]: https://img.shields.io/badge/latest--release-409.16.0-5d2f68.svg?logo=torproject&style=flat&logoColor=5d2f68
[badge-license]: https://img.shields.io/badge/license-Apache%20License%202.0-blue.svg?style=flat

<!-- TAG_DEPENDENCIES -->
[badge-kotlin]: https://img.shields.io/badge/kotlin-2.2.21-blue.svg?logo=kotlin
[badge-kmp-tor-common]: https://img.shields.io/badge/kmp--tor--common-2.4.2-blue.svg?style=flat

<!-- TAG_PLATFORMS -->
[badge-platform-jvm]: http://img.shields.io/badge/-jvm-DB413D.svg?style=flat

[url-filterjar]: https://github.com/05nelsonm/gradle-filterjar-plugin
[url-latest-release]: https://github.com/sparrowwallet/kmp-tor-resource/releases/latest
[url-license]: https://www.apache.org/licenses/LICENSE-2.0.html
[url-kotlin]: https://kotlinlang.org
[url-kmp-tor]: https://github.com/05nelsonm/kmp-tor
[url-kmp-tor-common]: https://github.com/05nelsonm/kmp-tor-common
[url-sparrow]: https://github.com/sparrowwallet/sparrow
[url-upstream]: https://github.com/05nelsonm/kmp-tor-resource
