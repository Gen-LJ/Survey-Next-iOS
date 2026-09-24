import Foundation

struct Country: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let code: String
    /// Only `/auth/register-form` nests regions; other endpoints omit them.
    let regions: [Region]?
}
