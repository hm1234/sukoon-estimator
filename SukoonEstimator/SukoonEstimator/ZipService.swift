import Foundation

struct ZipInfo {
    let city: String
    let state: String
    let lat: Double
    let lon: Double
}

struct CountyInfo {
    let name: String
    let fips: String  // 5-digit (state FIPS + county FIPS), e.g. "13119" for Fulton GA
}

enum ZipService {
    static func lookup(_ zip: String) async throws -> ZipInfo {
        let padded = String(format: "%05d", Int(zip) ?? 0)
        guard let url = URL(string: "https://api.zippopotam.us/us/\(padded)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard
            let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let places   = json["places"] as? [[String: Any]],
            let place    = places.first,
            let city     = place["place name"] as? String,
            let state    = place["state abbreviation"] as? String,
            let latStr   = place["latitude"] as? String,
            let lonStr   = place["longitude"] as? String,
            let lat      = Double(latStr),
            let lon      = Double(lonStr)
        else { throw URLError(.cannotParseResponse) }

        return ZipInfo(city: city, state: state, lat: lat, lon: lon)
    }

    // MARK: - County Lookup (Census Bureau Geocoder — free, no API key)
    static func lookupCounty(lat: Double, lon: Double) async throws -> CountyInfo {
        let urlStr = "https://geocoding.geo.census.gov/geocoder/geographies/coordinates?x=\(lon)&y=\(lat)&benchmark=Public_AR_Current&vintage=Current_Vintage&layers=Counties&format=json"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard
            let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result   = json["result"]       as? [String: Any],
            let geos     = result["geographies"] as? [String: Any],
            let counties = geos["Counties"]      as? [[String: Any]],
            let county   = counties.first,
            let name     = county["NAME"]        as? String,
            let stFips   = county["STATE"]       as? String,
            let coFips   = county["COUNTY"]      as? String
        else { throw URLError(.cannotParseResponse) }
        return CountyInfo(name: name, fips: stFips + coFips)
    }

    static func countyTaxRate(fips: String) -> Double? { countyTaxRates[fips] }
    static func stateTaxRate(for state: String) -> Double? { stateTaxRates[state] }

    // MARK: - Georgia County Rates
    // Source: GA Dept of Revenue — Effective April 1, 2026
    // FIPS codes are standard 5-digit (13 + 3-digit county FIPS, alphabetical order).
    // Fulton outside Atlanta/Hapeville/College Park/East Point = 7.75%
    // City of Atlanta (spans Fulton 13119 & DeKalb 13087) = 8.9% — override manually if needed.
    // Richmond (Augusta) = 8.5%
    static let countyTaxRates: [String: Double] = [
        "13001": 8.00, // Appling
        "13003": 8.00, // Atkinson
        "13005": 8.00, // Bacon
        "13007": 8.00, // Baker
        "13009": 8.00, // Baldwin
        "13011": 9.00, // Banks
        "13013": 8.00, // Barrow
        "13015": 7.00, // Bartow
        "13017": 8.00, // Ben Hill
        "13019": 9.00, // Berrien
        "13021": 8.00, // Bibb
        "13023": 8.00, // Bleckley
        "13025": 8.00, // Brantley
        "13027": 8.00, // Brooks
        "13029": 9.00, // Bryan
        "13031": 9.00, // Bulloch
        "13033": 7.00, // Burke
        "13035": 8.00, // Butts
        "13037": 8.00, // Calhoun
        "13039": 7.00, // Camden
        "13041": 9.00, // Candler
        "13043": 7.00, // Carroll
        "13045": 7.00, // Catoosa
        "13047": 7.00, // Charlton
        "13049": 7.00, // Chatham
        "13051": 9.00, // Chattahoochee
        "13053": 9.00, // Chattooga
        "13055": 7.00, // Cherokee
        "13057": 8.00, // Clarke
        "13059": 9.00, // Clay
        "13061": 8.00, // Clayton (College Park portion = 9% — override manually)
        "13063": 8.00, // Clinch
        "13065": 6.00, // Cobb
        "13067": 8.00, // Coffee
        "13069": 9.00, // Colquitt
        "13071": 8.00, // Columbia
        "13073": 9.00, // Cook
        "13075": 8.00, // Coweta
        "13077": 8.00, // Crawford
        "13079": 8.00, // Crisp
        "13081": 7.00, // Dade
        "13083": 8.00, // Dawson
        "13085": 9.00, // Decatur
        "13087": 8.00, // DeKalb (Atlanta portions = 8.9% — override manually)
        "13089": 8.00, // Dodge
        "13091": 8.00, // Dooly
        "13093": 8.00, // Dougherty
        "13095": 7.00, // Douglas
        "13097": 8.00, // Early
        "13099": 8.00, // Echols
        "13101": 8.00, // Effingham
        "13103": 9.00, // Elbert
        "13105": 9.00, // Emanuel
        "13107": 9.00, // Evans
        "13109": 7.00, // Fannin
        "13111": 7.00, // Fayette
        "13113": 7.00, // Floyd
        "13115": 7.00, // Forsyth
        "13117": 7.00, // Franklin
        "13119": 7.75, // Fulton (Atlanta = 8.9%, Hapeville/CollegePark/EastPoint = 8.75%)
        "13121": 7.00, // Gilmer
        "13123": 8.00, // Glascock
        "13125": 7.00, // Glynn
        "13127": 8.00, // Gordon
        "13129": 8.00, // Grady
        "13131": 8.00, // Greene
        "13133": 6.00, // Gwinnett
        "13135": 7.00, // Habersham
        "13137": 7.00, // Hall
        "13139": 8.00, // Hancock
        "13141": 8.00, // Haralson
        "13143": 8.00, // Harris
        "13145": 7.00, // Hart
        "13147": 7.00, // Heard
        "13149": 8.00, // Henry
        "13151": 7.00, // Houston
        "13153": 8.00, // Irwin
        "13155": 8.00, // Jackson
        "13157": 8.00, // Jasper
        "13159": 8.00, // Jeff Davis
        "13161": 9.00, // Jefferson
        "13163": 8.00, // Jenkins
        "13165": 8.00, // Johnson
        "13167": 7.00, // Jones
        "13169": 9.00, // Lamar
        "13171": 8.00, // Lanier
        "13173": 8.00, // Laurens
        "13175": 8.00, // Lee
        "13177": 9.00, // Liberty
        "13179": 9.00, // Lincoln
        "13181": 9.00, // Long
        "13183": 8.00, // Lowndes
        "13185": 8.00, // Lumpkin
        "13187": 9.00, // McDuffie
        "13189": 8.00, // McIntosh
        "13191": 8.00, // Macon
        "13193": 8.00, // Madison
        "13195": 8.00, // Marion
        "13197": 8.00, // Meriwether
        "13199": 9.00, // Miller
        "13201": 8.00, // Mitchell
        "13203": 8.00, // Monroe
        "13205": 8.00, // Montgomery
        "13207": 8.00, // Morgan
        "13209": 9.00, // Murray
        "13211": 9.00, // Muscogee
        "13213": 7.00, // Newton
        "13215": 8.00, // Oconee
        "13217": 9.00, // Oglethorpe
        "13219": 7.00, // Paulding
        "13221": 9.00, // Peach
        "13223": 7.00, // Pickens
        "13225": 8.00, // Pierce
        "13227": 7.00, // Pike
        "13229": 7.00, // Polk
        "13231": 8.00, // Pulaski
        "13233": 8.00, // Putnam
        "13235": 8.00, // Quitman
        "13237": 8.00, // Rabun
        "13239": 8.00, // Randolph
        "13241": 8.50, // Richmond
        "13243": 7.00, // Rockdale
        "13245": 9.00, // Schley
        "13247": 8.00, // Screven
        "13249": 8.00, // Seminole
        "13251": 7.00, // Spalding
        "13253": 7.00, // Stephens
        "13255": 8.00, // Stewart
        "13257": 8.00, // Sumter
        "13259": 8.00, // Talbot
        "13261": 8.00, // Taliaferro
        "13263": 8.00, // Tattnall
        "13265": 8.00, // Taylor
        "13267": 8.00, // Telfair
        "13269": 8.00, // Terrell
        "13271": 8.00, // Thomas
        "13273": 8.00, // Tift
        "13275": 8.00, // Toombs
        "13277": 8.00, // Towns
        "13279": 8.00, // Treutlen
        "13281": 7.00, // Troup
        "13283": 9.00, // Turner
        "13285": 8.00, // Twiggs
        "13287": 7.00, // Union
        "13289": 9.00, // Upson
        "13291": 8.00, // Walker
        "13293": 7.00, // Walton
        "13295": 8.00, // Ware
        "13297": 9.00, // Warren
        "13299": 9.00, // Washington
        "13301": 8.00, // Wayne
        "13303": 8.00, // Webster
        "13305": 8.00, // Wheeler
        "13307": 8.00, // White
        "13309": 7.00, // Whitfield
        "13311": 8.00, // Wilcox
        "13313": 9.00, // Wilkes
        "13315": 7.00, // Wilkinson
        "13317": 8.00, // Worth
    ]

    // MARK: - State Fallback Rates
    static let stateTaxRates: [String: Double] = [
        "AL": 4.00, "AK": 0.00, "AZ": 5.60, "AR": 6.50, "CA": 7.25,
        "CO": 2.90, "CT": 6.35, "DE": 0.00, "FL": 6.00, "GA": 4.00,
        "HI": 4.00, "ID": 6.00, "IL": 6.25, "IN": 7.00, "IA": 6.00,
        "KS": 6.50, "KY": 6.00, "LA": 4.45, "ME": 5.50, "MD": 6.00,
        "MA": 6.25, "MI": 6.00, "MN": 6.875,"MS": 7.00, "MO": 4.23,
        "MT": 0.00, "NE": 5.50, "NV": 6.85, "NH": 0.00, "NJ": 6.63,
        "NM": 5.13, "NY": 4.00, "NC": 4.75, "ND": 5.00, "OH": 5.75,
        "OK": 4.50, "OR": 0.00, "PA": 6.00, "RI": 7.00, "SC": 6.00,
        "SD": 4.50, "TN": 7.00, "TX": 8.25, "UT": 5.95, "VT": 6.00,
        "VA": 5.30, "WA": 10.25,"WV": 6.00, "WI": 5.00, "WY": 4.00,
        "DC": 6.00
    ]
}
