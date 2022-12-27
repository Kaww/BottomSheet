import SwiftUI
import BottomSheet

struct ContentView: View {

    @State private var show = false
    @State private var shouldScrollExpandSheet = true
    @State private var largestUndimmedDetent: BottomSheet.LargestUndimmedDetent? = .none
    @State private var showGrabber = false
    @State private var showsInCompactHeight = false
    @State private var showNavigationBar = true
    @State private var dismissable = true

    // Detents
    @State private var bottomSheetDetents: [BottomSheet.Detent] = [.medium, .large]
    @State private var selectedBottomSheetDetents: [BottomSheet.Detent] = [.medium]

    @State private var useCustomCornerRadius = false
    private let cornerRadiusMinValue: CGFloat = .zero
    private let cornerRadiusMaxValue: CGFloat = 80
    @State private var cornerRadius: CGFloat = 0

    var body: some View {
        NavigationView {
            List {
                detentsSection
                largestUndimmedDetentSection
                scrollSection
                compactHeightConfigSection
                showNavigationBarSection
                dismissableSection
                grabberSection
                customRadiusSection
            }
            .navigationTitle(Text("Bottom sheet"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { show.toggle() }) {
                        Text("Show!")
                    }
                }
            }
            .tint(.blue)
            .bottomSheet(
                isPresented: $show,
                detents: selectedBottomSheetDetents,
                shouldScrollExpandSheet: shouldScrollExpandSheet,
                largestUndimmedDetent: largestUndimmedDetent,
                showGrabber: showGrabber,
                cornerRadius: useCustomCornerRadius ? cornerRadius : nil,
                showsInCompactHeight: showsInCompactHeight,
                showNavigationBar: showNavigationBar,
                dismissable: dismissable
            ) {
                sheetContentView
            }
            .onDisappear {
                show = false
            }
        }
    }

    private var sheetContentView: some View {
        List {
            Section {
                Button(action: { BottomSheet.dismiss() }) {
                    Label("Dismiss", systemImage: "multiply")
                        .foregroundColor(.red)
                }

                ForEach(1..<31, id: \.self) { id in
                    Text("Item \(id)")
                }
            } header: {
                Text("Default sheet with scrolling")
            }
        }
        .navigationTitle(Text("Bottom sheet content"))
    }

    // MARK: Detents

    private var detentsSection: some View {
        Section {
            NavigationLink("Select detents") {
                List {
                    BottomSheetDetentsSelect(
                        values: $bottomSheetDetents,
                        selection: $selectedBottomSheetDetents
                    )
                }
            }
        } header: {
            Text("Detents")
        } footer: {
            Text(detentsFooterText)
        }
    }

    private var detentsFooterText: String {
        var text = "Defines the heights where the sheet can rest.\n"
        for detent in selectedBottomSheetDetents {
            text.append("- " + detent.description)
            if detent != selectedBottomSheetDetents.last {
                text.append("\n")
            }
        }
        return text
    }

    private var largestUndimmedDetentSection: some View {
        Section {
            Picker("Detents", selection: $largestUndimmedDetent) {
                Text("None")
                    .tag(.none as BottomSheet.LargestUndimmedDetent?)

                ForEach(BottomSheet.LargestUndimmedDetent.allCases) { detent in
                    Text(detent.description)
                        .tag(detent as BottomSheet.LargestUndimmedDetent?)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Interact with content underneath")
        } footer: {
            Text("")
        }
    }

    // MARK: Scroll

    private var scrollSection: some View {
        Section {
            Toggle(isOn: $shouldScrollExpandSheet) {
                Text("Should scroll expand sheet")
            }
        } header: {
            Text("Scroll")
        } footer: {
            Text("")
        }
    }

    // MARK: Compact Height

    private var compactHeightConfigSection: some View {
        Section {
            Toggle(isOn: $showsInCompactHeight) {
                Text("Attach to bottom")
            }
        } header: {
            Text("Compact height")
        } footer: {
            Text("Determines whether the sheet attaches to the bottom edge of the screen in a compact-height size class.")
        }
    }

    // MARK: Dismiss

    private var dismissableSection: some View {
        Section {
            Toggle(isOn: $dismissable) {
                Text("Dismissable")
            }
        } header: {
            Text("Dismiss")
        } footer: {}
    }

    // MARK: Grabber

    private var grabberSection: some View {
        Section {
            Toggle(isOn: $showGrabber) {
                Text("Show grabber")
            }
        } header: {
            Text("Grabber")
        } footer: {
            Text("")
        }
    }

    // MARK: Corner Radius

    private var customRadiusSection: some View {
        Section {
            Toggle(isOn: $useCustomCornerRadius) {
                Text("Use custom corner radius")
            }
            Slider(
                value: $cornerRadius,
                in: cornerRadiusMinValue...cornerRadiusMaxValue,
                step: 1,
                label: { Text("\(cornerRadius.rounded())") },
                minimumValueLabel: { Text("") },
                maximumValueLabel: { Text("\(Int(cornerRadius))") }
            )
            .disabled(!useCustomCornerRadius)
            .tint(useCustomCornerRadius ? .blue : .gray)
        } header: {
            Text("Corner radius")
        } footer: {
            Text("")
        }
    }

    // MARK: Navigation Bar

    private var showNavigationBarSection: some View {
        Section {
            Toggle(isOn: $showNavigationBar) {
                Text("Show NavigationBar")
            }
        } header: {
            Text("Navigation bar")
        } footer: {
            Text("Defines if the NavigationBar is visible or hidden in the sheet content view.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Detents Selection

struct BottomSheetDetentsSelect: View {
    @State private var showCustomValueView = false

    @Binding var values: [BottomSheet.Detent]
    @Binding var selection: [BottomSheet.Detent]

    var body: some View {
        Section("Detents") {
            ForEach(values) { value in
                Button {
                    if selection.contains(value) {
                        selection.removeAll(where: { $0 == value })
                    } else {
                        selection.append(value)
                    }
                } label: {
                    HStack {
                        Text(value.description)

                        Spacer()

                        if selection.contains(value) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .deleteDisabled(isDeleteDisabled(for: value))
            }
            .onDelete(perform: delete)

            Button {
                showCustomValueView = true
            } label: {
                Label("Add custom", systemImage: "plus.circle.fill")
            }
            .bottomSheet(
                isPresented: $showCustomValueView,
                detents: [BottomSheet.Detent.medium],
                dismissable: false
            ) {
                BottomSheetDetentsSelectCustomValuePicker {
                    values.append($0)
                    selection.append($0)
                }
            }
        }

        if !selection.isEmpty {
            Section("Selection and order") {
                ForEach(selection) { value in
                    HStack {
                        Text(value.description)
                        Spacer()
                        if selection.contains(value) {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
                .onMove(perform: move)
            }
            .environment(\.editMode, .constant(EditMode.active))
        }
    }

    private func isDeleteDisabled(for item: BottomSheet.Detent) -> Bool {
        item == .medium || item == .large
    }

    func move(from source: IndexSet, to destination: Int) {
        selection.move(fromOffsets: source, toOffset: destination)
    }

    func delete(from source: IndexSet) {
        let items = source.map { values[$0] }
        values.remove(atOffsets: source)
        selection.removeAll(where: items.contains(_:))
    }
}

private struct BottomSheetDetentsSelectCustomValuePicker: View {
    private enum ValueType { case ratio, fixed }

    @State private var value: String = ""
    @State private var selectedValueType: ValueType = .ratio

    var onSubmit: (BottomSheet.Detent) -> Void

    var body: some View {
        List {
            Section {
                Picker("Type of value", selection: $selectedValueType) {
                    Text("Size ratio").tag(ValueType.ratio)
                    Text("Fixed height").tag(ValueType.fixed)
                }
                .pickerStyle(.segmented)

                TextField("werwer", text: $value)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .overlay {
                        HStack {
                            if selectedValueType == .ratio {
                                Text("x")
                                    .offset(x: -10)
                            }
                            Spacer()
                        }
                    }

                Button {
                    submitValue()
                } label: {
                    Text("Add value")
                        .frame(maxWidth: .infinity)
                        .disabled(!isFormValid)
                }
            } footer: {
                switch selectedValueType {
                case .ratio:
                    Text("A ratio of the height within the safe area of the sheet")

                case .fixed:
                    Text("A fixed a height within the safe area of the sheet")
                }
            }

        }
        .navigationTitle("Custom value")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    BottomSheet.dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
    }

    private var isFormValid: Bool {
        switch selectedValueType {
        case .ratio:
            return Double(value.replacingOccurrences(of: ",", with: ".")) != nil

        case .fixed:
            return Int(value) != nil
        }
    }

    private func submitValue() {
        switch selectedValueType {
        case .ratio:
            submitRatio(value: value)

        case .fixed:
            submitFixed(value: value)
        }
    }

    private func submitRatio(value: String) {
        guard let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) else { return }
        onSubmit(.ratio(doubleValue))
        BottomSheet.dismiss()
    }

    private func submitFixed(value: String) {
        guard let intValue = Int(value) else { return }
        onSubmit(.fixed(intValue))
        BottomSheet.dismiss()
    }
}

struct BottomSheetDetentsSelectPreview: View {
    @State private var values: [BottomSheet.Detent] = [
        .medium,
        .large,
        .fixed(150),
        .ratio(0.5)
    ]

    @State private var selectedValues: [BottomSheet.Detent] = [
        .medium
    ]

    var body: some View {
        BottomSheetDetentsSelect(
            values: $values,
            selection: $selectedValues
        )
    }
}
