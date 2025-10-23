//
//  DebugViews.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  DEBUG PANEL - Development-only views for debugging
//
//  This file contains debug UI that only appears in DEBUG builds.
//  The panel shows app state, lifecycle info, and configuration details.

import SwiftUI
import Combine
internal import UniformTypeIdentifiers

#if DEBUG
/// Debug information panel showing app state, lifecycle, and configuration
///
/// Displays real-time information about:
/// - Platform and scene phase
/// - Launch count and timing
/// - Extension state
/// - Display mode settings
/// - Platform-specific configuration
///
/// Only visible in DEBUG builds
struct DebugPanelView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshTrigger = Date()
    @State private var showShareSheet = false
    @State private var fileToShare: URL?
    
    var body: some View {
        let _ = refreshTrigger // Force view to depend on refreshTrigger
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("DEBUG INFO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Spacer()
                Text("Updated: \(formatTime(refreshTrigger))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Platform & Scene
            debugSection(title: "PLATFORM & SCENE") {
                debugRow(label: "Platform", value: "\(viewModel.platform.kind)")
                debugRow(label: "Scene Phase", value: scenePhaseText, comment: scenePhaseComment)
                debugRow(label: "Use Settings", value: "\(viewModel.platform.useSettings)")
            }
            
            // Launch Info
            debugSection(title: "LAUNCH INFO") {
                debugRow(label: "Cold Launch", value: "\(viewModel.isColdLaunch)", comment: "Fresh start vs resumed")
                debugRow(label: "First Ever", value: "\(viewModel.isFirstLaunchEver)", comment: "Never launched before")
                debugRow(label: "Launch Count", value: "\(viewModel.launchCount + 1)")
                debugRow(label: "Session Start", value: formatDate(viewModel.currentSessionStartDate))
                if let lastLaunch = viewModel.lastLaunchDate {
                    debugRow(label: "Last Launch", value: timeSince(lastLaunch))
                }
            }
            
            // Activity Tracking
            debugSection(title: "ACTIVITY") {
                debugRow(label: "Activations", value: "\(viewModel.activationCount)", comment: "Times became active")
                debugRow(label: "Last Active", value: timeSince(viewModel.lastActiveDate))
                if let lastInactive = viewModel.lastInactiveDate {
                    debugRow(label: "Last Inactive", value: timeSince(lastInactive))
                }
            }
            
            // Extension & Settings
            debugSection(title: "EXTENSION") {
                debugRow(label: "State", value: extensionStateText)
                debugRow(label: "Display Mode", value: viewModel.displayMode.rawValue)
                debugRow(label: "Show Prefs Btn", value: "\(viewModel.platform.shouldShowPreferencesButton())")
                debugRow(label: "Modal Dismissed", value: "\(viewModel.hasSeenEnableExtensionModal)")
            }
            
            // Debug Actions
            debugSection(title: "DEBUG ACTIONS") {
                VStack(spacing: 8) {
                    #if os(iOS)
                    Button("Reset Modal Flag") {
                        viewModel.resetModalDismissal()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    #endif
                    
                    Button("Export App Storage") {
                        exportAppStorage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.blue)
                    #if os(iOS)
                    .sheet(isPresented: $showShareSheet) {
                        if let fileURL = fileToShare {
                            ShareSheet(activityItems: [fileURL])
                        }
                    }
                    #endif
                    
                    Button("Clear All Extension Data") {
                        clearAllExtensionData()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }
            }
            
            // Extension Activity
            debugSection(title: "EXTENSION ACTIVITY") {
                logContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        if let bgPing = viewModel.extensionPingTracker.backgroundPing {
                            HStack {
                                Text("Background:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatTime(bgPing.timestamp))
                                    .foregroundColor(.primary)
                            }
                        } else {
                            HStack {
                                Text("Background:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("No ping yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        
                        if let contentPing = viewModel.extensionPingTracker.contentPing {
                            HStack {
                                Text("Content Script:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatTime(contentPing.timestamp))
                                    .foregroundColor(.primary)
                            }
                            if let tabId = contentPing.tabId {
                                HStack {
                                    Text("  Tab ID:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(tabId)")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 10))
                                }
                            }
                        } else {
                            HStack {
                                Text("Content Script:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("No ping yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                    .font(.caption2)
                    .padding(12)
                    .textSelection(.enabled)
                }
            }
            
            
            
            // Event Log
            debugSection(title: "EVENT LOG (Last \(min(viewModel.debugEventLog.count, 10)))") {
                logContainer {
                    if viewModel.debugEventLog.isEmpty {
                        Text("No events yet")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(viewModel.debugEventLog.prefix(10)) { event in
                                    eventRow(event: event)
                                }
                            }
                            .padding(12)
                        }
                        .textSelection(.enabled)
                        .frame(maxHeight: 150)
                    }
                }
            }
            // Handler Debug Logs
            debugSection(title: "HANDLER DEBUG (\(viewModel.handlerDebugLogs.count))") {
                logContainer {
                    if viewModel.handlerDebugLogs.isEmpty {
                        Text("No handler debug logs")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(viewModel.handlerDebugLogs.prefix(10).enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(12)
                        }
                        .textSelection(.enabled)
                        .frame(maxHeight: 150)
                    }
                }
            }
            // Extension Stats
            debugSection(title: "EXTENSION STATS") {
                logContainer {
                    if let stats = viewModel.extensionStatsReader.stats {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total Hidden:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(stats.totalHidden)")
                                    .foregroundColor(.primary)
                                    .bold()
                            }
                            
                            HStack {
                                Text("Total Duplicates:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(stats.totalDupes)")
                                    .foregroundColor(.primary)
                                    .bold()
                            }
                            
                            HStack {
                                Text("Last Updated:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatTime(stats.lastUpdated))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption2)
                        .padding(12)
                        .textSelection(.enabled)
                    } else {
                        Text("No stats available")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            
            // Extension Logs
            debugSection(title: "EXTENSION LOGS (\(viewModel.extensionLogReader.logs.count))") {
                logContainer {
                    if viewModel.extensionLogReader.logs.isEmpty {
                        Text("No extension logs yet")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(viewModel.extensionLogReader.logs.prefix(20)) { log in
                                    extensionLogRow(log: log)
                                }
                            }
                            .padding(12)
                        }
                        .textSelection(.enabled)
                        .frame(maxHeight: 200)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(debugBackground)
        .font(.system(.caption, design: .monospaced))
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Update relative times every second
            refreshTrigger = Date()
            // Refresh extension logs, stats, and pings every second
            viewModel.extensionLogReader.refreshLogs()
            viewModel.extensionStatsReader.refreshStats()
            viewModel.extensionPingTracker.refreshPings()
            viewModel.refreshHandlerDebugLogs()
        }
    }
    
    /// Current scene phase as human-readable string
    private var scenePhaseText: String {
        switch scenePhase {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
    
    /// Explanation of current scene phase
    private var scenePhaseComment: String {
        switch scenePhase {
        case .active:
            return "In foreground, receiving events"
        case .inactive:
            return "Visible but not receiving events"
        case .background:
            return "Not visible, suspended soon"
        @unknown default:
            return "Unknown state"
        }
    }
    
    /// Extension state as human-readable string
    private var extensionStateText: String {
        switch viewModel.extensionEnabled {
        case .unchecked:
            return "unchecked"
        case .enabled:
            return "enabled"
        case .disabled:
            return "disabled"
        case .error:
            return "error"
        }
    }
    
    /// Section header in debug panel
    /// - Parameters:
    ///   - title: Section title
    ///   - content: Section content
    private func debugSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(Color.orange.opacity(0.3))
                .padding(.vertical, 4)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .tracking(0.5)
            
            content()
                .padding(.leading, 4)
        }
    }
    
    /// Single row in debug panel
    /// - Parameters:
    ///   - label: Label text (left side)
    ///   - value: Value text (right side)
    ///   - comment: Optional explanatory comment
    private func debugRow(label: String, value: String, comment: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text("\(label):")
                    .foregroundColor(.secondary)
                Text(value)
                    .fontWeight(.semibold)
                Spacer()
            }
            if let comment = comment {
                Text("↳ \(comment)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.leading, 8)
            }
        }
    }
    
    /// Event row in log
    /// - Parameter event: Debug event to display
    private func eventRow(event: DebugEvent) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(eventColor(for: event.type))
                .frame(width: 6, height: 6)
            
            Text(formatTime(event.timestamp))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text(event.message)
                .foregroundColor(.primary)
            
            Spacer(minLength: 0)
        }
        .font(.caption2)
    }
    
    /// Color for event type
    private func eventColor(for type: DebugEvent.EventType) -> Color {
        switch type {
        case .activation:
            return .green
        case .deactivation:
            return .orange
        case .extensionState:
            return .blue
        case .displayMode:
            return .purple
        case .launch:
            return .red
        }
    }
    
    /// Extension log row
    /// - Parameter log: Extension log entry
    private func extensionLogRow(log: ExtensionLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(logLevelColor(for: log.level))
                    .frame(width: 6, height: 6)
                
                Text(formatTime(log.timestamp))
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .leading)
                
                Text("[\(log.source.prefix(1).uppercased())]")
                    .foregroundColor(.purple)
                    .frame(width: 20, alignment: .leading)
                
                Text("[\(log.level.uppercased())]")
                    .foregroundColor(logLevelColor(for: log.level))
                    .frame(width: 50, alignment: .leading)
                
                if !log.context.isEmpty {
                    Text("[\(log.context)]")
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Text(log.message)
                    .foregroundColor(.primary)
                
                Spacer(minLength: 0)
            }
            
            if let file = log.file {
                Text("↳ \(file):\(log.line ?? 0)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.leading, 102)
            }
        }
        .font(.caption2)
    }
    
    /// Color for log level
    private func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug":
            return .gray
        case "info":
            return .blue
        case "warn":
            return .orange
        case "error":
            return .red
        default:
            return .secondary
        }
    }
    
    /// Export all app storage to file
    private func exportAppStorage() {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            print("❌ Failed to access app group")
            return
        }
        
        // Define app-specific keys to export
        let keysToExport = [
            "extension-logs",
            "extension-stats",
            "extension-ping-background",
            "extension-ping-content",
            "extension-last-active",
            "handler-debug",
            DISPLAY_MODE_KEY
        ]
        
        // Create export data structure
        var exportData: [String: Any] = [:]
        exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportData["appGroupId"] = APP_GROUP_ID
        
        // Add app-specific storage data, converting non-JSON-serializable types
        for key in keysToExport {
            if let value = defaults.object(forKey: key) {
                exportData[key] = convertToJSONSerializable(value)
            }
        }
        
        // Convert to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            
            // Create filename with timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let filename = "skip-ai-storage_\(timestamp).json"
            
            // Save to temporary directory (works for sandboxed apps)
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)
            try jsonData.write(to: fileURL)
            
            print("✅ Exported app storage to: \(fileURL.path)")
            
            // Show share sheet
            self.fileToShare = fileURL
            #if os(iOS)
            self.showShareSheet = true
            #elseif os(macOS)
            self.showMacSharePicker(for: fileURL)
            #endif
        } catch {
            print("❌ Failed to export app storage: \(error)")
        }
    }
    
    #if os(macOS)
    /// Show macOS save panel and share picker
    private func showMacSharePicker(for fileURL: URL) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = fileURL.lastPathComponent
        savePanel.message = "Choose where to save the exported storage file"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let destination = savePanel.url {
                do {
                    // Copy file to chosen location
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.copyItem(at: fileURL, to: destination)
                    print("✅ Saved to: \(destination.path)")
                    
                    // Show in Finder
                    NSWorkspace.shared.activateFileViewerSelecting([destination])
                } catch {
                    print("❌ Failed to save file: \(error)")
                }
            }
        }
    }
    #endif
    
    /// Convert non-JSON-serializable types to serializable equivalents
    private func convertToJSONSerializable(_ value: Any) -> Any {
        if let data = value as? Data {
            return ["__type": "Data", "__base64": data.base64EncodedString()]
        } else if let date = value as? Date {
            return ["__type": "Date", "__iso8601": ISO8601DateFormatter().string(from: date)]
        } else if let array = value as? [Any] {
            return array.map { convertToJSONSerializable($0) }
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { convertToJSONSerializable($0) }
        } else {
            return value
        }
    }
    
    /// Clear all extension data from shared storage
    private func clearAllExtensionData() {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            return
        }
        
        // Clear all extension-related keys
        defaults.removeObject(forKey: "extension-logs")
        defaults.removeObject(forKey: "extension-stats")
        defaults.removeObject(forKey: "extension-ping-background")
        defaults.removeObject(forKey: "extension-ping-content")
        defaults.removeObject(forKey: "extension-last-active")
        defaults.removeObject(forKey: "handler-debug")
        defaults.synchronize()
        
        // Refresh all readers
        viewModel.extensionLogReader.refreshLogs()
        viewModel.extensionStatsReader.refreshStats()
        viewModel.extensionPingTracker.refreshPings()
        viewModel.refreshHandlerDebugLogs()
        
        print("🗑️ Cleared all extension data")
    }
    
    /// Background styling for debug panel
    private var debugBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
    }
    
    /// Log container with terminal-style background
    private func logContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                ZStack {
                    // Subtle texture/noise effect
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.08))
                    
                    // Grid pattern
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    
                    // Inner shadow effect
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.03), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 3)
                        .offset(y: -73)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    /// Format date for display
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Format time only for display
    /// - Parameter date: Date to format
    /// - Returns: Time string (e.g. "3:45:12 PM")
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Calculate time elapsed since date
    /// - Parameter date: Past date
    /// - Returns: Human-readable relative time string (e.g. "5 min. ago")
    private func timeSince(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
#elseif os(macOS)
import AppKit

struct ShareSheet: NSViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        viewController.view = NSView()
        
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: activityItems)
            picker.show(relativeTo: .zero, of: viewController.view, preferredEdge: .minY)
        }
        
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
    }
}
#endif

#Preview("Debug Panel") {
    DebugPanelView(viewModel: AppViewModel())
        .padding()
}

#Preview("Debug Panel - With Logs") {
    struct DebugPreview: View {
        @StateObject var viewModel: AppViewModel
        
        init() {
            let vm = AppViewModel()
            vm.extensionEnabled = .enabled
            vm.activationCount = 5
            _viewModel = StateObject(wrappedValue: vm)
        }
        
        var body: some View {
            DebugPanelView(viewModel: viewModel)
                .padding()
        }
    }
    
    return DebugPreview()
}
#endif

