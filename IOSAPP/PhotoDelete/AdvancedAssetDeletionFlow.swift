import Photos
import SwiftUI

/// Fetches PHAssets for local identifiers in one batch request.
enum PHAssetFetcher {
    static func assets(withLocalIdentifiers identifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
}

/// Runs the direct batch deletion shared by the advanced cleanup lists and
/// applies the list-specific post-success hooks (original marking, result
/// clearing). Replaces the per-list duplicated execute functions.
@MainActor
struct AdvancedAssetDeletionFlow {
    let dataManager: DataManager
    let isExecuting: Binding<Bool>
    let reload: () -> Void
    var onSuccess: ((Set<String>) -> Void)? = nil
    var onResultDismissed: (() -> Void)? = nil

    func run(_ assets: [PHAsset], clearResultAfter: Bool = false) {
        guard !assets.isEmpty, !isExecuting.wrappedValue else { return }
        isExecuting.wrappedValue = true
        BatchCleanupExecutor.execute(
            dataManager: dataManager,
            deleteAssets: assets,
            favoriteAssets: []
        ) { outcome in
            isExecuting.wrappedValue = false
            if outcome.success {
                onSuccess?(outcome.deletedAssetIDs)
                if clearResultAfter {
                    onResultDismissed?()
                }
                HapticManager.notify(.success)
            } else {
                HapticManager.notify(.error)
            }
            reload()
        }
    }
}
