import Foundation

/// One page of a list endpoint. Equivalent of `PageModel<T>`.
struct Page<Item: Decodable>: Decodable {
    let items: [Item]
    let meta: PageMeta
}

struct PageMeta: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
}
