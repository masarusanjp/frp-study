import Foundation

struct Formatters {
    static func formatSaleQuantity(quantity: Double) -> String {
        return String(format: "%.2f", quantity)
    }

    static func formatSaleCost(cost: Double) -> String {
        return String(format: "%.2f", cost)
    }

    static func formatPrice(price: Double) -> String {
        return String(format: "%.2f", price)
    }
}
