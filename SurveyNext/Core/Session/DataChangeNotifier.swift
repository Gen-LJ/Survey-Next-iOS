import Foundation
import Observation

/// Bumped by repositories after any write, so screens further back (home,
/// lists, profile) reload without passing results between screens.
/// Same idea as `DataChangeNotifier` on Android.
///
/// Screens use it as `.task(id: notifier.version) { … }`: SwiftUI re-runs the
/// task whenever the version changes, like collecting a StateFlow.
@Observable
final class DataChangeNotifier {
    private(set) var version = 0

    func notifyChanged() {
        version += 1
    }
}
