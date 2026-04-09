import SwiftUI

@main
struct real_igaApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("real-iga", systemImage: "keyboard") {
            Button("종료") { NSApplication.shared.terminate(nil) }
        }
    }
}


