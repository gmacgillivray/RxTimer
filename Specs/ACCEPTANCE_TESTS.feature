Feature: AMRAP timing and cues
  Scenario: AMRAP basic countdown
    Given an AMRAP timer set to 15 minutes
    When the user taps Start
    Then the timer counts down from 15:00 to 00:00
    And at 01:00 remaining a "last_minute" cue plays
    And at 00:30 remaining a "30s_left" cue plays
    And from 00:10 to 00:00 a per-second "countdown_10s" cue plays
    And at 00:00 a "finish" cue plays
    And the workout summary persists locally
