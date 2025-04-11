//
//  ViewController.swift
//  Netatalk Manager
//
//  Created by Victor on 07.04.25.
//

import Cocoa
import Foundation

class ViewController: NSViewController {
    
    var netatalkStatusTimer: Timer?
    var netatalkInstalled = false
    var isPostInstallTransitionActive = false
    
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
        if !netatalkInstalled {
            installNetatalk()
        } else {
            stopNetatalk()
        }
    }

    @IBAction func didTapRestart(_ sender: Any) {
        restartNetatalk()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.statusImageView.wantsLayer = true
        self.statusSpinner.alphaValue = 0
        self.statusSpinner.stopAnimation(nil)

        netatalkInstalled = isNetatalkInstalled()

        if !netatalkInstalled {
            statusLabel.stringValue = "Netatalk is not installed"
            statusLabel.textColor = .systemGray

            let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            statusImageView.symbolConfiguration = config
            statusImageView.image = NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: nil)
            statusImageView.contentTintColor = .systemGray
            statusImageView.layer?.shadowOpacity = 0

            startButton.isHidden = true
            restartButton.isHidden = true
            stopButton.title = "Install Netatalk"

            NSApp.dockTile.badgeLabel = nil
            return
        }

        startNetatalkStatusMonitoring()
    }
    
    //MARK: Main Functions
    
    func startNetatalkStatusMonitoring() {
        // Initial status check
        checkNetatalkStatus()
        
        // Start a repeating timer to monitor status
        netatalkStatusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkNetatalkStatus()
        }
    }

    func checkNetatalkStatus() {
        guard !isPostInstallTransitionActive else { return }
        
        let wasInstalled = netatalkInstalled
        netatalkInstalled = isNetatalkInstalled()

        if netatalkInstalled != wasInstalled && !isPostInstallTransitionActive {
            // Only react if not during install transition (which handles the UI)
            DispatchQueue.main.async {
                if !self.netatalkInstalled {
                    self.statusLabel.stringValue = "Netatalk is not installed"
                    self.statusLabel.textColor = .systemGray

                    let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                    self.statusImageView.symbolConfiguration = config
                    self.statusImageView.image = NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: nil)
                    self.statusImageView.contentTintColor = .systemGray
                    self.statusImageView.layer?.shadowOpacity = 0

                    self.startButton.isHidden = true
                    self.restartButton.isHidden = true
                    self.stopButton.title = "Install Netatalk"

                    NSApp.dockTile.badgeLabel = nil
                }
            }
        }

        guard netatalkInstalled else { return }

        // Status prüfen wie bisher
        if let brewStatus = tryIsNetatalkRunningViaBrew() {
            if brewStatus {
                updateStatusLabel(isRunning: true)
            } else if let processStatus = tryIsNetatalkRunning() {
                updateStatusLabel(isRunning: processStatus)
            } else {
                statusLabel.stringValue = "Error: Unable to determine Netatalk status"
                statusLabel.textColor = .systemYellow
            }
        } else if let processStatus = tryIsNetatalkRunning() {
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
    
    func isNetatalkInstalled() -> Bool {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "/opt/homebrew/bin/brew list netatalk"]

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func installNetatalk() {
        setControlsEnabled(false, message: "Installing Netatalk...")

        let progressBar = NSProgressIndicator()
        progressBar.style = .bar
        progressBar.isIndeterminate = false
        progressBar.minValue = 0
        progressBar.maxValue = 100
        progressBar.doubleValue = 0
        progressBar.frame = CGRect(
            x: statusLabel.frame.origin.x + statusLabel.frame.width * 0.1,
            y: statusLabel.frame.origin.y - 30,
            width: statusLabel.frame.width * 0.8,
            height: 12
        )
        self.view.addSubview(progressBar)

        let stepLabel = NSTextField(labelWithString: "Starting installation…")
        stepLabel.alignment = .center
        stepLabel.font = NSFont.systemFont(ofSize: 11)
        stepLabel.textColor = .secondaryLabelColor
        stepLabel.frame = CGRect(
            x: progressBar.frame.origin.x,
            y: progressBar.frame.origin.y - 20,
            width: progressBar.frame.width,
            height: 18
        )
        self.view.addSubview(stepLabel)

        DispatchQueue.main.async {
            self.netatalkStatusTimer?.invalidate()
            self.netatalkStatusTimer = nil
            self.statusImageView.alphaValue = 0
            self.startButton.isHidden = true
            self.restartButton.isHidden = true
            self.stopButton.isHidden = true
        }

        // Simulierter Timer für Progress
        var simulatedProgress: Double = 0
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            simulatedProgress += 1
            progressBar.doubleValue = min(simulatedProgress, 95)
            if simulatedProgress >= 95 {
                timer.invalidate()
            }
        }
        RunLoop.main.add(progressTimer, forMode: .common)

        DispatchQueue.global().async {
            let task = Process()
            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", "/opt/homebrew/bin/brew install netatalk"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { fileHandle in
                if let line = String(data: fileHandle.availableData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        stepLabel.stringValue = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }

            do {
                try task.run()
                task.waitUntilExit()
                handle.readabilityHandler = nil
            } catch {
                print("Error: \(error)")
            }

            DispatchQueue.main.async {
                progressTimer.invalidate()
                progressBar.doubleValue = 100
                progressBar.removeFromSuperview()
                stepLabel.removeFromSuperview()

                let success = self.isNetatalkInstalled()
                self.netatalkInstalled = success

                if success {
                    self.isPostInstallTransitionActive = true
                    self.statusLabel.stringValue = "Installation successful. Starting..."
                    self.statusLabel.textColor = .labelColor

                    // Show hourglass icon while starting up
                    let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                    self.statusImageView.symbolConfiguration = config
                    self.statusImageView.image = NSImage(systemSymbolName: "hourglass.circle.fill", accessibilityDescription: nil)
                    self.statusImageView.contentTintColor = .systemOrange
                    self.statusImageView.alphaValue = 1
                    self.statusImageView.layer?.shadowOpacity = 0

                    self.startButton.isHidden = false
                    self.restartButton.isHidden = false
                    self.stopButton.isHidden = false
                    self.stopButton.title = "Stop"

                    self.statusSpinner.stopAnimation(nil)
                    self.statusSpinner.alphaValue = 0

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.checkNetatalkStatus()
                        self.startNetatalkStatusMonitoring()
                        self.isPostInstallTransitionActive = false
                    }
                } else {
                    self.statusLabel.stringValue = "Installation failed"
                    self.statusLabel.textColor = .systemRed
                    self.stopButton.isHidden = false
                    self.stopButton.title = "Install Netatalk"
                    self.setControlsEnabled(true)
                }
            }
        }
    }
    
}
