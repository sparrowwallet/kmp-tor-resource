# Releasing

Releases are published to Maven Central as `com.sparrowwallet:resource-exec-tor-gpl` (with `resource-lib-tor-gpl`
and `resource-geoip`), JVM only. CI builds, signs (macOS), packages and validates the release commit. Publishing
runs on the Mac, from CI's packaged resources: the Mac has no Docker, so it doesn't package itself.

Why this is safe: CI's `package` job packages the five targets with the committed detached signatures, and fails
unless every packaged resource matches its validation hash in `build-logic/src/main/kotlin/resource/validation/`.
On the Mac, `verifyResourceValidation` runs before any publish task and fails unless the same hashes match. A
mismatch would otherwise make Gradle silently build with the mock resources from `mock-resources/`.

### Before the release

- If tor or a bundled library changed since the last release, follow [UPDATING.md](UPDATING.md) first: build,
  sign (macOS in CI, Windows with Jsign), package and regenerate the validation hashes.
- `master` is green in CI, including `package and validate`.

### One-time setup (macOS)

- A JDK between 17 and 24 to run Gradle, and JDK 11 installed (the `module-info` compile uses a JDK 11 toolchain,
  found under `/Library/Java/JavaVirtualMachines`)
```
java --version
/usr/libexec/java_home -V
```

- `gh` logged in, to download the CI artifact
```
gh auth status
```

- `~/.gradle/gradle.properties` holds the Maven Central Portal credentials and the GPG signing config used for
  Sparrow's other `com.sparrowwallet` artifacts
```
mavenCentralUsername=<token username>
mavenCentralPassword=<token password>
signing.keyId=...
```

### Release commit

- In a `bash` shell, set the version
```
VERSION_NAME="<version name>"   # e.g. 409.16.0
```

- Update `VERSION_NAME` (remove `-SNAPSHOT`) in the root `gradle.properties`, update `CHANGELOG.md`, and the
  version in `README.md`

- Commit, tag and push
```
git checkout master
git pull
git add --all
git commit -S -m "Prepare $VERSION_NAME release"
git tag -s "$VERSION_NAME" -m "Release v$VERSION_NAME"
git push
git push origin "$VERSION_NAME"
```

- Wait for the CI run on the release commit to finish green, in particular `package and validate`, and note its
  run ID
```
gh run list --workflow CI.yml --commit "$(git rev-parse HEAD)"
RUN_ID="<run id>"
```

### Publish (macOS)

- If GPG asks for a YubiKey PIN, sign something first: the PIN prompt and the Gradle build don't mix
```
echo test | gpg --sign --armor > /dev/null
```

- Start clean, then download CI's packaged resources and jars, and put the resources in place
```
./gradlew clean
DIR_DL="$(mktemp -d)"
gh run download "$RUN_ID" -n package -D "$DIR_DL"
rm -rf external/build/package
mkdir -p external/build
cp -R "$DIR_DL/external/build/package" external/build/
```

- Build the jars and check they match CI's, byte for byte (same commit, same compiler and resources). The jars are
  reproducible: every entry has the fixed timestamp 1980-02-01, a fixed order and a fixed mode (files `rw-r--r--`,
  directories `rwxr-xr-x`), set in `build-logic/src/main/kotlin/publication.gradle.kts`, so the building machine's
  file modes and umask don't matter. CI's `package` job also lists the three jars' sha256s in its run summary.
```
./gradlew verifyResourceValidation \
  :library:resource-exec-tor-gpl:jvmJar :library:resource-lib-tor-gpl:jvmJar :library:resource-geoip:jvmJar
for m in resource-exec-tor-gpl resource-lib-tor-gpl resource-geoip; do
  shasum -a 256 "library/$m/build/libs/$m-jvm-$VERSION_NAME.jar" "$DIR_DL/library/$m/build/libs/$m-jvm-$VERSION_NAME.jar"
done
```
  If they differ, stop and compare the jars' contents (`unzip` both and `diff -r`) and entries (`unzip -Z`).

- Publish (don't add `clean` here: it deletes the validation reports, and `verifyResourceValidation` then refuses)
```
./gradlew publishAllPublicationsToMavenCentralRepository --no-daemon --no-parallel
```

- Check the deployment on the Central Portal ([central.sonatype.com](https://central.sonatype.com/publishing/deployments)):
  it should be *Validated*, with the three modules' root and `-jvm` publications

- Check the publication resolves (reads the deployment with the Maven Central credentials)
```
./gradlew clean -PCHECK_PUBLICATION
./gradlew :tools:check-publication:build --refresh-dependencies -PCHECK_PUBLICATION
```

- **Release** the deployment from the Central Portal UI

### After the release

- Update `VERSION_NAME` to the next `-SNAPSHOT` (e.g. `409.16.1-SNAPSHOT`) in the root `gradle.properties`, then
  commit and push
```
git add gradle.properties
git commit -S -m "Prepare for next development iteration"
git push
```

- Wait for the release on [Maven Central](https://repo1.maven.org/maven2/com/sparrowwallet/resource-exec-tor-gpl/)

- Draft a GitHub release for the tag, with the changelog
