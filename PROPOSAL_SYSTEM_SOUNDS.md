# Proposal: Replace Voice-Based Audio with iOS System Sounds

## Current Issue

**Problem**: Voice-based countdown sounds ("Three", "Two", "One", "Go") are not aligned with on-screen text and create timing inconsistencies during workout countdowns.

**User Feedback**: Request to change from words to system sounds for better timing precision and cleaner audio experience.

## Current Audio Implementation

| Event | Current Audio | Duration | Issue |
|-------|--------------|----------|-------|
| countdown_3 | "Three" voice | ~0.3-0.4s | Variable duration, may lag text |
| countdown_2 | "Two" voice | ~0.2-0.3s | Variable duration, may lag text |
| countdown_1 | "One" voice | ~0.2-0.3s | Variable duration, may lag text |
| start | "Go" voice | ~0.2-0.3s | Variable duration |
| interval_tick | tick.caf | ~0.1s | (Keep as is) |
| last_minute | warn.caf | ~0.1s | (Keep as is) |
| 30s_left | warn.caf | ~0.1s | (Keep as is) |
| finish | end.caf | ~0.1s | (Keep as is) |

## Proposed Solution: iOS System Sounds

Replace voice countdown with **iOS System Sounds** using `AudioServicesPlaySystemSound()` API.

### Benefits

1. **Zero Latency**: System sounds play instantly, no file loading
2. **Perfect Timing**: Consistent duration, always aligned with text changes
3. **System Integration**: Uses iOS native audio system (respects silent mode, ringer volume)
4. **Zero Dependencies**: No audio file generation needed
5. **Smaller App Size**: Remove voice .caf files from bundle
6. **Consistent Experience**: Familiar sounds users recognize from iOS

### Recommended System Sound Mappings

#### Option A: Classic Beep Progression (Recommended)

| Event | System Sound ID | Sound Name | Description |
|-------|----------------|------------|-------------|
| countdown_3 | 1103 | SMS Received 3 | Low pitch beep |
| countdown_2 | 1104 | SMS Received 4 | Medium pitch beep |
| countdown_1 | 1105 | SMS Received 5 | Higher pitch beep |
| start | 1057 | Tock | Sharp, attention-getting click |

**Rationale**: Ascending pitch creates natural progression toward "start". Each sound is distinct and recognizable.

#### Option B: Minimal Single-Tone

| Event | System Sound ID | Sound Name | Description |
|-------|----------------|------------|-------------|
| countdown_3 | 1104 | SMS Received 4 | Standard beep |
| countdown_2 | 1104 | SMS Received 4 | Same beep (rhythm-based) |
| countdown_1 | 1104 | SMS Received 4 | Same beep (rhythm-based) |
| start | 1057 | Tock | Different sound for "go" |

**Rationale**: Single repeating tone focuses user on rhythm/timing. Start sound clearly distinguishes beginning of workout.

#### Option C: iOS Camera Shutter Pattern

| Event | System Sound ID | Sound Name | Description |
|-------|----------------|------------|-------------|
| countdown_3 | 1108 | SMS Received 6 | Soft tone |
| countdown_2 | 1108 | SMS Received 6 | Soft tone |
| countdown_1 | 1108 | SMS Received 6 | Soft tone |
| start | 1108 | Camera Shutter | Distinctive "capture" sound |

**Rationale**: Non-intrusive countdown with clear action sound on start.

### System Sounds Reference

Common iOS System Sound IDs:
- **1103-1108**: SMS/Alert tones (short, clean beeps)
- **1057**: Tock (mechanical click)
- **1309**: Begin video recording (subtle whoosh)
- **1013**: Low power alert (attention-getting)
- **1005**: New mail alert (pleasant ding)
- **1000-1002**: Mail sent, swoosh sounds

## Implementation Plan

### Phase 1: Update AudioService (Estimated: 15 minutes)

**File**: `Sources/Services/AudioService.swift`

1. Add system sound playback method:
```swift
func playSystemSound(_ soundID: SystemSoundID) {
    AudioServicesPlaySystemSound(soundID)
}
```

2. Create event-to-sound mapping:
```swift
private let systemSoundMap: [String: SystemSoundID] = [
    "countdown_3": 1103,
    "countdown_2": 1104,
    "countdown_1": 1105,
    "start": 1057
]
```

