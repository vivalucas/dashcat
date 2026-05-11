import ApplicationServices
import CoreGraphics
import Foundation

final class ScrollManager {
    static let shared = ScrollManager()

    private let mouseReversedKey = "scrollMouseReversed"
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?

    var mouseReversed: Bool {
        get {
            if UserDefaults.standard.object(forKey: mouseReversedKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: mouseReversedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: mouseReversedKey)
        }
    }

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    private init() {}

    @discardableResult
    func requestTrustPrompt() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }
        guard isTrusted else { return false }

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(tap: .cghidEventTap,
                                          place: .tailAppendEventTap,
                                          options: .defaultTap,
                                          eventsOfInterest: mask,
                                          callback: ScrollManager.eventTapCallback,
                                          userInfo: userInfo) else {
            return false
        }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }

        let currentRunLoop = CFRunLoopGetCurrent()
        CFRunLoopAddSource(currentRunLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        runLoop = currentRunLoop
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoop, let source = runLoopSource {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        runLoop = nil
    }

    private func handleScrollEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        guard mouseReversed else { return Unmanaged.passUnretained(event) }

        let isTrackpad = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        guard !isTrackpad else { return Unmanaged.passUnretained(event) }

        event.setIntegerValueField(.scrollWheelEventDeltaAxis1,
                                   value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2,
                                   value: -event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
        return Unmanaged.passUnretained(event)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else {
            return Unmanaged.passUnretained(event)
        }
        let manager = Unmanaged<ScrollManager>.fromOpaque(refcon).takeUnretainedValue()
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = manager.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        guard type == .scrollWheel else {
            return Unmanaged.passUnretained(event)
        }
        return manager.handleScrollEvent(event)
    }
}
