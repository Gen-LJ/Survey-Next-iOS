import Foundation

/// Body of `POST /auth/register`. Encoded as snake_case (`country_id`, `region_id`),
/// and the ids go out as numbers: Go binds them as `uint` and rejects strings.
struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let role: Role
    let countryId: Int
    let regionId: Int
}
