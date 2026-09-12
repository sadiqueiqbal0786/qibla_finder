# Google Play updates

Version 2.2.0+13 adds Google Play flexible in-app updates. On launch/resume,
Play checks whether a newer version is available to the signed-in user. Its
consent prompt allows a background download, followed by an app restart prompt.
The same version is offered at most once per 24 hours. A newly available version
can prompt immediately. Offline checks and non-Play installs fail harmlessly.

Publish this version first: versions already installed without this feature
cannot show the new prompt. Increase the build number after `+` in pubspec.yaml
for every future Play upload. Availability follows Play processing, testing
track eligibility, and staged rollout eligibility; this is not a push alert
while the app is closed.

Validation on Play:
1. Install this build from an internal testing track using an eligible account.
2. Publish a higher version code to that track with the same application ID and
   signing configuration.
3. Open the older app and accept or dismiss the update prompt.
4. Verify background download, the restart prompt, and the installed version.
5. Verify a downloaded update is offered for completion after reopening the app.

A debug APK build verifies compilation but cannot validate Play eligibility.
Reference: https://developer.android.com/guide/playcore/in-app-updates/kotlin-java

# Friday display

On Friday, calculated Dhuhr is labelled “Jumma / Dhuhr” in the prayer list,
next-prayer card, and scheduled notification. Calculation and reminder times
remain Dhuhr's start time. The Friday screen explains that mosque congregation
times may differ. No manual configuration or extra reminder is required.
