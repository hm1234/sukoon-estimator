import SwiftUI

struct QuoteView: View {
    @EnvironmentObject var state: AppState
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Group {
                if state.hasQuote {
                    quoteContent
                } else {
                    emptyState
                }
            }
            .navigationTitle("Quote")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if state.hasQuote {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: state.buildQuoteText()) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 20) {
            Text("☕")
                .font(.system(size: 64))
            Text("Fill in event details\non the **Form** tab to\ngenerate a quote.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sukoonBg)
    }

    // MARK: - Quote Content
    var quoteContent: some View {
        let q = state.quote
        return List {
            // ── Hero ──
            Section {
                VStack(spacing: 6) {
                    Text("Sukoon Coffee Co.")
                        .font(.system(.title2, design: .serif))
                        .italic()
                        .foregroundStyle(.white)
                    Text("SPECIALTY LIVE MOBILE COFFEE CART")
                        .font(.system(size: 10, weight: .medium))
                        .kerning(2)
                        .foregroundStyle(.secondary)
                    if !q.clientName.isEmpty || !q.eventName.isEmpty {
                        Text([q.clientName, q.eventName].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    Divider().padding(.vertical, 8)
                    Text("ESTIMATED TOTAL")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(2)
                        .foregroundStyle(.secondary)
                    Text(q.total, format: .currency(code: "USD"))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .listRowBackground(Color.sukoonCard)
            }

            // ── Taxable Breakdown ──
            Section("Taxable Items") {
                qRow("Base Package · \(q.guests) guests · \(q.hours)h",
                     amount: q.basePrice ?? 0, bold: true)
                if q.extraHrs > 0 {
                    qRow("Add'l Hours (\(q.extraHrs) × $150)", amount: q.extraCost, sub: true)
                }
                if q.outdoorCharge > 0 {
                    qRow("Outdoor Upcharge (+\(Int(q.outdoorPct))%)", amount: q.outdoorCharge, sub: true)
                }
                ForEach(q.addons) { a in
                    qRow(a.label, amount: a.amount, sub: true)
                }
            }
            .listRowBackground(Color.sukoonCard)

            // ── Non-taxable Breakdown ──
            if !q.nonTaxableAddons.isEmpty || q.travelFee > 0 {
                Section("Non-Taxable Items") {
                    ForEach(q.nonTaxableAddons) { a in
                        qRow(a.label, amount: a.amount, sub: true)
                    }
                    if let miles = q.travelMiles {
                        qRow("Travel Fee (\(Int(miles)) mi)", amount: q.travelFee, sub: true)
                    }
                }
                .listRowBackground(Color.sukoonCard)
            }

            // ── Totals ──
            Section("Totals") {
                qRow("Taxable Subtotal", amount: q.taxableSubtotal)
                if q.taxRate > 0 {
                    qRow("Tax (\(q.taxRate)%)", amount: q.taxAmount, sub: true)
                }
                if q.nonTaxableAddons.isEmpty == false || q.travelFee > 0 {
                    qRow("Non-Taxable Items", amount: q.subtotal - q.taxableSubtotal + q.travelFee, sub: true)
                }
                HStack {
                    Text("Total").fontWeight(.bold).foregroundStyle(.white)
                    Spacer()
                    Text(q.total, format: .currency(code: "USD"))
                        .fontWeight(.bold).foregroundStyle(.white)
                }
            }
            .listRowBackground(Color.sukoonCard)

            // ── Actions ──
            Section {
                Button {
                    UIPasteboard.general.string = state.buildQuoteText()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    Label(copied ? "Copied!" : "Copy Quote to Clipboard",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(copied ? .green : .white)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.sukoonCard)

                Button(role: .destructive) {
                    state.resetForm()
                } label: {
                    Label("New Quote", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.sukoonCard)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.sukoonBg)
    }

    // MARK: - Quote Row
    @ViewBuilder
    func qRow(_ label: String, amount: Double, sub: Bool = false, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(sub ? .secondary : .primary)
                .font(bold ? .body.weight(.medium) : (sub ? .callout : .body))
            Spacer()
            Text(amount, format: .currency(code: "USD"))
                .foregroundStyle(sub ? .secondary : .primary)
                .font(bold ? .body.weight(.medium) : (sub ? .callout : .body))
        }
    }
}
