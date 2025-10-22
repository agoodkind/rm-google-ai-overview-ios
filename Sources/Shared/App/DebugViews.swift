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
import SwiftUIBackports

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
            
            #if os(iOS)
            // Debug Actions
            debugSection(title: "DEBUG ACTIONS") {
                Button("Reset Modal Flag") {
                    viewModel.resetModalDismissal()
                }
                .backport.glassButtonStyle()
                .controlSize(.small)
            }
            #endif
            
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
                        .frame(maxHeight: 150)
                    }
                }
            }
            
            // Extension Logs
            debugSection(title: "EXTENSION LOGS (Last \(min(viewModel.extensionLogReader.logs.count, 10)))") {
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
                                ForEach(viewModel.extensionLogReader.logs.prefix(10)) { log in
                                    extensionLogRow(log: log)
                                }
                            }
                            .padding(12)
                        }
                        .frame(maxHeight: 150)
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
                    .padding(.leading, 82)
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

