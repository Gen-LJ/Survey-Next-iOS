import Foundation

struct Region: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let code: String
}
