---
name: ios-testing
description: VITA CITY iOS testing expert. Use when writing Swift Testing / XCTest unit tests, reviewing test coverage, or implementing TDD for CPPointCalculator, StreakManager, or Repository layers.
allowed-tools: Read, Grep, Glob
---

# iOS Testing Expert — VITA CITY

## Project Context
- Test framework: Swift Testing (preferred) + XCTest for UI tests
- Mandatory coverage: CPPointCalculator (all calculation paths), StreakManager (archive logic), Repository implementations
- Build command: `xcodebuild test -scheme VitaCity -destination 'platform=iOS Simulator,name=iPhone 16'`

## Key Test Targets

### CPPointCalculator (highest priority)
Every combination in the CP table must be covered:
- Exercise: 0 steps / 5000 steps / 10000+ steps / with workout / without workout
- Diet: 0/1/2/3 meals rated / with or without snack
- Alcohol: none (100 CP) / moderate (60 CP) / excessive (penalty, floor 0)
- Sleep: <5h / 5h / 6h / 7-9h (ideal) / >9h
- Lifestyle: water count 0-8 / stress levels / habit completions
- Daily cap: assert totalCP never exceeds 500

### StreakManager
- `currentStreak()`: 0 days / consecutive days / gap in records
- `archiveOldRecords()`: records ≤90 days untouched / records >90 days archived (isArchived=true) / premium bypass

### Repository Layer
- Inject mock ModelContext to test CRUD without real SwiftData container
- Test error propagation (corrupt data, missing records)

## Instructions
1. Read the target source file(s)
2. Identify untested branches — focus on edge cases and error paths
3. Generate Swift Testing (@Test, @Suite) test cases
4. Keep tests pure: no network, no HealthKit, no real StoreKit
5. Use dependency injection — never instantiate real repositories in unit tests

## Best Practices
- Test behavior, not implementation details
- One assertion concept per test function
- Use #expect() for assertions in Swift Testing
- Name tests in Given/When/Then or Should/When style
- Mock HealthKitServiceProtocol, DailyRecordRepositoryProtocol via protocol substitution
