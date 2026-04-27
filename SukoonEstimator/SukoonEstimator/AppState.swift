import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {

    // MARK: - Tab Selection
    @Published var selectedTab: Int = 0

    // MARK: - Settings (persisted via UserDefaults)
    @Published var homeZip: String = "" { didSet { saveSettings() } }
    @Published var outdoorPct: Double = 10 { didSet { saveSettings() } }

    @Published var guestTiers: [GuestTier] = [
        GuestTier(guests: 50,   price: 550),
        GuestTier(guests: 100,  price: 700),
        GuestTier(guests: 150,  price: 1000),
        GuestTier(guests: 200,  price: 1300),
        GuestTier(guests: 250,  price: 1600),
        GuestTier(guests: nil,  price: 1600),
    ] { didSet { saveSettings() } }

    @Published var travelTiers: [TravelTier] = [
        TravelTier(miles: 10,  fee: 0),
        TravelTier(miles: 25,  fee: 50),
        TravelTier(miles: 50,  fee: 100),
        TravelTier(miles: 75,  fee: 175),
        TravelTier(miles: nil, fee: 250),
    ] { didSet { saveSettings() } }

    // MARK: - Form State
    @Published var clientName  = ""
    @Published var eventName   = ""
    @Published var eventZip    = "" { didSet { if eventZip.count >= 5 { scheduleEventZipLookup() } else { eventCoords = nil; eventZipStatus = .idle; eventCountyName = nil } } }
    @Published var eventCountyName: String? = nil
    @Published var taxRate     = 8.25
    @Published var hoursCount  = 2
    @Published var guestCount  = ""
    @Published var isIndoor    = true

    // Add-ons
    @Published var powerSupply    = false
    @Published var altMilk        = false
    @Published var milkPrice      = ""
    @Published var stickers       = false
    @Published var stickersPrice  = "85"
    @Published var altSyrups      = false
    @Published var syrupsCount    = 1
    @Published var altSauces      = false
    @Published var saucesCount    = 1
    @Published var hotChoc        = false
    @Published var hotChocPrice   = ""

    // MARK: - Zip State
    struct Coords { let lat, lon: Double; let city, state: String }

    enum ZipStatus: Equatable {
        case idle, loading
        case found(city: String, state: String)
        case error
    }

    @Published var homeCoords:      Coords?    = nil
    @Published var eventCoords:     Coords?    = nil
    @Published var homeZipStatus:   ZipStatus  = .idle
    @Published var eventZipStatus:  ZipStatus  = .idle

    private var homeZipTask:  Task<Void, Never>?
    private var eventZipTask: Task<Void, Never>?
    private var homeZipDebounce:  AnyCancellable?
    private var eventZipDebounce: AnyCancellable?

    // MARK: - Init
    init() {
        loadSettings()
        // Trigger home zip lookup if persisted
        if !homeZip.isEmpty { scheduleHomeZipLookup() }
    }

    // MARK: - Computed Quote
    var quote: Quote {
        let guests    = Int(guestCount) ?? 0
        let base      = getBasePrice(guests: guests)
        let extraHrs  = max(0, hoursCount - 1)
        let extraCost = Double(extraHrs) * 200
        let outdoor   = (!isIndoor && base != nil) ? (base! * outdoorPct / 100) : 0

        var travelMiles: Double? = nil
        var travelFee = 0.0
        if let h = homeCoords, let e = eventCoords {
            let m = haversine(h.lat, h.lon, e.lat, e.lon) * 1.25
            travelMiles = m
            travelFee   = getTravelFee(miles: m)
        }

        // Taxable addons: food & beverage items
        var addons: [Quote.AddonLine] = []
        if altMilk   { addons.append(.init(label: "Alt Milk",                     amount: Double(milkPrice) ?? 0)) }
        if stickers  { addons.append(.init(label: "Custom Stickers",              amount: Double(stickersPrice) ?? 0)) }
        if altSyrups { addons.append(.init(label: "Alt Syrups (\(syrupsCount)×)", amount: Double(syrupsCount) * 20)) }
        if altSauces { addons.append(.init(label: "Alt Sauces (\(saucesCount)×)", amount: Double(saucesCount) * 20)) }
        if hotChoc   { addons.append(.init(label: "Hot Chocolate",                amount: Double(hotChocPrice) ?? 0)) }

        // Non-taxable addons: equipment / fees
        var nonTaxableAddons: [Quote.AddonLine] = []
        if powerSupply { nonTaxableAddons.append(.init(label: "Power Supply", amount: 300)) }

        let taxableSubtotal    = (base ?? 0) + extraCost + outdoor + addons.reduce(0) { $0 + $1.amount }
        let nonTaxableAddonTotal = nonTaxableAddons.reduce(0) { $0 + $1.amount }
        let subtotal           = taxableSubtotal + nonTaxableAddonTotal
        let taxAmount          = taxableSubtotal * taxRate / 100
        let total              = subtotal + travelFee + taxAmount

        return Quote(
            clientName:       clientName,
            eventName:        eventName,
            guests:           guests,
            hours:            hoursCount,
            basePrice:        base,
            extraHrs:         extraHrs,
            extraCost:        extraCost,
            outdoorCharge:    outdoor,
            outdoorPct:       outdoorPct,
            travelMiles:      travelMiles,
            travelFee:        travelFee,
            addons:           addons,
            nonTaxableAddons: nonTaxableAddons,
            taxableSubtotal:  taxableSubtotal,
            subtotal:         subtotal,
            taxRate:          taxRate,
            taxAmount:        taxAmount,
            total:            total,
            isIndoor:         isIndoor,
            eventCity:        eventCoords?.city,
            eventState:       eventCoords?.state,
            eventZip:         eventZip
        )
    }

    var hasQuote: Bool {
        let g = Int(guestCount) ?? 0
        return g > 0 && getBasePrice(guests: g) != nil
    }

    // MARK: - Tier Helpers
    func getBasePrice(guests: Int) -> Double? {
        guard guests > 0 else { return nil }
        let sorted = guestTiers.sorted { ($0.guests ?? Int.max) < ($1.guests ?? Int.max) }
        for t in sorted {
            if let max = t.guests, guests <= max { return t.price }
            if t.guests == nil { return t.price }
        }
        return sorted.last?.price
    }

    func getTravelFee(miles: Double) -> Double {
        let sorted = travelTiers.sorted { ($0.miles ?? Double.infinity) < ($1.miles ?? Double.infinity) }
        for t in sorted {
            if let max = t.miles, miles <= max { return t.fee }
            if t.miles == nil { return t.fee }
        }
        return sorted.last?.fee ?? 0
    }

    func haversine(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let R = 3958.8, r = Double.pi / 180
        let dL = (lat2 - lat1) * r, dG = (lon2 - lon1) * r
        let a  = sin(dL/2)*sin(dL/2) + cos(lat1*r)*cos(lat2*r)*sin(dG/2)*sin(dG/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }

    // MARK: - Zip Lookup
    func scheduleHomeZipLookup() {
        homeZipTask?.cancel()
        homeZipTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            await doHomeZipLookup()
        }
    }

    func scheduleEventZipLookup() {
        eventZipTask?.cancel()
        eventZipTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            await doEventZipLookup()
        }
    }

    private func doHomeZipLookup() async {
        homeZipStatus = .loading
        do {
            let info = try await ZipService.lookup(homeZip)
            homeCoords    = Coords(lat: info.lat, lon: info.lon, city: info.city, state: info.state)
            homeZipStatus = .found(city: info.city, state: info.state)
            saveSettings()
        } catch {
            homeZipStatus = .error
            homeCoords = nil
        }
    }

    private func doEventZipLookup() async {
        eventZipStatus = .loading
        eventCountyName = nil
        do {
            let info = try await ZipService.lookup(eventZip)
            eventCoords    = Coords(lat: info.lat, lon: info.lon, city: info.city, state: info.state)
            eventZipStatus = .found(city: info.city, state: info.state)
            // State rate as initial fallback
            if let rate = ZipService.stateTaxRate(for: info.state) { taxRate = rate }
            // Refine with county-level rate (Census Geocoder — may take 1-2s)
            if let county = try? await ZipService.lookupCounty(lat: info.lat, lon: info.lon) {
                eventCountyName = county.name
                if let rate = ZipService.countyTaxRate(fips: county.fips) {
                    taxRate = rate
                }
            }
        } catch {
            eventZipStatus = .error
            eventCoords = nil
        }
    }

    // MARK: - Quote Text
    func buildQuoteText() -> String {
        let q   = quote
        let fmt = { (v: Double) in String(format: "$%.2f", v) }
        let pad = { (s: String) in s.padding(toLength: 32, withPad: " ", startingAt: 0) }

        var lines = [
            "════════════════════════════════════",
            "   SUKOON COFFEE CO.",
            "   Specialty Live Mobile Coffee Cart",
            "   @SukoonCoffeeCo",
            "════════════════════════════════════",
            "",
        ]
        if !q.clientName.isEmpty { lines.append("Client : \(q.clientName)") }
        if !q.eventName.isEmpty  { lines.append("Event  : \(q.eventName)") }
        if !q.eventZip.isEmpty   {
            let loc = (q.eventCity != nil && q.eventState != nil) ? " · \(q.eventCity!), \(q.eventState!)" : ""
            lines.append("Zip    : \(q.eventZip)\(loc)")
        }
        lines.append("Type   : \(q.isIndoor ? "Indoor" : "Outdoor")")
        lines.append("Hours  : \(q.hours)  |  Guests: \(q.guests)")
        lines += ["", "BREAKDOWN", "────────────────────────────────────"]
        lines.append("\(pad("Base Package")) \(fmt(q.basePrice ?? 0))")
        if q.extraHrs > 0      { lines.append("\(pad("Add'l Hours (\(q.extraHrs)×$200)")) \(fmt(q.extraCost))") }
        if q.outdoorCharge > 0 { lines.append("\(pad("Outdoor (+\(Int(q.outdoorPct))%)")) \(fmt(q.outdoorCharge))") }
        for a in q.addons      { lines.append("\(pad(a.label)) \(fmt(a.amount))") }
        lines.append("────────────────────────────────────")
        lines.append("\(pad("Taxable Subtotal")) \(fmt(q.taxableSubtotal))")
        if q.taxRate > 0       { lines.append("\(pad("Tax (\(q.taxRate)%)")) \(fmt(q.taxAmount))") }
        if !q.nonTaxableAddons.isEmpty {
            lines.append("")
            lines.append("NON-TAXABLE")
            for a in q.nonTaxableAddons { lines.append("\(pad(a.label)) \(fmt(a.amount))") }
        }
        if let mi = q.travelMiles { lines.append("\(pad("Travel (\(Int(mi)) mi)")) \(fmt(q.travelFee))") }
        lines += ["════════════════════════════════════", "\(pad("TOTAL")) \(fmt(q.total))", "════════════════════════════════════"]
        return lines.joined(separator: "\n")
    }

    // MARK: - Reset
    func resetForm() {
        clientName = ""; eventName = ""; eventZip = ""; taxRate = 8.25
        hoursCount = 2; guestCount = ""; isIndoor = true
        powerSupply = false
        altMilk = false;    milkPrice = ""
        stickers = false;   stickersPrice = "85"
        altSyrups = false;  syrupsCount = 1
        altSauces = false;  saucesCount = 1
        hotChoc = false;    hotChocPrice = ""
        eventCoords = nil;  eventZipStatus = .idle;  eventCountyName = nil
    }

    // MARK: - Persistence
    private let defaults = UserDefaults.standard

    func saveSettings() {
        defaults.set(homeZip,    forKey: "homeZip")
        defaults.set(outdoorPct, forKey: "outdoorPct")
        if let d = try? JSONEncoder().encode(guestTiers)  { defaults.set(d, forKey: "guestTiers") }
        if let d = try? JSONEncoder().encode(travelTiers) { defaults.set(d, forKey: "travelTiers") }
    }

    func loadSettings() {
        if let z = defaults.string(forKey: "homeZip")          { homeZip    = z }
        if defaults.object(forKey: "outdoorPct") != nil         { outdoorPct = defaults.double(forKey: "outdoorPct") }
        if let d = defaults.data(forKey: "guestTiers"),
           let t = try? JSONDecoder().decode([GuestTier].self,  from: d) { guestTiers  = t }
        if let d = defaults.data(forKey: "travelTiers"),
           let t = try? JSONDecoder().decode([TravelTier].self, from: d) { travelTiers = t }
    }
}
