import Foundation
import SwiftUI

@Observable
class OldLSPViewModel {
    var serverProcess: Process!
    var stdinPipe: Pipe!
    var stdoutPipe: Pipe!
    var stderrPipe: Pipe!

    private func handleStdoutOutput(fromNotification notification: Notification) {
        guard let handle = notification.object as? FileHandle else { return }
        let data = handle.availableData
        if data.count > 0 {
            if let str = String(data: data, encoding: .utf8) {
                print("[SourceKit-LSP stdout] \(str)\n\n")
            } else {
                print("[SourceKit-LSP stdout] Got data, but couldn't convert it into a string\n\n")
            }
        } else {
            print("[SourceKit-LSP stdout] Reached end of input\n\n")
        }
        // In my testing, waitForDataInBackgroundAndNotify fires once (the next time there's data),
        // and not again. So in the notification handler, I call it again
        // to, effectively, loop the listener.
        //            self.stdoutPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    func handleStderrOutput(fromNotification notification: Notification) {
        guard let handle = notification.object as? FileHandle else { return }
        let data = handle.availableData
        if data.count > 0 {
            if let str = String(data: data, encoding: .utf8) {
                print("[SourceKit-LSP stderr] \(str)\n\n")
            } else {
                print("[SourceKit-LSP stderr] Got data, but couldn't convert it into a string\n\n")
            }
        } else {
            print("[SourceKit-LSP stderr] Reached end of input\n\n")
        }
        // In my testing, waitForDataInBackgroundAndNotify fires once (the next time there's data),
        // and not again. So in the notification handler, I call it again
        // to, effectively, loop the listener.
        //            self.stderrPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    func doingAThing() {
        // Create and configure the sub-process
        self.serverProcess = Process()
        serverProcess.executableURL = URL(filePath: "/usr/bin/sourcekit-lsp", directoryHint: .notDirectory)
        serverProcess.arguments = ["--log-level", "debug"]
        serverProcess.qualityOfService = .userInteractive
        // Set current-working-directory to the directory of the codebase I want to browse
        // I'm not sure if this is necessary, but likely doesn't hurt.
        serverProcess.currentDirectoryURL = URL(fileURLWithPath: "/Users/ekrietsch/dev/sources.shared-ui-ios")

        // Get access to stdin, stdout, and stderr
        self.stdinPipe = Pipe()
        serverProcess.standardInput = stdinPipe
        self.stdoutPipe = Pipe()
        serverProcess.standardOutput = stdoutPipe
        stdoutPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: stdoutPipe.fileHandleForReading,
            queue: nil,
            using: self.handleStdoutOutput(fromNotification:)
        )
        self.stderrPipe = Pipe()
        serverProcess.standardError = stderrPipe
        stderrPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: stderrPipe.fileHandleForReading,
            queue: nil,
            using: self.handleStderrOutput(fromNotification:)
        )

        // Actually start the sub-process
        try! serverProcess.run()
        print("Running with PID \(serverProcess.processIdentifier)")
    }

    func sendCommand() {
        let initEnvelope = lspayload(id: 100000, method: "initialize", params: [
            "processId": nil,
            "clientInfo": [
                "name": "EriksSourceKit-LSP-Thing",
                "version": "0.1.0"
            ],
            "locale": "en_US",
            "rootUri": "file:///Users/ekrietsch/dev/sources.shared-ui-ios",
            "capabilities": [
                "workspace": [:],
                "window": [
                    "workDoneProgress": true
                ],
                "general": [
                    "positionEncodings": ["utf-8"]
                ]
            ]
        ])
        try! stdinPipe.fileHandleForWriting.write(contentsOf: initEnvelope.data(using: .utf8)!)
    }

    private func lspayload(id: UInt, method: String, params: [String: Any?]) -> String {
        let messageDictionary: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: messageDictionary, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let envelope = "Content-Length: \(jsonData.count)\r\n\r\n\(jsonString)"
        return envelope
    }
}

