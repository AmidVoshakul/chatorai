# CI / Release Pipeline Diagrams

**Last updated:** 2026-07-08

This file documents the single GitHub Actions workflow, build matrix, and
GitHub Release publication flow used for every tagged version of ChatORAI.
---
## Workflow Topology

```mermaid
graph TD
    push_main["Push to main / develop"]
    push_tag["Push tag v*"]
    pr["Pull request\nto main"]

    subgraph jobs["Single workflow: .github/workflows/ci.yml"]
        test["test\n(flutter pub get → analyze → flutter test)"]
        build_apk["build-apk\n(needs: test)"]
        build_linux["build-linux\n(needs: test)"]
        build_windows["build-windows\n(needs: test)"]
        build_macos["build-macos\n(needs: test)"]
        release["release\n(needs: all builds;\nonly on v* tags)"]
    end

    push_main --> test
    push_tag --> test
    pr --> test

    test --> build_apk
    test --> build_linux
    test --> build_windows
    test --> build_macos

    build_apk --> release
    build_linux --> release
    build_windows --> release
    build_macos --> release

    release --> gh_release["GitHub Release\n(with generate_release_notes)"]
```

**Note:** `release.yml` was deleted. All jobs live in `.github/workflows/ci.yml`.
Cross-workflow `needs:` is not supported by GitHub Actions, so release stays in
the same file.
---
## Linux Artifact Packaging

```mermaid
graph TD
    flutter_build["flutter build linux --release"]
    bundle_dir["build/linux/x64/release/bundle"]

    subgraph tar["tar.gz"]
        tar_pkg["tar -czf chatorai-linux-x64-{tag}.tar.gz"]
        tar_stable["cp → chatorai-linux-x64.tar.gz"]
    end

    subgraph appimage["AppImage"]
        appdir["ChatORAI.AppDir/"]
        apprun["AppRun script\n(GL self-healing + CHATORAI_FORCE_SOFT_GL)"]
        appimage_pkg["appimagetool → .AppImage"]
        appimage_stable["cp → chatorai-linux-x64.AppImage"]
    end

    subgraph deb["deb"]
        staging["debian-staging/"]
        control["DEBIAN/control\n(Package: chatorai, Depends: GTK libs, libsecret-1-0, libsqlite3-0, zlib1g…)"]
        postinst["DEBIAN/postinst\n(glxinfo heuristic → .force_soft_gl)"]
        launcher["usr/bin/chatorai\n(software-GL fallback + crash retry)"]
        deb_pkg["dpkg-deb --build → .deb"]
    end

    flutter_build --> bundle_dir
    bundle_dir --> tar_pkg
    tar_pkg --> tar_stable

    bundle_dir --> appdir
    appdir --> apprun
    apprun --> appimage_pkg
    appimage_pkg --> appimage_stable

    bundle_dir --> staging
    staging --> control
    staging --> postinst
    staging --> launcher
    control --> deb_pkg
    postinst --> deb_pkg
    launcher --> deb_pkg
```

**Install paths (all Linux formats consistent):**
- tarball / AppImage: `/usr/local/lib/chatorai` + `/usr/local/bin/chatorai`
- deb: `/usr/local/lib/chatorai` + `/usr/bin/chatorai`

No stale `/usr/lib/chatorai` paths remain.
---
## Windows / macOS Artifacts

```mermaid
graph LR
    win_build["flutter build windows --release"]
    win_zip["Compress-Archive → .zip"]
    win_stable["cp → chatorai-windows-x64.zip"]

    mac_build["flutter build macos --release"]
    mac_dmg["create-dmg / hdiutil → .dmg"]
    mac_stable["cp → chatorai-macos.dmg"]

    win_build --> win_zip --> win_stable
    mac_build --> mac_dmg --> mac_stable
```
---
## Release Publication

```mermaid
graph LR
    tag_push["git push --tags v0.1.1"]
    download["Download all artifacts"]
    rename_apk["mv app-release.apk\n→ chatorai-release-{tag}.apk"]
    gh_release["softprops/action-gh-release@v2\n(generate_release_notes: true)"]
    stable_copies["Stable copies\n(chatorai-linux-x64.*,\nchatorai-windows-x64.zip,\nchatorai-macos.dmg)"]

    tag_push --> download
    download --> rename_apk
    rename_apk --> gh_release
    download --> stable_copies
    stable_copies --> gh_release
```

**First git tag:** `v0.1.0`  
**Current version:** `0.1.1`