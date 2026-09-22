# Breaker HD

**Tiny resets. Back to the thing.** Start the task you already know you need to do. When your brain wants novelty, tap one button for a deliberately tiny reset, then return to the task.

## Add to AltStore

Copy this source URL and add it in AltStore's **Sources** tab:

```text
https://raw.githubusercontent.com/c15c/BreakerHD/main/altstore-source.json
```

Once the first GitHub Actions build finishes, **Breaker HD** will appear in the source and install through AltStore. The source points to the unsigned IPA attached to the `v0.1.0` GitHub release; AltStore signs it during installation.

## MVP

- One task, one timer and one escape button
- Six personalised 5–10 second novelty bursts
- Automatic return so the reset cannot become the distraction
- Local-only escape-signature learning and lightweight proactive nudges
- Haptic, sound and intervention preferences
- No accounts, ads, analytics, streaks, coins or cloud data

## Build pipeline

Every push to `main` builds an unsigned iPhoneOS app, packages `BreakerHD.ipa`, uploads it as a workflow artifact and publishes it to the `v0.1.0` release for the AltStore source.

Requires iOS 17 or later. Bundle identifier: `com.c15co.breakerhd`.

## Product guardrails

Breaker HD is designed as a focus aid, not medical treatment. Interventions are brief, finite and non-scrollable. User data remains on-device.
