# Zonn App Store Submission Checklist

Last updated: January 2026

## Pre-Submission Requirements

### App Archive
- [ ] Build with Release configuration
- [ ] Archive created via Xcode (Product > Archive)
- [ ] App validated successfully in Xcode Organizer
- [ ] No warnings or errors in validation

### Code Signing
- [ ] Developer ID certificate installed
- [ ] App signed with correct provisioning profile
- [ ] Entitlements configured correctly:
  - `com.apple.security.app-sandbox` - Required for Mac App Store
  - `com.apple.security.automation.apple-events` - Required for Spotify integration
  - `com.apple.security.network.client` - Required for loading album artwork
  - `com.apple.security.files.user-selected.read-write` - For sandbox file access

### App Icon
- [ ] 1024x1024 App Store icon in Assets.xcassets
- [ ] Icon follows Apple Human Interface Guidelines (no transparency, rounded corners applied automatically)
- [ ] Icon is distinctive and recognizable at small sizes

### Minimum System Requirements
- [ ] **Deployment Target:** macOS 14.0 (Sonoma)
- [ ] Document this in App Store description if targeting newer macOS only
- [ ] Test on minimum supported macOS version

### Notarization (handled automatically by App Store)
- [ ] Note: Apps submitted to Mac App Store are automatically notarized
- [ ] For direct distribution outside App Store, manual notarization would be required

### Spotify Integration Considerations
- [ ] Ensure `NSAppleEventsUsageDescription` is in Info.plist (explains permission to user)
- [ ] Test that Spotify automation works with sandbox enabled
- [ ] Prepare to explain Spotify integration to App Review team (already in reviewer notes)

---

## App Store Connect Setup

### App Information
- [ ] **App Name:** Zonn (verify availability in App Store Connect)
- [ ] **Subtitle:** Focus Timer for Deep Work (30 characters max)
- [ ] **Primary Language:** English (U.S.)
- [ ] **Bundle ID:** app.zonn.Zonn
- [ ] **SKU:** zonn-focus-timer-001 (unique identifier for your records)

### Category Selection
- [ ] **Primary Category:** Productivity
- [ ] **Secondary Category:** Lifestyle (optional)

---

## App Store Listing Content

### App Description (4000 characters max)
```
Zonn helps you achieve deep focus with beautifully designed timer sessions.

KEY FEATURES:

Minimalist Menu Bar App
- Lives quietly in your menu bar
- One-click access to start focus sessions
- Unobtrusive design that stays out of your way

Pomodoro-Style Focus Sessions
- Default 25-minute focus sessions
- Customizable session durations
- Visual tree growth animation during sessions
- Motivational messages to keep you on track

Session History & Statistics
- Track your daily focus time
- View session history with labels
- Monitor your productivity trends

Spotify Integration
- Automatically pauses Spotify when you start a session
- Resumes playback when your break begins
- See currently playing track info

Focus Mode Panel
- Dedicated distraction-free focus window
- Beautiful tree growth visualization
- Ambient design for better concentration

Perfect for students, professionals, writers, developers, and anyone who wants to reclaim their focus in a distracted world.

Download Zonn and start your focused work session today.
```

### Keywords (100 characters max, comma-separated)
```
focus,timer,pomodoro,productivity,concentration,deep work,study,flow state,time management,work
```

### What's New (Version 1.0.0)
```
Initial release of Zonn - your minimalist focus timer for Mac.

- Pomodoro-style focus sessions
- Menu bar quick access
- Session history tracking
- Spotify integration
- Beautiful tree growth animation
```

### Promotional Text (170 characters max, can be updated without new version)
```
Start your focus journey with Zonn. A beautiful, minimalist timer that helps you achieve deep work and track your productivity progress.
```

---

## Required Screenshots

### Mac App Store Screenshot Specifications

| Size | Resolution | Required |
|------|------------|----------|
| 16:10 | 1280 x 800 pixels | Yes (minimum 1 required) |
| 16:10 | 1440 x 900 pixels | Optional |
| 16:10 | 2560 x 1600 pixels | Recommended |
| 16:10 | 2880 x 1800 pixels | Recommended for Retina |

### Screenshot Suggestions (1-10 screenshots)
1. **Menu Bar Timer** - Show the app in the menu bar with timer running
2. **Focus Panel** - Full focus panel with tree animation at mid-growth
3. **Session Complete** - Completed session with fully grown tree
4. **History View** - Session history list showing tracked sessions
5. **Statistics** - Daily/weekly focus time statistics
6. **Spotify Integration** - Focus panel showing Spotify track info

### Screenshot Tips
- Use clean desktop backgrounds
- Show realistic usage scenarios
- Ensure text is readable at thumbnail size
- Consider adding subtle device frames
- Use consistent visual style across all screenshots

