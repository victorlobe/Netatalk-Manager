//
//  AppDelegate.swift
//  Netatalk Manager
//
//  Created by Victor on 07.04.25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func toggleDockBadge(_ sender: NSMenuItem) {
         showDockBadge.toggle()
         sender.state = showDockBadge ? .on : .off
        UserDefaults.standard.set(showDockBadge, forKey: "showDockBadge")
     }
    @IBAction func openConfig(_ sender: Any) {
        let configPath = "/opt/homebrew/etc/afp.conf"
        let configURL = URL(fileURLWithPath: configPath)

        if FileManager.default.fileExists(atPath: configPath) {
            NSWorkspace.shared.activateFileViewerSelecting([configURL])
        } else {
            let alert = NSAlert()
            alert.messageText = "Die Konfigurationsdatei wurde nicht gefunden."
            alert.informativeText = configPath
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.styleMask.remove(.resizable)
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            
            if let menu = NSApp.mainMenu?.item(withTitle: "View")?.submenu,
               let item = menu.item(withTitle: "Show Status in Dock") {
                
                item.state = showDockBadge ? .on : .off
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


}

