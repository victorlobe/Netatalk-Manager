//
//  ViewController.swift
//  Netatalk Manager
//
//  Created by Victor on 07.04.25.
//

import Cocoa
import Foundation

class ViewController: NSViewController {
    
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var statusImageView: NSImageView!
    @IBOutlet var startButton: NSButton!
    @IBOutlet var stopButton: NSButton!
    @IBOutlet var restartButton: NSButton!
    @IBOutlet var statusSpinner: NSProgressIndicator!
    
    @IBAction func didTapStart(_ sender: Any) {
        startNetatalk()
    }

    @IBAction func didTapStop(_ sender: Any) {
        stopNetatalk()
    }

    @IBAction func didTapRestart(_ sender: Any) {
        restartNetatalk()
    }
    
    var netatalkStatusTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startNetatalkStatusMonitoring()
        self.statusImageView.wantsLayer = true
        self.statusSpinner.alphaValue = 0
        self.statusSpinner.stopAnimation(nil)
    }
    
    //MARK: Main Functions
    
    func startNetatalkStatusMonitoring() {
        // Initial status check
        checkNetatalkStatus()
        
        // Start a repeating timer to monitor status
        netatalkStatusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkNetatalkStatus()
        }
    }

    func checkNetatalkStatus() {
        // Check via brew first
        if let brewStatus = tryIsNetatalkRunningViaBrew() {
            if brewStatus {
                updateStatusLabel(isRunning: true)
            } else {
                // If brew reports "not started", double-check using pgrep
                if let processStatus = tryIsNetatalkRunning() {
                    updateStatusLabel(isRunning: processStatus)
                } else {
                    statusLabel.stringValue = "Error: Unable to determine Netatalk status"
                    statusLabel.textColor = .systemYellow
                }
            }
        } else if let processStatus = tryIsNetatalkRunning() {
            // If brew check failed, fall back to pgrep result
            updateStatusLabel(isRunning: processStatus)
        } else {
            statusLabel.stringValue = "Error: Unable to determine Netatalk status"
            statusLabel.textColor = .systemYellow
        }
    }
    
    func updateStatusLabel(isRunning: Bool) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = isRunning ? "Netatalk is running" : "Netatalk is not running"
            self.statusLabel.textColor = isRunning ? .systemGreen : .systemRed
            let symbolName = isRunning ? "checkmark.circle.fill" : "xmark.circle.fill"
            let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            self.statusImageView.symbolConfiguration = config
            self.statusImageView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            self.statusImageView.contentTintColor = isRunning ? .systemGreen : .systemRed

            self.startButton.isEnabled = !isRunning
            self.stopButton.isEnabled = isRunning
            self.restartButton.isEnabled = isRunning
            
            // Glow when running
            if isRunning {
                self.statusImageView.layer?.shadowColor = NSColor.systemGreen.cgColor
                self.statusImageView.layer?.shadowRadius = 10
                self.statusImageView.layer?.shadowOpacity = 0.8
                self.statusImageView.layer?.shadowOffset = .zero
            } else {
                self.statusImageView.layer?.shadowOpacity = 0
            }
            if showDockBadge {
                NSApp.dockTile.badgeLabel = isRunning ? "🟢" : "🔴"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }
        }
    }
    
    func tryIsNetatalkRunningViaBrew() -> Bool? {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "/opt/homebrew/bin/brew services list | grep netatalk"]
        
        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("started")
            } else {
                return nil
            }
        } catch {
            print("Error executing brew services list: \(error)")
            return nil
        }
    }

    func tryIsNetatalkRunning() -> Bool? {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["netatalk"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error executing pgrep: \(error)")
            return nil
        }
    }
    
    //MARK: Functions
    
    func startNetatalk() {
        setControlsEnabled(false, message: "Starting Netatalk...")
        runShellCommand("/opt/homebrew/bin/brew services start netatalk") {
            self.checkNetatalkStatus()
            self.setControlsEnabled(true)
        }
    }

    func stopNetatalk() {
        setControlsEnabled(false, message: "Stopping Netatalk...")
        runShellCommand("/opt/homebrew/bin/brew services stop netatalk") {
            self.checkNetatalkStatus()
            self.setControlsEnabled(true)
        }
    }

    func restartNetatalk() {
        setControlsEnabled(false, message: "Restarting Netatalk...")
        runShellCommand("/opt/homebrew/bin/brew services restart netatalk") {
            self.checkNetatalkStatus()
            self.setControlsEnabled(true)
        }
    }

    //MARK: Helper
    
    private func runShellCommand(_ command: String, completion: (() -> Void)? = nil) {
        DispatchQueue.global().async {
            let task = Process()
            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", command]
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Error executing command: \(command)\n\(error)")
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func setControlsEnabled(_ isEnabled: Bool, message: String? = nil) {
        startButton.isEnabled = isEnabled
        stopButton.isEnabled = isEnabled
        restartButton.isEnabled = isEnabled

        if let message = message {
            statusLabel.stringValue = message
            statusLabel.textColor = .labelColor
            NSApp.dockTile.badgeLabel = "⏳"
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            self.statusImageView.animator().alphaValue = isEnabled ? 1 : 0
            self.statusSpinner.animator().alphaValue = isEnabled ? 0 : 1
        }

        if isEnabled {
            statusSpinner.stopAnimation(nil)
        } else {
            statusSpinner.startAnimation(nil)
        }
    }
}
