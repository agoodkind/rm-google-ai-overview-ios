//
//  ShareSheet.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  iOS share sheet wrapper

import SwiftUI
import UIKit
import MessageUI

/// iOS share sheet for sharing feedback reports
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Try to present mail composer if available
        if MFMailComposeViewController.canSendMail(),
           let feedbackText = activityItems.first as? String {
            let mailVC = MFMailComposeViewController()
            mailVC.setToRecipients(["alex@goodkind.io"])
            mailVC.setSubject("Skip AI Feedback")
            mailVC.setMessageBody(feedbackText, isHTML: false)
            mailVC.mailComposeDelegate = context.coordinator
            return mailVC
        }
        
        // Fallback to activity controller
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

