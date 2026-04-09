import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {

    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        startKeyListener()
    }

    func startKeyListener() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)


        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, _ in

                guard type == .keyDown else {
                    return Unmanaged.passRetained(event)
                }

                var length: Int = 0
                var buffer = [UniChar](repeating: 0, count: 4)
                event.keyboardGetUnicodeString(
                    maxStringLength: 4,
                    actualStringLength: &length,
                    unicodeString: &buffer
                )
                let string = String(utf16CodeUnits: buffer, count: length)
                print("키 감지: \(string)")

                if string == "ㄹ" || string == "f" {

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString("ㄹㅇ이가 ", forType: .string)

                        let backspaceDown = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)!
                        let backspaceUp = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: false)!
                        backspaceDown.post(tap: .cgAnnotatedSessionEventTap)
                        backspaceUp.post(tap: .cgAnnotatedSessionEventTap)

                        let cmdV = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true)!
                        cmdV.flags = .maskCommand
                        cmdV.post(tap: .cgAnnotatedSessionEventTap)

                        let cmdVUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false)!
                        cmdVUp.flags = .maskCommand
                        cmdVUp.post(tap: .cgAnnotatedSessionEventTap)
                    }

                    return nil
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap!, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
        CFRunLoopRun()
    }
}
