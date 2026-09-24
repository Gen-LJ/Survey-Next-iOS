import Foundation

/// State of a screen whose content comes from one request.
/// Equivalent of the `LoadState` sealed interface on Android.
enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }
}
