# UPDATING

1) Update git submodules in `external` to desired tags, then:
   - Update `SUBMODULES_EXPECTED` in `external/task.sh` with each new tag and commit. Builds stop if a submodule
     isn't at the listed commit.
   - Stage the moved submodules (`git add external/<name>`) before building: `task.sh` runs
     `git submodule update`, which resets submodules to the commits in the index.
   - Check the patches in `external/patches/` still apply (`git -C external/<name> apply --check ../patches/<name>/*.patch`).

2) Update version strings in `README.md`

3) Copy `tor` man pages
   ```shell
   cp external/tor/doc/man/tor.1.txt docs/tor-man.adoc
   ```

4) Clean & build
   ```shell
   ./external/task.sh clean
   ./external/task.sh build:all
   ```

5) Generate code signatures
   - macOS (signed and notarized in CI with Sparrow's Developer ID):
     1. Run the CI workflow by hand (`workflow_dispatch`) with `sign_macos` ticked.
     2. Unpack its `macos-lts-signatures` artifact into `external/codesign/tor-gpl/macos-lts/`, and commit it.
   - Windows (signed locally with Jsign; imported on the machine that has the unsigned build from step 4):
     1. Get the unsigned `tor.exe` and `tor.dll`: the `mingw-x86_64` artifact of a CI run of the commit being
        released, or `external/build/out/tor-gpl/mingw/x86_64/` from step 4. They're byte-identical.
     2. Sign both files with Jsign, with a timestamp, embedding the full certificate chain (`--certfile` with
        the leaf and intermediate certificates). Sign fresh unsigned copies, never already-signed files.
     3. Copy the two signed files into a directory of their own on that machine, and import them:
        ```shell
        ./external/task.sh sign:mingw:import /path/to/dir/with/signed/files
        ```
        This writes `external/codesign/tor-gpl/mingw/x86_64/{tor.dll,tor.exe}.signature`, after checking that
        each one turns the unsigned file into the signed one.
     4. Commit the signatures. CI's `mingw-signed` and `windows-signed-smoke` jobs then apply them to the
        CI-built output, check both Authenticode signatures are valid and timestamped on Windows, and run
        the signed `tor.exe`.

6) Package compilations (on the machine with the build from step 4, after the signatures from step 5 are in place)
   ```shell
   ./external/task.sh package:all
   ```

7) Update `ResourceValidation` extension hash values
   ```shell
   ./external/task.sh validate:update_hashes
   ```

8) Ensure validation output has NO errors. A mismatched hash doesn't fail the Gradle build: the module
   silently falls back to its mock resources. CI's `package` job packages the CI build and fails on any
   validation error, so push and check it before releasing.
