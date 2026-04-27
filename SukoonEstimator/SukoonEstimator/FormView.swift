import SwiftUI

struct FormView: View {
    @EnvironmentObject var state: AppState
    @FocusState private var focused: Field?

    enum Field: Hashable { case zip, tax, guests, milkPrice, stickersPrice, hotChocPrice }

    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                eventSection
                locationSection
                addonsSection
                actionSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.sukoonBg)
            .navigationTitle("New Quote")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }
                }
            }
        }
    }

    // MARK: - Event Details Section
    var eventSection: some View {
        Section("Event Details") {
            // Event Zip
            HStack(spacing: 12) {
                iconBadge("location.fill", color: .init(red: 42/255, green: 21/255, blue: 8/255))
                TextField("Event Zip Code", text: $state.eventZip)
                    .keyboardType(.numberPad)
                    .focused($focused, equals: .zip)
                Spacer()
                zipStatusView(state.eventZipStatus)
            }

            // Tax Rate
            HStack(spacing: 12) {
                iconBadge("percent", color: .init(red: 42/255, green: 21/255, blue: 8/255))
                Text("Tax Rate")
                Spacer()
                TextField("8.25", value: $state.taxRate, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 55)
                    .focused($focused, equals: .tax)
                Text("%").foregroundStyle(.secondary)
            }

            // Hours
            HStack(spacing: 12) {
                iconBadge("clock.fill", color: .init(red: 42/255, green: 21/255, blue: 8/255))
                Stepper(
                    "Hours: \(state.hoursCount)\(state.hoursCount > 1 ? " (+\((state.hoursCount-1))×$200)" : " (min)")",
                    value: $state.hoursCount, in: 1...24
                )
            }

            // Guest Count
            HStack(spacing: 12) {
                iconBadge("person.2.fill", color: .init(red: 42/255, green: 21/255, blue: 8/255))
                TextField("Guest Count (e.g. 75)", text: $state.guestCount)
                    .keyboardType(.numberPad)
                    .focused($focused, equals: .guests)
            }
        }
        .listRowBackground(Color.sukoonCard)
    }

    // MARK: - Location Section
    var locationSection: some View {
        Section {
            Picker("", selection: $state.isIndoor) {
                Label("Indoor",  systemImage: "house.fill").tag(true)
                Label("Outdoor", systemImage: "sun.max.fill").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.sukoonCard)
        } header: {
            Text("Event Type")
        } footer: {
            if !state.isIndoor {
                Text("Outdoor upcharge of \(Int(state.outdoorPct))% will be added to the base price.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Add-ons Section
    var addonsSection: some View {
        Section("Add-ons") {

            // Power Supply — fixed $300
            Toggle(isOn: $state.powerSupply) {
                HStack(spacing: 12) {
                    iconBadge("bolt.fill", color: .init(red: 46/255, green: 30/255, blue: 20/255))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Power Supply")
                        Text("$300 flat fee").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.green)
            .listRowBackground(Color.sukoonCard)

            // Alt Milk
            addonPriceRow("Alternative Milk", icon: "drop.fill", iconColor: .init(red: 30/255, green: 30/255, blue: 50/255),
                           hint: "Oat, Almond, Coconut… (enter cost)",
                           isOn: $state.altMilk, price: $state.milkPrice, field: .milkPrice)

            // Stickers — default $85, editable
            addonPriceRow("Custom Stickers", icon: "star.fill", iconColor: .init(red: 50/255, green: 35/255, blue: 10/255),
                           hint: "Up to 200 · change to $110 for up to 250",
                           isOn: $state.stickers, price: $state.stickersPrice, field: .stickersPrice)

            // Alt Syrups — $20/syrup
            addonCounterRow("Alt Syrups", icon: "drop", iconColor: .init(red: 40/255, green: 25/255, blue: 15/255),
                             unitLabel: "$20 / syrup", isOn: $state.altSyrups, count: $state.syrupsCount, unitPrice: 20)

            // Alt Sauces — $20/sauce
            addonCounterRow("Alt Sauces", icon: "fork.knife", iconColor: .init(red: 40/255, green: 25/255, blue: 15/255),
                             unitLabel: "$20 / sauce", isOn: $state.altSauces, count: $state.saucesCount, unitPrice: 20)

            // Hot Chocolate
            addonPriceRow("Hot Chocolate", icon: "mug.fill", iconColor: .init(red: 50/255, green: 20/255, blue: 10/255),
                           hint: "Enter your price",
                           isOn: $state.hotChoc, price: $state.hotChocPrice, field: .hotChocPrice)
        }
    }

    // MARK: - Action Section
    var actionSection: some View {
        Section {
            Button {
                state.selectedTab = 1
            } label: {
                Label("Generate Quote", systemImage: "chart.bar.doc.horizontal.fill")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .listRowBackground(Color(red: 60/255, green: 30/255, blue: 15/255))

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset Form", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.sukoonCard)
            .confirmationDialog("Reset all form fields?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { state.resetForm() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Sub-views
    @ViewBuilder
    func iconBadge(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: name)
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    func zipStatusView(_ status: AppState.ZipStatus) -> some View {
        switch status {
        case .idle:                    EmptyView()
        case .loading:                 ProgressView().scaleEffect(0.75)
        case .found(let city, let st):
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(city), \(st)").font(.caption).foregroundStyle(.green).lineLimit(1)
                if let county = state.eventCountyName {
                    Text(county).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        case .error:                   Label("Not found", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption).foregroundStyle(.red)
        }
    }

    @ViewBuilder
    func addonPriceRow(_ title: String, icon: String, iconColor: Color, hint: String,
                       isOn: Binding<Bool>, price: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: isOn) {
                HStack(spacing: 12) {
                    iconBadge(icon, color: iconColor)
                    Text(title)
                }
            }
            .tint(.green)
            if isOn.wrappedValue {
                HStack {
                    Text(hint).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("$").foregroundStyle(.secondary)
                    TextField("0.00", text: price)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($focused, equals: field)
                }
                .padding(.leading, 42)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .listRowBackground(Color.sukoonCard)
        .animation(.easeInOut(duration: 0.2), value: isOn.wrappedValue)
    }

    @ViewBuilder
    func addonCounterRow(_ title: String, icon: String, iconColor: Color,
                         unitLabel: String, isOn: Binding<Bool>, count: Binding<Int>, unitPrice: Int) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if isOn.wrappedValue {
                    Text("\(count.wrappedValue) × \(unitLabel) = $\(count.wrappedValue * unitPrice)")
                        .font(.caption).foregroundStyle(.secondary)
                        .transition(.opacity)
                } else {
                    Text(unitLabel).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isOn.wrappedValue {
                Stepper("", value: count, in: 1...20)
                    .labelsHidden()
                    .fixedSize()
                    .transition(.opacity)
            }
            Toggle("", isOn: isOn).labelsHidden().tint(.green)
        }
        .listRowBackground(Color.sukoonCard)
        .animation(.easeInOut(duration: 0.15), value: isOn.wrappedValue)
    }
}
