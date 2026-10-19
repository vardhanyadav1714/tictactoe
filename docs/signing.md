# Tic Tac Toe upload signing

The Android application ID remains `innovatixhub.in.tictactoe`.

## Files

| File | Purpose |
| --- | --- |
| `tictactoe.jks` | Private JKS upload keystore; RSA 2048-bit key, valid for 10,000 days |
| `tictactoe.pem` | Public upload certificate to provide in the Play Console reset form |
| `android/tictactoe.properties` | Private local signing configuration, with alias `tictactoe` |
| `android/tictactoe.properties.example` | Versioned template to restore signing configuration on another machine |
| `build/distributions/tictactoe.aab` | Signed Android App Bundle for Google Play |
| `build/distributions/tictactoe.apk` | Signed APK for local installation |

The certificate subject is `CN=InnovatixHub, OU=Mobile, O=InnovatixHub`. Keystore and key passwords are configured locally. Passwords are intentionally absent from the tracked documentation and example file.

Back up the keystore and its passwords somewhere private outside this checkout. Git does not contain the private key or password file, so cloning this repository alone will not restore release signing.

## Build

From the project directory on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-release.ps1
```

The script builds an AAB and an APK, then copies them to the filenames above. Flutter's standard `app-release.aab` and `app-release.apk` outputs remain available as well. Debug builds continue to use the standard Android debug key. Release builds fail if the private signing configuration is missing, rather than using a debug key.

To restore signing on another machine, copy the backed-up `tictactoe.jks` to the project root. Copy `android/tictactoe.properties.example` to `android/tictactoe.properties` and enter the passwords locally. The `storeFile` path is relative to the `android` directory.

## Submit an upload-key reset for an existing Play app

1. Sign into Google Play Console with the account allowed to manage this app's signing.
2. Select the existing app with package `innovatixhub.in.tictactoe`.
3. Open **Protected with Play → Play Store protection → Manage Play app signing**. Some console layouts show **App integrity → App signing** instead.
4. Under **Upload key certificate**, choose **Request upload key reset**, enter the reason, and upload `tictactoe.pem`.
5. Submit the request. Wait until Google confirms the new key is active before uploading an update signed with this keystore.

Upload the PEM certificate to the reset form. Keep the JKS and password properties private. An upload-key reset requires an existing app enrolled in Play App Signing; this does not replace an independently managed, lost app signing key.

If this is the new game's first Play upload, no lost-key reset is needed. Use `tictactoe.aab` for the first release and follow Play's signing setup. For an update, set a version code higher than every previously uploaded version. This rebuilt app uses version code 2 to update the original app's version code 1.

Reference: [Google Play App Signing and upload-key reset instructions](https://support.google.com/googleplay/android-developer/answer/9842756).

## Export or inspect the public certificate again

Use `keytool` from your JDK's `bin` directory. These commands prompt for the keystore password:

```powershell
keytool -exportcert -rfc -storetype JKS -keystore tictactoe.jks -alias tictactoe -file tictactoe.pem
keytool -printcert -file tictactoe.pem
```
