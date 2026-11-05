# Working on Mind

Read README.md first: it has the vision, requirements and file format.
PORT.md has technical lessons from YMap, the predecessor; OLD-README.md is
YMap's README.

## Policies

- Write as little code as possible to get the job done; the owner reads it.
- Comments only where something isn't obvious from the code. Minimal docs.
- Record requests and design decisions in README.md (lines up to 80
  characters). Record state a new session needs that the code and git log
  don't show (blockers, half-done work, what was tested) in PROGRESS.md,
  append-only, one header per session.
- Ask the owner when a design choice is theirs to make.
- Commit after each working step, with a clear message.

## Build and test

```
swift test --package-path MindKit       # format logic, on the Mac
xcodegen generate                       # after changing project.yml
xcodebuild -project Mind.xcodeproj -scheme Mind-iOS \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' \
  -derivedDataPath build build
xcodebuild -project Mind.xcodeproj -scheme Mind-macOS \
  -derivedDataPath build build
```

Check UI changes yourself in the iPad simulator (`xcrun simctl`, screenshots)
before asking the owner to look on the device.

Owner's iPad (Pencil, iCloud), connected by USB:

```
D=00008103-001560CE01E3401E
xcodebuild -project Mind.xcodeproj -scheme Mind-iOS -destination "id=$D" \
  -derivedDataPath build -allowProvisioningUpdates build
xcrun devicectl device install app --device $D \
  build/Build/Products/Debug-iphoneos/Mind.app
xcrun devicectl device process launch --terminate-existing --device $D \
  com.calebyates.mind
```

Only one session at a time can install on the iPad.
