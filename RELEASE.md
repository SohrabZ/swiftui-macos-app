# Releasing LiquidGlassDemo

LiquidGlassDemo ships as a **direct download** — a signed, notarized DMG hosted on
GitHub Releases, with in-app auto-updates via [Sparkle](https://sparkle-project.org).
This is *not* the Mac App Store (Sparkle isn't allowed there); it's the same model
the reference project uses.

The pipeline: **build + sign `.app` → DMG → notarize + staple → update the Sparkle
appcast → publish a GitHub release**. `scripts/release.sh` runs all of it once the
one-time setup below is done.

## One-time setup

You need an **Apple Developer account** ($99/yr). None of the secrets below are
committed — they live in your keychain and in `app.yml` (public values only).

1. **Developer ID Application certificate.** In Xcode → Settings → Accounts, or at
   developer.apple.com, create a *Developer ID Application* certificate and install
   it in your login keychain. Confirm it:
   ```bash
   security find-identity -v -p codesigning
   ```
   Copy the full identity string into `app.yml` → `developer_id_application`, and
   your team id into `apple_team_id`.

2. **Notarization credentials.** Create an app-specific password (or App Store
   Connect API key) and store it as a notarytool profile:
   ```bash
   xcrun notarytool store-credentials "LiquidGlassDemo Notary" \
       --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-pw"
   ```
   Put the profile name in `app.yml` → `notarytool_keychain_profile`.

3. **Sparkle signing key.** Generate an Ed25519 key pair once. The **private key
   stays in your keychain**; the tool prints the **public** key:
   ```bash
   ./.build/artifacts/sparkle/Sparkle/bin/generate_keys
   ```
   Paste the printed public key into `app.yml` → `sparkle_public_ed_key`.
   (Run `swift build` first if the artifacts path doesn't exist yet.)

4. **Fill in `app.yml`** — `bundle_identifier`, `github_owner`/`github_repo`,
   `feed_url`, and `download_base_url`. Defaults point at this repo's GitHub
   Releases and the `appcast.xml` served raw from the default branch.

5. **Host the appcast.** The app polls `feed_url` for updates. The default serves
   the committed `appcast.xml` via `raw.githubusercontent.com` on the default
   branch — so publishing an update = committing the regenerated `appcast.xml`.
   (GitHub Pages or your own site work too; keep `feed_url` and the app's
   `SUFeedURL` in sync.)

## Cut a release

```bash
scripts/release.sh --version 1.2.0            # build number derives from git history
# or: scripts/release.sh --version 1.2.0 --build 42 --notes notes.md
```

This signs and notarizes the DMG, regenerates `appcast.xml`, and creates the
GitHub release with the DMG attached. Then commit the feed so users see it:

```bash
git add appcast.xml && git commit -m "Release 1.2.0" && git push
```

Existing users get the update automatically (Sparkle checks the feed on launch and
periodically), or via **LiquidGlassDemo ▸ Check for Updates…**.

## Local testing (no signing)

`scripts/build_app.sh` assembles `dist/LiquidGlassDemo.app` without signing when no
Developer ID is set — good for checking the bundle, icon, and layout:

```bash
scripts/build_app.sh --version 0.0.0 --build 1
open dist/LiquidGlassDemo.app
```

Unsigned builds omit the Sparkle keys, so auto-update stays off (no updater errors).

## Notes

- **SwiftPM, not Xcode.** This repo has no `.xcodeproj`, so `build_app.sh` packages
  the `.app` by hand (binary + `Info.plist` + `.icns` + embedded, re-signed
  `Sparkle.framework`) instead of `xcodebuild archive`.
- **Appcast history.** `generate_appcast` builds the feed from the DMGs in
  `dist/updates/`. Keep past DMGs there (or re-download them) to retain every
  version in the feed; Sparkle only needs the newest to offer an update.
- **`Package.resolved` is committed** so release builds pin the exact Sparkle
  version.
- **Never commit** certificates, the Sparkle private key, or notarization
  passwords. Only the Sparkle *public* key belongs in `app.yml`.
