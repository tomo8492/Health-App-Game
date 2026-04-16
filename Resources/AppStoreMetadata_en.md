# App Store Metadata Draft — English (en_US)

Paste into App Store Connect → App Information → Localizable Information → English (U.S.)

---

## App Name (30 chars)

```
VITA CITY: Health Pixel Town
```
Length: 27 / 30

---

## Subtitle (30 chars)

```
Healthy habits grow your city
```
Length: 29 / 30

---

## Promotional Text (170 chars)

```
🎉 Launch special! Premium features at a limited price. Log your steps,
meals, and sleep to grow your own pixel-art city. Streaks make your town
flourish day by day.
```
Length: 166 / 170

---

## Description (up to 4,000 chars)

```
VITA CITY turns your daily healthy habits into a charming pixel-art city
builder. Small steps today become a thriving town tomorrow.

■ Five Axes of Health
Track Exercise, Diet, Alcohol, Sleep, and Lifestyle for up to 500 CP
(City Points) per day. Steps and sleep are pulled automatically from
Apple Health, so most of your logging happens with a single tap.

■ Build as You Live
Use your CP to construct any of 28 unique buildings — gyms, organic
cafes, observatories, parks and more. Each building reflects a real
healthy habit. Your town levels up from 1 to 10 and the map expands up
to 50×50 tiles.

■ Weather that Reflects You
Hit 400 CP today and the sun shines. Fall below 100 and storms roll in.
Your streak builds a morning baseline, so consistent logging keeps the
skies clear even on off days.

■ Gentle Penalties, Positive Focus
Over-drinking temporarily spawns an "izakaya" and a "ruined building"
as a visual warning — but they fade as soon as you resume healthy logs.
VITA CITY is built to encourage, not to shame.

■ Premium (one-time purchase)
• Unlimited map expansion
• Full statistics history (free tier keeps 90 days)
• All widget sizes (free tier: small only)
• Detailed health reports
• Exclusive pixel-art themes
One payment, lifetime access. Family Sharing enabled.

■ Privacy First
All health data stays on your iPhone. Nothing is uploaded. No account
required — just open the app and start growing your town.

■ Perfect For
• People who struggle to stick with health apps
• Fans of cozy pixel-art and simulation games
• Anyone who wants to turn Apple Health data into something fun
• Habit-builders who love streaks

Every small step becomes a city block. Start building yours today.
```
Length: ~1,750 / 4,000

---

## Keywords (100 chars, comma-separated)

```
health,pedometer,habit tracker,sleep,fitness,pixel,city builder,simulation,wellness,diary,game
```
Length: 93 / 100

Do not include "VITA CITY" (it's already in the app name).

---

## Support URL

```
https://[your-domain]/vitacity/support
```

Or use GitHub Pages: `https://tomo8492.github.io/Health-App-Game/support_en.html`

---

## Marketing URL (optional)

```
https://[your-domain]/vitacity/
```

---

## Privacy Policy URL (required)

```
https://[your-domain]/vitacity/privacy_en.html
```

Use `AppStoreMetadata_privacy.md` as source.

---

## Age Rating

| Category | Answer |
|----------|--------|
| References to alcohol, tobacco, drugs | **No** (logging only, not promotion) |
| Gambling | No |
| Violence / sexual content | No |
| Unrestricted web access | No |

Expected rating: **4+**.

Conservative alternative: **12+** if Apple interprets alcohol logging strictly.

---

## Category

- **Primary**: Health & Fitness
- **Secondary**: Games > Simulation

---

## Pricing

- Base app: **Free**
- In-App Purchase (non-consumable): `com.vitacity.premium.lifetime`
  - Tier: **Tier 6 ($4.99 USD / ¥610 JPY)** — must match `VitaCity.storekit`
  - Family Sharing: **Enabled**

---

## Review Notes (App Store Review Information → Notes)

```
No demo account required. The app is fully functional without any login.

HealthKit usage:
- We read steps, active energy, workouts, and sleep analysis.
- All health data remains on-device. Nothing is transmitted to our servers
  or any third party.
- The NSHealthUpdateUsageDescription is present but we do not write to
  HealthKit; this key is included only because iOS requires it when the
  HealthKit entitlement is enabled.

In-App Purchase:
- Single non-consumable product: com.vitacity.premium.lifetime (Tier 6).
- Purchase is verified locally via StoreKit 2's Transaction.currentEntitlement(for:).
- "Restore Purchases" button is available on the premium screen.

Alcohol logging:
- VITA CITY allows users to log their own alcohol consumption for health
  tracking purposes. It does NOT sell, promote, or glorify alcohol.
- Over-consumption triggers a passive visual warning (izakaya / ruined
  building sprites) that disappears as soon as healthy logging resumes.

Contact: [your support email]
```
