import Testing

@testable import AemiTesting

/// Compatibility coverage for semaphore permits and cancellation.
@Suite("AsyncSemaphore")
struct AsyncSemaphoreTests {

    @Test func waitReturnsImmediatelyWhenPermitAvailable() async throws {
        let sem = AsyncSemaphore(value: 1)
        try await sem.wait()  // consumes the pre-loaded permit
    }

    @Test func waitSuspendsUntilSignal() async throws {
        let sem = AsyncSemaphore()
        let task = Task { try await sem.wait() }
        sem.signal()
        try await task.value
    }

    @Test func signalIncrementsWhenNoWaiters() async throws {
        let sem = AsyncSemaphore()
        sem.signal()
        sem.signal()
        try await sem.wait()
        try await sem.wait()
    }

    @Test func `each signal releases one concurrent waiter`() async throws {
        let sut = AsyncSemaphore()
        let resumed = CountProbe<Int>()
        let count = 4

        try await withThrowingTaskGroup(of: Void.self) { group in
            defer { group.cancelAll() }
            for index in 0..<count {
                group.addTask {
                    try await sut.wait()
                    resumed.record(index)
                }
            }
            for expected in 1...count {
                sut.signal()
                try await resumed.wait(forAtLeast: expected)
            }
            try await group.waitForAll()
        }
        #expect(resumed.count == count)
        #expect(Set(resumed.events) == Set(0..<count))
    }

    @Test func cancellationDoesNotConsumePermit() async throws {
        let sem = AsyncSemaphore()
        let task = Task { try await sem.wait() }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        // The cancellation should not have consumed a permit.
        // Signal once and a fresh wait must succeed.
        sem.signal()
        try await sem.wait()
    }
}
