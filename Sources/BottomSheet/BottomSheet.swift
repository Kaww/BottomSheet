import SwiftUI

@available(iOS 15, *)
public extension View {

    /// Presents a bottomSheet when a binding to a Boolean value that you provide is true.
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: BottomSheet.Detents = .medium,
        shouldScrollExpandSheet: Bool = true,
        largestUndimmedDetent: BottomSheet.LargestUndimmedDetent? = nil,
        showGrabber: Bool = false,
        cornerRadius: CGFloat? = nil,
        showsInCompactHeight: Bool = false,
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
                            showsInCompactHeight: showsInCompactHeight
                        ) {
                            content()
                                .onDisappear {
                                    isPresented.projectedValue.wrappedValue = false
                                }
                        }
                    }
                }
        }
    }
}

@available(iOS 15, *)
public struct BottomSheet {

    /// Wraps the UIKit's detents (UISheetPresentationController.Detent)
    public enum Detents: CaseIterable, Identifiable {

        /// Creates a system detent for a sheet that's approximately half the height of the screen, and is inactive in compact height.
        case medium
        /// Creates a system detent for a sheet at full height.
        case large
        /// Allows both medium and large detents. Opens in medium first
        case mediumAndLarge
        /// Allows both large and medium detents. Opens in large first
        case largeAndMedium

        fileprivate var value: [UISheetPresentationController.Detent] {
            switch self {
            case .medium:
                return [.medium()]

            case .large:
                return [.large()]

            case .mediumAndLarge, .largeAndMedium:
                return [.medium(), .large()]
            }
        }

        public var description: String {
            switch self {
            case .medium:
                return "Medium"

            case .large:
                return "Large"

            case .mediumAndLarge:
                return "Medium and large"

            case .largeAndMedium:
                return "Large and medium"
            }
        }

        public var id: Int {
            self.hashValue
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
    ///
    /// *Sarun's* blog article source: https://sarunw.com/posts/bottom-sheet-in-ios-15-with-
    fileprivate static func present<Content: View>(
        detents: Detents,
        shouldScrollExpandSheet: Bool,
        largestUndimmedDetent: LargestUndimmedDetent?,
        showGrabber: Bool,
        cornerRadius: CGFloat?,
        showsInCompactHeight: Bool,
        @ViewBuilder _ contentView: @escaping () -> Content
    ) {
        let detailViewController = UIHostingController(rootView: contentView())
        let nav = UINavigationController(rootViewController: detailViewController)

        ref = nav

        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = detents.value
            sheet.prefersScrollingExpandsWhenScrolledToEdge = shouldScrollExpandSheet
            sheet.largestUndimmedDetentIdentifier = largestUndimmedDetent?.value ?? .none
            sheet.prefersGrabberVisible = showGrabber
            sheet.preferredCornerRadius = cornerRadius
            sheet.prefersEdgeAttachedInCompactHeight = showsInCompactHeight
            // Missing article's section "Switch between available detents" section

            switch detents {
            case .largeAndMedium:
                sheet.selectedDetentIdentifier = .large

            case .mediumAndLarge:
                sheet.selectedDetentIdentifier = .medium

            default: break
            }
        }

        UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true, completion: nil)
    }
}
