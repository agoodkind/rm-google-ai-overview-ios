//
//  ShareSheet.swift
//  Skip AI (macOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  macOS share sheet wrapper

import SwiftUI
import AppKit

/// macOS share sheet for sharing feedback reports
struct ShareSheet: NSViewRepresentable {
    let activityItems: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            // Try to create email with pre-filled recipient
            if let feedbackText = self.activityItems.first as? String {
                self.openMailComposer(with: feedbackText, in: view)
            } else {
                self.showSharingPicker(in: view)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private func openMailComposer(with body: String, in view: NSView) {
        let service = NSSharingService(named: .composeEmail)
        service?.recipients = ["alex@goodkind.io"]
        service?.subject = "Skip AI Feedback"
        
        if service?.canPerform(withItems: [body]) == true {
            service?.perform(withItems: [body])
        } else {
            // Fallback if Mail.app not configured
            showSharingPicker(in: view)
        }
    }
    
    private func showSharingPicker(in view: NSView) {
        guard let window = view.window else { return }
        let picker = NSSharingServicePicker(items: activityItems)
        picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
}

