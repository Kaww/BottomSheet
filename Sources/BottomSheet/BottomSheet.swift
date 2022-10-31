import SwiftUI
import UIKit

@available(iOS 15, *)
public extension View {

    /// Presents a bottomSheet when a binding to a Boolean value that you provide is true.
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: [BottomSheet.Detent] = [.medium],
        shouldScrollExpandSheet: Bool = true,
        largestUndimmedDetent: BottomSheet.LargestUndimmedDetent? = nil,
        showGrabber: Bool = false,
        cornerRadius: CGFloat? = nil,
        showsInCompactHeight: Bool = false,
        dismissable: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        background {
            Color.clear
                .onDisappear {
                    BottomSheet.dismiss()
                }
                .onChange(of: isPresented.wrappedValue) { show in
                    if show {
                        BottomSheet.present(
                            detents: detents,
                            shouldScrollExpandSheet: shouldScrollExpandSheet,
                            largestUndimmedDetent: largestUndimmedDetent,
                            showGrabber: showGrabber,
                            cornerRadius: cornerRadius,
                            showsInCompactHeight: showsInCompactHeight,
                            dismissable: dismissable
                        ) {
                            content()
                                .onDisappear {
                                    isPresented.projectedValue.wrappedValue = false
                                }
                        }
                    } else {
                        BottomSheet.dismiss()
                    }
                }
        }
    }
}

@available(iOS 15, *)
public struct BottomSheet {

    /// Wraps the UIKit's detents (UISheetPresentationController.Detent)
    public enum Detent: Identifiable, CustomStringConvertible, Equatable {
        case medium
        case large
        case fixed(Int)
        case ratio(Double)

        public var id: String { description }

        public var description: String {
            switch self {
            case .medium:
                return "Medium"

            case .large:
                return "Large"

            case .fixed(let value):
                return "Fixed height of \(value)"

            case .ratio(let value):
                return "Ratio of \(value)"
            }
        }

        var asUIKitDetent: UISheetPresentationController.Detent? {
            switch self {
            case .medium:
                return .medium()

            case .large:
                return .large()

#if swift(>=5.7)
            case .fixed(let value):
                guard #available(iOS 16, *) else { return nil }
                return .custom { _ in CGFloat(value) }

            case .ratio(let value):
                guard #available(iOS 16, *) else { return nil }
                return .custom { $0.maximumDetentValue * value }
#else
            case .fixed, .ratio:
                return nil
#endif
            }
        }
    }

    /// Wraps the UIKit's largestUndimmedDetentIdentifier.
    /// *"The largest detent that doesn’t dim the view underneath the sheet."*
    public enum LargestUndimmedDetent: CaseIterable, Identifiable {
        case medium
        case large

        fileprivate var value: UISheetPresentationController.Detent.Identifier {
            switch self {
            case .medium:
                return .medium

            case .large:
                return .large
            }
        }

        public var description: String {
            switch self {
            case .medium:
                return "Medium"

            case .large:
                return "Large"
            }
        }

        public var id: Int {
            self.hashValue
        }
    }

    private static var ref: UINavigationController? = nil

    public static func dismiss() {
        ref?.dismiss(animated: true, completion: { ref = nil })
    }

    /// Handles the presentation logic of the new UIKit's pageSheet modal presentation style.
    /// *Sarun's* blog article source: https://sarunw.com/posts/bottom-sheet-in-ios-15-with-
    fileprivate static func present<Content: View>(
        detents: [Detent],
        shouldScrollExpandSheet: Bool,
        largestUndimmedDetent: LargestUndimmedDetent?,
        showGrabber: Bool,
        cornerRadius: CGFloat?,
        showsInCompactHeight: Bool,
        dismissable: Bool,
        @ViewBuilder _ contentView: @escaping () -> Content
    ) {
        let detailViewController = UIHostingController(rootView: contentView())
        let nav = UINavigationController(rootViewController: detailViewController)

        ref = nav

        nav.modalPresentationStyle = .pageSheet
        nav.isModalInPresentation = !dismissable

        if let sheet = nav.sheetPresentationController {
            sheet.detents = detents.isEmpty ? [.medium()] : detents.compactMap { $0.asUIKitDetent }
            sheet.prefersScrollingExpandsWhenScrolledToEdge = shouldScrollExpandSheet
            setLargestUndimmedDetentIdentifier(
                to: sheet,
                detent: largestUndimmedDetent,
                availableDetents: detents
            )
            sheet.prefersGrabberVisible = showGrabber
            sheet.preferredCornerRadius = cornerRadius
            sheet.prefersEdgeAttachedInCompactHeight = showsInCompactHeight

            if let firstDetent = detents.first {
                switch firstDetent {
                case .medium:
                    sheet.selectedDetentIdentifier = .medium

                case .large:
                    sheet.selectedDetentIdentifier = .large

                case .ratio, .fixed:
                    guard #available(iOS 16, *) else {
                        if detents.contains(.medium) {
                            sheet.selectedDetentIdentifier = .medium
                        } else if detents.contains(.large) {
                            sheet.selectedDetentIdentifier = .large
                        }
                        break
                    }
#if swift(>=5.7)
                    sheet.selectedDetentIdentifier = firstDetent.asUIKitDetent?.identifier
#endif
                }
            }
        }

        UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true, completion: nil)
    }

    fileprivate static func setLargestUndimmedDetentIdentifier(
        to sheet: UISheetPresentationController,
        detent: LargestUndimmedDetent?,
        availableDetents: [Detent]
    ) {
        guard let detent = detent else { return }
        if detent == .medium || detent == .large {
            sheet.largestUndimmedDetentIdentifier = detent.value
        } else {
            if availableDetents.contains(.medium) {
                sheet.largestUndimmedDetentIdentifier = .medium
            } else if availableDetents.contains(.large) {
                sheet.largestUndimmedDetentIdentifier = .large
            }
        }
    }
}
