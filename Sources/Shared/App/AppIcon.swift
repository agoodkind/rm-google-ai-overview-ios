import SwiftUI

public struct AppIcon: View {
    
    public var placeholderIconName: String = "AppIcon" // primary try
    public var placeholderIconBackupName: String = "AppIconBackup" // fallback
    
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
        NSImage(named: placeholderIconName)
        ?? Bundle.main.iconFileName.flatMap { NSImage(named: $0) }
        ?? NSImage(named: placeholderIconBackupName)
    }
#else
    var resolvedImage: UIImage? {
        UIImage(named: placeholderIconName)
        ?? Bundle.main.iconFileName.flatMap { UIImage(named: $0) }
        ?? UIImage(named: placeholderIconBackupName)
    }
#endif
    
    public var body: some View {
        Group {
#if os(macOS)
            if let iconImage = resolvedImage {
                Image(nsImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10.0)
            } else {
                EmptyView()
            }
#else
            if let iconImage = resolvedImage {
                Image(uiImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10.0)
            } else {
                EmptyView() 
            }
#endif
        }
    }
}
