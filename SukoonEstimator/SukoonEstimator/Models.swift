import Foundation

// MARK: - Tier Models

struct GuestTier: Codable, Identifiable {
    var id: UUID = UUID()
    var guests: Int?   // nil = infinity (catch-all)
    var price: Double

    enum CodingKeys: String, CodingKey { case id, guests, price }
}

struct TravelTier: Codable, Identifiable {
    var id: UUID = UUID()
    var miles: Double? // nil = infinity (catch-all)
    var fee: Double

    enum CodingKeys: String, CodingKey { case id, miles, fee }
}

// MARK: - Computed Quote

struct Quote {
    let clientName: String
    let eventName: String
    let guests: Int
    let hours: Int
    let basePrice: Double?
    let extraHrs: Int
    let extraCost: Double
    let outdoorCharge: Double
    let outdoorPct: Double
    let travelMiles: Double?
    let travelFee: Double
    let addons: [AddonLine]          // taxable (food/beverage)
    let nonTaxableAddons: [AddonLine] // non-taxable (equipment, travel fees)
    let taxableSubtotal: Double      // base + hours + outdoor + taxable addons
    let subtotal: Double             // taxableSubtotal + nonTaxableAddons (display line)
    let taxRate: Double
    let taxAmount: Double            // taxableSubtotal × taxRate only
    let total: Double
    let isIndoor: Bool
    let eventCity: String?
    let eventState: String?
    let eventZip: String

    struct AddonLine: Identifiable {
        let id = UUID()
        let label: String
        let amount: Double
    }

    var isValid: Bool { basePrice != nil && guests > 0 }
}
