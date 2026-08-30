import Foundation

/// Schedules a delayed UI clear on the main actor and cancels prior work to avoid
/// overlapping updates or leftover tasks after a view disappears.
@MainActor
final class DeferredUIAction {
    private var task: Task<Void, Never>?

    func schedule(after delay: Duration, action: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            action()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
