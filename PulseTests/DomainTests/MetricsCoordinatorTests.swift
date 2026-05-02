//
//  MetricsCoordinatorTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Testing

@testable import Pulse

@Suite("Metrics Coordinator Tests")
@MainActor
struct MetricsCoordinatorTests {
    @Test("start updates latest snapshot and history")
    func startUpdatesSnapshotAndHistory() async throws {
        let coordinator = MetricsCoordinator(maxHistoryCount: 10)

        coordinator.start(interval: .milliseconds(50))
        try await Task.sleep(for: .milliseconds(180))
        coordinator.stop()

        #expect(coordinator.latestSnapshot != nil)
        #expect(!coordinator.history.isEmpty)
        #expect(coordinator.history.count <= 10)
    }

    @Test("history count does not exceed max count")
    func historyDoesNotExceedLimit() async throws {
        let coordinator = MetricsCoordinator(maxHistoryCount: 2)

        coordinator.start(interval: .milliseconds(20))
        try await Task.sleep(for: .milliseconds(180))
        coordinator.stop()

        #expect(coordinator.history.count <= 2)
    }

    @Test("updateInterval restarts sampling with new interval")
    func updateIntervalRestartsSampling() async throws {
        let coordinator = MetricsCoordinator(maxHistoryCount: 20)

        coordinator.start(interval: .milliseconds(250))
        try await Task.sleep(for: .milliseconds(100))
        let countBeforeUpdate = coordinator.history.count

        coordinator.updateInterval(.milliseconds(20))
        let deadline = Date().addingTimeInterval(1)
        while coordinator.history.count <= countBeforeUpdate && Date() < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        coordinator.stop()

        #expect(coordinator.history.count > countBeforeUpdate)
    }

    @Test("stop cancels sampling task")
    func stopCancelsSamplingTask() async throws {
        let coordinator = MetricsCoordinator(maxHistoryCount: 20)

        coordinator.start(interval: .milliseconds(30))
        try await Task.sleep(for: .milliseconds(120))
        coordinator.stop()
        let countAfterStop = coordinator.history.count

        try await Task.sleep(for: .milliseconds(120))

        #expect(coordinator.history.count == countAfterStop)
    }
}
