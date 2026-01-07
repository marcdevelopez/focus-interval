# Android Setup Notes

This project uses Firebase Auth with Google Sign-In on Android. Debug builds are
signed with a per-user debug keystore, so fingerprints change when:
- You switch OS users.
- You delete or regenerate `~/.android/debug.keystore`.
- You use a different machine.

## Debug keystore fingerprints

Get the SHA-1/SHA-256 of your local debug keystore and add them to the Android
app in Firebase Console:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

After updating Firebase, download the new `google-services.json` and replace:
`android/app/google-services.json`.

## Google Sign-In debug troubleshooting (Android)

Use this sequence when Google Sign-In fails after switching users or machines:

1. Confirm the Android `applicationId` matches the Firebase package name.
2. Get the SHA-1 and SHA-256 from your local debug keystore:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

3. Add both SHA-1 and SHA-256 in Firebase Console.
4. Download a NEW `google-services.json`.
5. Replace `android/app/google-services.json`.
6. Rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

Expected result:
- Google Sign-In opens the account selector.
- Auth succeeds and the session is persisted.

Rules of thumb:
- Each debug keystore implies new SHA values.
- New Mac, new OS user, or new CI runner = new SHA values.
- When SHA values change, always download a new `google-services.json`.

## Debug vs release keys

- The debug keystore is auto-generated per user/machine and is NOT used for production.
- Production builds are signed with a separate release (or upload) keystore configured for release.
- Losing the debug keystore only affects local debug sign-in; losing the release keystore blocks production updates.

## Release keystore

Release builds use a separate keystore. Its fingerprints should be added once
and shared securely with the team.

IMPORTANT:
- Do not commit the release keystore or its fingerprints to the repo.
- If the release keystore is lost, you cannot update the app in production.
- If you use Google Play App Signing, you still need the upload keystore to
  publish new versions.

Backup guidance:
- Store the release keystore and credentials in a secure vault (1Password,
  Bitwarden, encrypted disk, or a private secrets manager).
- Verify that at least two trusted team members can recover it.

Reminder for new setups:
- If release keystore backup is not confirmed, stop and ask before shipping.