---

## App Preview Video (Optional)
- **Duration:** 15-30 seconds recommended
- **Resolution:** Same as screenshots (up to 1920 x 1080)
- **Format:** H.264, 30fps
- **Audio:** Optional but recommended
- **Content Ideas:**
  - Starting a focus session from menu bar
  - Tree growing during focus session
  - Completing session and seeing stats
  - Spotify integration in action

---

## Required URLs

### Support URL (Required)
- [ ] Create support page/website
- [ ] Include contact method (email or form)
- [ ] Add FAQ section
- Suggested: GitHub Pages, Notion page, or simple landing page

### Privacy Policy URL (Required)
- [ ] **Update placeholder email** in PRIVACY_POLICY.md (currently `[your-email@example.com]`)
- [ ] Host PRIVACY_POLICY.md content online
- [ ] Ensure URL is publicly accessible
- [ ] Verify URL loads correctly before submission
- Options:
  - GitHub repository (raw or rendered): `https://github.com/username/repo/blob/main/PRIVACY_POLICY.md`
  - GitHub Pages
  - Personal website
  - Notion public page

### Marketing URL (Optional)
- [ ] Landing page for the app
- [ ] Include screenshots, features, download link

---

## Export Compliance

App Store Connect will ask about encryption usage:

| Question | Answer for Zonn |
|----------|-----------------|
| Does your app use encryption? | Yes (HTTPS for album artwork) |
| Does your app qualify for any exemptions? | Yes |
| Exemption type | Standard HTTPS/TLS (exempt) |

**Note:** Apps using only standard HTTPS/TLS are exempt from export documentation requirements.

- [ ] Complete Export Compliance questionnaire in App Store Connect
- [ ] Select "Yes" for encryption, then "Yes" for exemption (standard HTTPS)

---

## Age Rating Questionnaire

Answer these questions in App Store Connect:

| Question | Answer for Zonn |
|----------|-----------------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Mature/Suggestive Themes | None |
| Simulated Gambling | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Unrestricted Web Access | No |
| Gambling with Real Currency | No |

**Expected Rating:** 4+ (suitable for all ages)

---

## App Review Information

### Contact Information
- [ ] First Name
- [ ] Last Name
- [ ] Phone Number
- [ ] Email Address

### Demo Account (if applicable)
- Not required for Zonn (no login functionality)

### Notes for Reviewer
```
Zonn is a menu bar focus timer app. To test:

1. Launch the app - it appears as a clock icon in the menu bar
2. Click the menu bar icon to see the timer interface
3. Click the play button to start a 25-minute focus session
4. The tree animation shows progress during the session
5. Click the expand button to open the dedicated Focus Panel
6. View session history by clicking the list icon

Spotify Integration:
- If Spotify is running, Zonn can pause/resume playback
- This requires the Automation permission (granted on first use)
- The app uses AppleScript for Spotify control, no API access needed

Note: The app runs in the menu bar only (LSUIElement = true), so there is no Dock icon by design.
```

---

## Pricing & Availability

### Pricing
- [ ] Select price tier (Free or Paid)
- [ ] Consider offering free with optional tip jar (future feature)

### Availability
- [ ] Select countries/regions
- [ ] Recommended: All countries where Mac App Store is available
- [ ] Release date: Manual release or Automatic after approval

### Pre-Orders (Optional)
- [ ] Enable if you want to build anticipation
- [ ] Set pre-order release date

---

## Final Submission Checklist

### Before Submitting
- [ ] All screenshots uploaded
- [ ] App description complete and proofread
- [ ] Keywords optimized
- [ ] Privacy policy URL accessible
- [ ] Support URL accessible
- [ ] Age rating completed
- [ ] App information filled out
- [ ] Contact information provided
- [ ] Review notes added
- [ ] Pricing set
- [ ] Build uploaded via Xcode or Transporter
- [ ] Build selected for submission

### After Submission
- [ ] Monitor App Store Connect for status updates
- [ ] Check email for review feedback
- [ ] Prepare to respond quickly if reviewer has questions
- [ ] Plan marketing activities for launch

---

## Common Rejection Reasons to Avoid

1. **Crashes or bugs** - Test thoroughly on different Mac models
2. **Incomplete information** - Fill out all required fields
3. **Placeholder content** - Remove any "lorem ipsum" or test data
4. **Privacy issues** - Ensure privacy policy matches actual data usage
5. **Misleading metadata** - Screenshots and descriptions must match functionality
6. **Guideline 4.2 (Minimum Functionality)** - Ensure app provides sufficient value

---

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Marketing Resources](https://developer.apple.com/app-store/marketing/guidelines/)
