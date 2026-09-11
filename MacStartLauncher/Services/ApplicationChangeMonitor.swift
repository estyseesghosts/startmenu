import Foundation

/// Watches the standard application locations and reports debounced changes.
///
/// Used to pick up applications being installed or removed while the launcher
/// is running.
final class ApplicationChangeMonitor {
    private let roots: [URL]
    private let onChange: () -> Void
    private let debounceInterval: TimeInterval
    private let queue: DispatchQueue

    private var stream: FSEventStreamRef?
    private var debounceWorkItem: DispatchWorkItem?

    init(
        roots: [URL] = ApplicationDiscoveryService.defaultRoots(),
        debounceInterval: TimeInterval = 0.75,
        queue: DispatchQueue = .main,
        onChange: @escaping () -> Void
    ) {
        self.roots = roots
        self.debounceInterval = debounceInterval
        self.queue = queue
        self.onChange = onChange
    }

    func start() {
        guard stream == nil else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<ApplicationChangeMonitor>
                .fromOpaque(info)
                .takeUnretainedValue()
            monitor.scheduleChange()
        }

        let paths = roots.map(\.path) as CFArray
        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagFileEvents
                | kFSEventStreamCreateFlagIgnoreSelf
        )

        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            flags
        )

        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    private func scheduleChange() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    deinit {
        stop()
    }
}
