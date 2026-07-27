# MediaLab feed exercise

## Goal and time box

Implement the same single media-feed screen in SwiftUI and Jetpack Compose using
MVVM and structured concurrency. Budget approximately half a day per platform.
The native projects deliberately contain no feed implementation.

The product has one screen, no detail page, no video player, no downloads, no
offline database, no tabs, and no navigation.

Use `feed-iphone-mock.png` as the visual target.

## Feed requirements

- Show the title “Field notes”.
- Show a search field that filters by title, summary, or tag.
- Load cards from `GET /v1/items`.
- Each card displays its poster image, title, summary, tags, and media kind.
- Pull to refresh reloads the current query.
- Search is debounced by 300 milliseconds.
- Include a Chaos toggle. When enabled, send chaos level 2 to the backend.
- Show four explicit states: initial loading, content, empty results, and error
  with retry.
- Keep the UI responsive while requests and image work are running.

## MVVM ownership

- The view renders immutable state and sends user actions.
- The ViewModel owns the current feed request and search debounce.
- A repository owns HTTP access.
- An image loader owns poster fetching and memory caching.
- Work must be cancelled when it is replaced or when its owning ViewModel ends.

## Required multithreading behavior

This is the core of the exercise, not an optional optimization.

1. Fetch feed JSON away from the main UI executor.
2. After the feed arrives, load visible poster images concurrently.
3. Limit poster work to at most four simultaneous requests.
4. Decode and cache image data away from the main UI executor.
5. Publish rendered state only on the main actor or main dispatcher.
6. When the search text changes, cancel the previous debounce and request.
7. Enforce latest-query-wins: an older response must never replace newer data.
8. Pull to refresh must cancel or supersede the current feed request.
9. Cancellation must be cooperative and must not appear as a user-facing error.
10. Two rows requesting the same image URL must share one in-flight request.

## Swift ↔ Kotlin learning map

| Concern | Swift | Kotlin |
|---|---|---|
| Screen-owned work | Task owned by the ViewModel | viewModelScope coroutine |
| Latest-wins search | cancellation plus task replacement | debounce plus mapLatest |
| Parallel posters | task group | coroutine scope plus async |
| Limit of four | actor-isolated permit controller | coroutine semaphore |
| UI state | main actor | main dispatcher and StateFlow |
| Shared image request | actor-protected task registry | mutex-protected deferred registry |

The names above identify concepts to practice; they are not prescribed project
structure. Keep the two implementations idiomatic to their platform.

## Acceptance checks

- Typing quickly never flashes results for an older query.
- With Chaos enabled, the interface remains interactive during server latency.
- Instrumentation shows no HTTP or image decoding work on the main thread.
- Network inspection never shows more than four active poster requests.
- Leaving and recreating the screen does not publish state from abandoned work.
- Refreshing five times quickly ends with one authoritative result.
- Backend failure shows retry; cancellation does not.
- iOS and Android expose equivalent user-visible behavior.

## Suggested half-day sequence

1. Define models, feed state, repository contract, and ViewModel.
2. Render the four states with static rows.
3. Connect the feed request and pull to refresh.
4. Add debounced, latest-wins search.
5. Add bounded concurrent image loading and memory caching.
6. Turn on Chaos mode and verify every acceptance check.
