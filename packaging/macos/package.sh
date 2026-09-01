#!/usr/bin/env bash
#
# Signs, notarizes and zips the macOS bundle `flutter build macos --release`
# produced. It runs on a macOS host and nowhere else.
#
# Everything it needs comes from the environment, and every step it cannot take
# is skipped with a line saying so rather than failing. That is the shape the
# release workflow needs: a tag pushed by somebody with no Developer ID should
# still produce an artifact, and it should be impossible to mistake that
# artifact for a signed one.
#
#   MACOS_SIGNING_IDENTITY   the "Developer ID Application: …" identity in the
#                            keychain. Absent: the bundle is signed ad hoc.
#   MACOS_NOTARY_PROFILE     a `notarytool store-credentials` profile name.
#                            Absent: the bundle is not notarized or stapled.
set -euo pipefail

app="build/macos/Build/Products/Release/atril.app"
out="build/macos/packaged"

if [[ ! -d $app ]]; then
  echo "no bundle at $app — run 'flutter build macos --release' first" >&2
  exit 1
fi

mkdir -p "$out"

if [[ -n ${MACOS_SIGNING_IDENTITY:-} ]]; then
  # --deep is deliberately not used: it is documented as unsuitable for
  # signing a distributed app, and Xcode has already signed the frameworks
  # and the embedded helpers with the same identity. What is re-signed here is
  # the bundle itself, under the hardened runtime that notarization requires,
  # with the release entitlements the sandbox is described by.
  echo "signing with $MACOS_SIGNING_IDENTITY"
  codesign --force --timestamp --options runtime \
    --entitlements macos/Runner/Release.entitlements \
    --sign "$MACOS_SIGNING_IDENTITY" \
    "$app"
  codesign --verify --strict --verbose=2 "$app"
  name="atril-macos"
else
  # An ad-hoc signature is what lets the bundle launch at all on the machine
  # that built it. It is not a distributable signature and the artifact's name
  # is what says so, because a file called atril-macos.zip that Gatekeeper
  # refuses is a bug report from somebody who was never told.
  echo "MACOS_SIGNING_IDENTITY is unset: signing ad hoc, this build is not distributable"
  codesign --force --sign - "$app"
  name="atril-macos-unsigned"
fi

if [[ -n ${MACOS_NOTARY_PROFILE:-} && -n ${MACOS_SIGNING_IDENTITY:-} ]]; then
  # Notarization takes a zip and staples the ticket back onto the bundle, so
  # the archive that ships is made after stapling and not before.
  echo "notarizing"
  ditto -c -k --keepParent "$app" "$out/notarize.zip"
  xcrun notarytool submit "$out/notarize.zip" \
    --keychain-profile "$MACOS_NOTARY_PROFILE" --wait
  xcrun stapler staple "$app"
  rm -f "$out/notarize.zip"
else
  echo "MACOS_NOTARY_PROFILE is unset: not notarizing, Gatekeeper will quarantine this build"
fi

# ditto rather than zip, because a .app is a directory whose symlinks and
# extended attributes are part of the signature.
ditto -c -k --keepParent "$app" "$out/$name.zip"
echo "wrote $out/$name.zip"
