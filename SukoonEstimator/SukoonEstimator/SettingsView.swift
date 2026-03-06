import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var editingGuests  = false
    @State private var editingTravel  = false

    var body: some View {
        NavigationStack {
            List {
                homeSection
                guestTiersSection
                travelTiersSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.sukoonBg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }

    // MARK: - Home Base
    var homeSection: some View {
        Section {
            HStack {
                Label("Your Home Zip", systemImage: "house.fill")
                Spacer()
                TextField("75001", text: $state.homeZip)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .onChange(of: state.homeZip) {
                        if state.homeZip.count >= 5 { state.scheduleHomeZipLookup() }
                        else { state.homeCoords = nil; state.homeZipStatus = .idle }
                    }
                zipStatus(state.homeZipStatus)
            }

            HStack {
                Label("Outdoor Upcharge", systemImage: "sun.max.fill")
                Spacer()
                TextField("10", value: $state.outdoorPct, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                Text("%").foregroundStyle(.secondary)
            }
        } header: {
            Text("Home Base")
        } footer: {
            Text("Used to calculate travel distance to the event zip code.")
        }
        .listRowBackground(Color.sukoonCard)
    }

    // MARK: - Guest Tiers
    var guestTiersSection: some View {
        Section {
            ForEach($state.guestTiers) { $tier in
                HStack(spacing: 10) {
                    if let g = tier.guests {
                        Text("≤ \(g) guests").foregroundStyle(.secondary).font(.callout).frame(width: 110, alignment: .leading)
                    } else {
                        Text("∞  (overflow)").foregroundStyle(.secondary).font(.callout).frame(width: 110, alignment: .leading)
                    }
                    Spacer()
                    Text("$")
                    TextField("0", value: $tier.price, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            .onDelete { idx in
                state.guestTiers.remove(atOffsets: idx)
                if state.guestTiers.last?.guests != nil {
                    state.guestTiers[state.guestTiers.count - 1].guests = nil
                }
            }

            Button {
                let last = state.guestTiers.last
                if state.guestTiers.last?.guests == nil {
                    state.guestTiers[state.guestTiers.count - 1].guests = 250
                }
                state.guestTiers.append(GuestTier(guests: nil, price: (last?.price ?? 1000) + 200))
            } label: {
                Label("Add Tier", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Guest Pricing Tiers")
        } footer: {
            Text("Swipe left to delete. The last tier acts as the overflow (∞).")
        }
        .listRowBackground(Color.sukoonCard)
    }

    // MARK: - Travel Tiers
    var travelTiersSection: some View {
        Section {
            ForEach($state.travelTiers) { $tier in
                HStack(spacing: 10) {
                    if let m = tier.miles {
                        Text("≤ \(Int(m)) mi").foregroundStyle(.secondary).font(.callout).frame(width: 80, alignment: .leading)
                    } else {
                        Text("∞  (overflow)").foregroundStyle(.secondary).font(.callout).frame(width: 80, alignment: .leading)
                    }
                    Spacer()
                    Text("$")
                    TextField("0", value: $tier.fee, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            .onDelete { idx in
                state.travelTiers.remove(atOffsets: idx)
                if state.travelTiers.last?.miles != nil {
                    state.travelTiers[state.travelTiers.count - 1].miles = nil
                }
            }

            Button {
                let last = state.travelTiers.last
                if state.travelTiers.last?.miles == nil {
                    state.travelTiers[state.travelTiers.count - 1].miles = 100
                }
                state.travelTiers.append(TravelTier(miles: nil, fee: (last?.fee ?? 200) + 75))
            } label: {
                Label("Add Tier", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Travel Fee Tiers")
        } footer: {
            Text("Distance is straight-line × 1.25 road factor. Swipe left to delete.")
        }
        .listRowBackground(Color.sukoonCard)
    }

    // MARK: - Zip Status Badge
    @ViewBuilder
    func zipStatus(_ status: AppState.ZipStatus) -> some View {
        switch status {
        case .idle:                EmptyView()
        case .loading:             ProgressView().scaleEffect(0.75)
        case .found(let c, let s): Text("\(c), \(s)").font(.caption2).foregroundStyle(.green).lineLimit(1)
        case .error:               Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.caption)
        }
    }
}
