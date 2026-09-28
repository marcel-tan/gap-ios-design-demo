import Foundation
import Observation

/// The signed-in demo shopper and her Gap Encore membership.
@Observable
final class EncoreAccount {
    static let pointsKey = "encore.points"
    static let basePoints = 2124

    let firstName = "Gwenyth"
    let lastName = "Paltrow-Lee"
    let email = "gwenyth@example.com"
    let tier = "Premier Member"
    let memberSince = "2019"
    let shippingAddress = "1255 Rue Sainte-Catherine O, Montréal, QC H3G 1P7"
    let paymentLabel = "Gap Good Rewards Mastercard •••• 4021"

    private(set) var points: Int
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: EncoreAccount.pointsKey)
        points = stored > 0 ? stored : EncoreAccount.basePoints
    }

    var fullName: String { "\(firstName) \(lastName)" }
    var pointsLabel: String { EncoreAccount.formatPoints(points) }

    /// Points needed for the next $5 reward (every 500 points).
    var pointsToNextReward: Int { 500 - (points % 500) }
    var nextRewardProgress: Double { Double(points % 500) / 500 }

    func earn(_ earned: Int) {
        guard earned > 0 else { return }
        points += earned
        defaults.set(points, forKey: EncoreAccount.pointsKey)
    }

    func reset() {
        points = EncoreAccount.basePoints
        defaults.removeObject(forKey: EncoreAccount.pointsKey)
    }

    static func formatPoints(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

enum Greeting {
    static func text(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
