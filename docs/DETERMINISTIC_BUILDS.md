# DETERMINISTIC BUILDS

Tor and its dependencies are compiled deterministically such that anyone who wishes to verify the output can do
so. Compilation, packaging and validation are done by the `external/task.sh` script. The expected sha256 hashes are
provided by Gradle extensions in `build-logic/src/main/kotlin/resource/validation/extensions`.

The toolchain images are pinned by digest ([build-env/digests](../build-env/digests)). The Linux and Windows
images are public. The macOS images contain Apple's macOS SDK and are private, so only the Linux and Windows builds
can be reproduced without access to them (see [COMPILATION_DETAILS.md](COMPILATION_DETAILS.md)).

### TL;DR

<!-- TAG_VERSION -->
```
git clone --branch 409.16.0 --depth 1 --recurse-submodules https://github.com/sparrowwallet/kmp-tor-resource.git \
  && cd kmp-tor-resource \
  && ./external/task.sh build:all:linux-libc \
  && ./external/task.sh build:all:mingw \
  && ./external/task.sh package:linux-libc \
  && ./external/task.sh package:mingw \
  && ./external/task.sh package:geoip \
  && ./external/task.sh validate
```

### Validate Compilations

- What you will need:
    - An `x86_64` Linux machine (other hosts that can run `linux/amd64` containers work, much more slowly)
    - Bash
    - Git
    - Docker
    - A JDK between 17 and 24
    - Approximately 20GB of available disk space

1) Clone the repository:
   ```shell
   git clone https://github.com/sparrowwallet/kmp-tor-resource.git
   cd kmp-tor-resource
   ```

<!-- TAG_VERSION -->
2) Checkout the tag you wish to validate (replace with desired tag name):
   ```shell
   git checkout 409.16.0
   ```

3) Compile code:
   ```shell
   ./external/task.sh build:all:linux-libc
   ./external/task.sh build:all:mingw
   ```
   - With access to the private macOS images (`docker login ghcr.io`), `./external/task.sh build:all` builds all
     five targets.
   - If you are not building for the first time, add `--rebuild`, or run `./external/task.sh clean` first, to
     start completely fresh.

4) Package the compilations (this applies the committed detached signatures to the Windows build):
   ```shell
   ./external/task.sh package:linux-libc
   ./external/task.sh package:mingw
   ./external/task.sh package:geoip
   ```
   - After `build:all`, run `./external/task.sh package:all` instead.

5) Validate the hashes of the packaged compilations against the expected hashes:
   ```shell
   ./external/task.sh validate
   ```

If the error report files are empty, every packaged resource matched its expected sha256. Without the macOS
build, `resource-exec-tor-gpl/jvm.err` and `resource-lib-tor-gpl/jvm.err` list the macOS files as missing; every
other line should be absent.

Any error output is self-explanatory: either the file didn't exist, or its hash didn't match what was expected
for that platform and architecture.

<details>
    <summary>Example output (all five targets, no errors)</summary>

```
resource-exec-tor-gpl/jvm.err:

resource-geoip/jvm-geoip.err:

resource-lib-tor-gpl/jvm.err:


    Task 'validate' completed in 0m1.119s
```

</details>