3. Update `play(sound:)` method to check system sound map first

### Phase 2: Update TimerViewModel (Estimated: 5 minutes)

**File**: `Sources/UI/ViewModels/TimerViewModel.swift`

Lines 545-552: No changes needed (event names stay the same)

### Phase 3: Clean Up Audio Files (Estimated: 5 minutes)

**Files to Remove**:
- `Resources/Audio/three.caf`
- `Resources/Audio/two.caf`
- `Resources/Audio/one.caf`
- `Resources/Audio/go.caf`

**Files to Keep**:
- `Resources/Audio/tick.caf`
- `Resources/Audio/warn.caf`
- `Resources/Audio/end.caf`
- `Resources/Audio/beep_1hz.caf`
- `Resources/Audio/start.caf`

### Phase 4: Update Documentation (Estimated: 5 minutes)

**File**: `Specs/EVENTS_TO_CUES.md`

Update audio column to reference system sound IDs instead of file names.

### Phase 5: Update Audio Generation Script (Estimated: 5 minutes)

**File**: `Resources/Audio/generate_audio.sh`

Remove countdown voice generation sections (lines 46-62).

## Testing Plan

1. **Countdown Timing**: Start timer, verify sounds play exactly when text changes
2. **System Volume**: Test with various ringer volume levels
3. **Silent Mode**: Verify sounds respect silent switch (or decide if they should override)
4. **Rapid Fire**: Test EMOM with frequent interval changes
5. **Background**: Verify sounds play when app is backgrounded (if applicable)

## Trade-offs Analysis

### Pros
- ✅ Perfect timing alignment with text
- ✅ Zero latency playback
- ✅ Smaller app bundle size (~100KB savings)
- ✅ No audio file generation needed
- ✅ iOS-native integration
- ✅ Consistent across devices

### Cons
- ❌ Less semantic (beeps vs. "Three, Two, One")
- ❌ May not be as clear for vision-impaired users (but VoiceOver still speaks text)
- ❌ Limited customization (system sounds are fixed)
- ❌ Sounds may change across iOS versions

### Accessibility Considerations

**VoiceOver**: Still announces "Three", "Two", "One", "Go!" via text labels
**Haptics**: Remain unchanged (light, light, light, rigid)
**Visual**: Text display primary indicator

System sounds serve as **auditory reinforcement**, not primary communication. VoiceOver provides semantic information.

## Alternative: Hybrid Approach

Keep voice for accessibility, add option to switch:

```swift
enum CountdownAudioStyle {
    case voice      // Current: "Three", "Two", "One", "Go"
    case systemSound // Proposed: System beeps
    case hapticOnly  // Silent, haptics only
}
```

**Decision**: Recommend **Option A (Classic Beep Progression)** as default, with potential future setting to allow user preference.

## Recommendation

**Proceed with Option A: Classic Beep Progression**

- Uses system sounds 1103 → 1104 → 1105 → 1057
- Ascending pitch creates natural countdown feel
- Start sound (1057 Tock) is distinctly different
- Zero latency ensures perfect text/audio sync
- Maintains haptic + VoiceOver for full accessibility

**Estimated Total Implementation Time**: 35 minutes
**Risk Level**: Low (easy to revert if sounds not satisfactory)

## Open Questions

1. **Silent Mode Behavior**: Should countdown sounds override silent switch, or respect it?
   - Recommendation: Respect silent switch for courtesy, rely on haptics + visual

2. **Custom Sounds**: Should we keep option to load custom sounds in future?
   - Recommendation: Start with system sounds, add customization later if requested

3. **Keep Voice Files**: Should voice files remain in project for potential future use?
   - Recommendation: Remove to reduce bundle size, can regenerate if needed

## Next Steps

**If Approved**:
1. Implement AudioService system sound support
2. Test Option A sound progression
3. If sounds are satisfactory, remove voice files
4. Update documentation
5. Commit changes

**If Modifications Needed**:
- Try Option B or C
- Test specific system sound IDs user prefers
- Adjust implementation accordingly

---

**Awaiting User Approval**: Please review and confirm which option to implement, or request modifications.
