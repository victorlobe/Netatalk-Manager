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


}

