# MediaLab practice workspace

MediaLab is one small feed exercise to implement twice: once with SwiftUI and
once with Jetpack Compose. Both native projects intentionally launch as blank
screens. The application implementation is left entirely to the learner.

## Start here

```bash
./start-dev.sh
```

That command starts the finished backend, boots the simulators, and launches the
two blank starter apps. Run `./start-dev.sh --check` to inspect prerequisites
without starting anything.

Press `Ctrl-C`, close the terminal, or close either simulator to stop the
backend, terminate both apps, and shut down both emulators.

Build both apps and run their platform unit tests without opening simulator
windows or launching either app:

```bash
./build-test.sh
```

The current machines needs:

- Xcode with an installed iOS simulator runtime.
- Android Studio with SDK Platform 36+, an AVD, and its bundled JDK 17+.
- Node.js 20+.

The launcher uses the first bootable iPhone and the first Android AVD unless
`IOS_DEVICE` or `ANDROID_AVD` is set.

## Workspace

- `backend/` — completed dependency-free Node feed API, image generation,
  video proxy/cache, range requests, latency, and failure simulation.
- `ios/` — blank SwiftUI application shell.
- `android/` — blank Jetpack Compose application shell.
- `docs/APP_SPEC.md` — feed-only requirements and concurrency acceptance criteria.
- `docs/API_CONTRACT.md` — feed and media HTTP contract.
- `docs/feed-iphone-mock.png` — feed-only iPhone product mock.

## Useful commands

```bash
./scripts/server.sh
./scripts/ios.sh build
./scripts/ios.sh test
./scripts/ios.sh launch
./scripts/android.sh build
./scripts/android.sh test
./scripts/android.sh launch
./scripts/test-backend.sh
```

The API is available at `http://localhost:8080`. Android emulators reach the
host at `http://10.0.2.2:8080`.
