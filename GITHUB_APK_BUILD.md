# YOKA TECH — GitHub APK Build

1. Create a GitHub repository.
2. Upload the contents of this folder to the repository root.
3. Ensure `pubspec.yaml`, `lib/`, `android/`, and `.github/` are at the repository root.
4. Open **Actions** in GitHub.
5. Select **Build YOKA TECH Android APK**.
6. Click **Run workflow**.
7. Wait for the workflow to finish.
8. Open the completed workflow run.
9. Under **Artifacts**, download `yoka-tech-release-apk`.
10. Extract the downloaded artifact and install `app-release.apk` on Android.

The workflow builds an unsigned release APK suitable for testing/internal installation. For a Play Store release, configure Android signing secrets and a signed app bundle separately.
