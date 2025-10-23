import SwiftUI

#if os(macOS)
import AppKit
fileprivate extension NSImage {
    var isValid: Bool {
        return representations.count > 0
    }
}
#endif

public struct AppIcon: View {
    
    public var placeholderIconName: String = "AppIcon" // primary try
    public var placeholderIconBackupName: String = "LargeIcon" // fallback
    
    public init(setIconName: String? = nil, setBackupName: String? = nil) {
        if let thisName = setIconName, !thisName.isEmpty {
            placeholderIconName = thisName
        }
        if let thisName = setBackupName, !thisName.isEmpty {
            placeholderIconBackupName = thisName
        }
    }
    
#if os(macOS)
    var resolvedImage: NSImage? {
        if let primary = NSImage(named: placeholderIconName) {
            return primary
        }
        if let fallbackName = Bundle.main.iconFileName,
           let fallback = NSImage(named: fallbackName) {
            return fallback
        }
        if let backup = NSImage(named: placeholderIconBackupName) {
            return backup
        }
        return nil
    }
#else
    var resolvedImage: UIImage? {
        if let primary = UIImage(named: placeholderIconName) {
            return primary
        }
        if let fallbackName = Bundle.main.iconFileName,
           let fallback = UIImage(named: fallbackName) {
            return fallback
        }
        if let backup = UIImage(named: placeholderIconBackupName) {
            return backup
        }
        return nil
    }
#endif
    
    public var body: some View {
        Group {
            if let iconImage = resolvedImage {
#if os(macOS)
                Image(nsImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10.0)
#else

                    Image(uiImage: iconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .backport.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10.0))

#endif
            } else {
                EmptyView()
            }
        }
    }
}
