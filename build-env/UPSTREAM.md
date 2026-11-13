# Upstream

Copied from https://github.com/05nelsonm/build-env at commit `1e15a2c1177a1ab868877d21dcf6f47cbc117335`.

Local changes:

- `task.sh`: `ORG` is `ghcr.io/sparrowwallet/build-env`.
- `src/**/Dockerfile`: `FROM` lines name `ghcr.io/sparrowwallet/build-env.*` images.
- `src/base/Dockerfile`: `debian:12-slim` is pinned by digest.
- JNI headers removed: no `JNI_H` and no download from the upstream `sdk` branch in `src/base/Dockerfile`, and no
  `jni_md.h` symlink loops in `src/linux`, `src/base/darwin`, `src/base/mingw` and `src/base/android`.
  Upstream's JNI download was what created `${BUILD_ENV}`, so `src/base/Dockerfile` now copies
  `pkg-config-crosswrapper.sh` to `${BUILD_ENV}/` (trailing slash) to create the directory.
- `digests` (new): GHCR digests of the published images.

The READMEs and CHANGELOG are unchanged from upstream and still refer to `05nelsonm/build-env` and `JNI_H`.
