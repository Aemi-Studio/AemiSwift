# AemiSwift

Battle-tested Swift testing helpers for async/concurrent code on Apple
platforms. Four typed primitives that replace `Task.sleep`,
`Task.yield`, and `Task.megaYield` with deterministic, event-driven
rendezvous through Swift Concurrency's continuation machinery.

## Why

Wall-clock waits (`Task.sleep(for: .milliseconds(400))`) and
best-effort drains (`Task.megaYield`) are intrinsically flaky in a
parallel test target — under load the MainActor can be starved for
seconds and any "wait N ms then assert" pattern silently runs against
not-yet-settled state. `Task.yield()` between operations papers over
ordering bugs without fixing them.

The primitives in `AemiTesting` route entirely through
`CheckedContinuation` + `Synchronization.Mutex`. They resume the
awaiting test the *instant* the production side fires the signal —
no polling, no timeout, no scheduler dependency.

## Primitives

```swift
import AemiTesting

// 1. Single-shot continuation barrier.
//    Production fires once; test awaits once.
let gate = TaskGate()
controller.scheduleCommit { gate.open() }
try await gate.wait()

// 2. Counting semaphore.
//    Production fires N times; test awaits each occurrence.
let sem = AsyncSemaphore()
undoController.onDidCommit = { _ in sem.signal() }
viewModel.updateExposure(1.0)
viewModel.updateContrast(0.5)
try await sem.wait()  // first commit
try await sem.wait()  // second commit

// 3. Typed signal buffer with synchronous quiescent assertion.
//    Production sends typed events; test consumes + asserts "no more".
let probe = AsyncProbe<EditSnapshot>()
undoController.onDidCommit = { snapshot in probe.send(snapshot) }
// ... trigger debounced work ...
_ = try await probe.next()
try probe.expectNoBufferedElements()  // exactly-one assertion

// 4. Virtual Clock with explicit rendezvous.
//    Production sleeps; test advances time deterministically.
let clock = TestClock()
let controller = UndoController(clock: clock)
let gate = TaskGate()

controller.scheduleCommit(delayMilliseconds: 50) { gate.open() }
try await clock.waitForSleepers()           // production reached sleep
clock.advance(by: .milliseconds(50))        // drain the sleeper
try await gate.wait()                       // post-sleep signal
```

## Why `waitForSleepers` (not `Task.yield`)

`Clock.sleep(for:)` computes its deadline as `clock.now + duration` at
the moment sleep is called. If the test calls `advance(by:)` before the
spawned Task has reached `sleep`, the clock moves but no sleeper is
queued — and when the Task finally calls `sleep`, the new deadline
lives in the future relative to the already-advanced clock, so the
sleeper waits forever.

`Task.yield()` before `advance` "fixes" this in practice but is
non-deterministic under load. `waitForSleepers(count:)` is a
`CheckedContinuation` resolved *only* when the requested number of
additional sleepers have been appended to the queue — pure
event-driven rendezvous, scheduler-independent.

## "N more" semantics

`waitForSleepers(count: N)` waits for N **additional** sleepers past
whatever was queued at registration time. Mid-test composition (test
already gated on one sleeper, then wants to wait for the next 2) is
the canonical case; a queue-size threshold would trip immediately on
existing entries.

## Integration patterns

The primitives are pure (no `@testable` requirement). The *integration
sites* in your production code typically need test-only hook surfaces:

```swift
@MainActor
final class UndoController {
    /// Test-only hook fired after every successful commit.
    /// Production leaves it `nil`.
    var onDidCommit: ((EditSnapshot) -> Void)?

    func commit(_ snapshot: EditSnapshot) {
        // ... commit work ...
        onDidCommit?(snapshot)
    }
}
```

Test side:

```swift
let probe = AsyncProbe<EditSnapshot>()
controller.onDidCommit = { probe.send($0) }
```

For clock injection, accept `any Clock<Duration>` in production
inits:

```swift
final class UndoController {
    private let clock: any Clock<Duration>
    init(clock: any Clock<Duration> = ContinuousClock()) {
        self.clock = clock
    }
}
```

Tests pass `TestClock()` and step time with `clock.advance(by:)`.

## Cancellation

All four primitives are cancellation-aware. Cancelled awaits throw
`CancellationError` at the call site (via
`withTaskCancellationHandler` removing the waiter from its queue and
resuming with the error) — no roundabout `try Task.checkCancellation()`
downstream.

## Provenance

Iteratively refined across two production codebases (Luce + Ful) by
two Claude Code sessions coordinating live via ClaudeTalk MCP.
Canonical design decisions:

- **`<Void, any Error>` continuation type** — cleaner cancellation
  surface than `<Void, Never>` with a downstream `checkCancellation`
  dance. Error surfaces at the actual call site.
- **Per-waiter "N more" decrement** — matches the human intent of
  every realistic call site (rationale above).
- **Resume continuations outside the lock** — non-negotiable safety
  property; resuming inside `Mutex.withLock` can re-enter the
  awaiter's actor while the lock is held, deadlocking the system.
- **Synchronous `expectNoBufferedElements`** — atomic drain + finish
  under one lock acquisition; pair with a deterministic settle point
  rather than relying on quiescence guessing.

## Requirements

- Swift 6.0+
- iOS 18 / macOS 15 / tvOS 18 / watchOS 11 / visionOS 2
  (baseline driven by `Synchronization.Mutex`)

## License

MIT.
