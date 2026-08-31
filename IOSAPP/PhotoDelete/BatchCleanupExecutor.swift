import Photos

struct BatchCleanupOutcome {
    let success: Bool
    let deletedAssetIDs: Set<String>
    let celebration: CleanupCelebration?
    let error: Error?
}

/// Commits delete/favorite candidates directly without a custom confirm
/// screen; the system presents its own deletion confirmation for deletes.
enum BatchCleanupExecutor {
    @MainActor
    static func execute(
        dataManager: DataManager,
        deleteAssets: [PHAsset],
        favoriteAssets: [PHAsset],
        albumInfo: AlbumInfo? = nil,
        completion: @escaping (BatchCleanupOutcome) -> Void
    ) {
        let estimatedSpaceSaved = dataManager.deletedContentSizeSummary(
            for: deleteAssets
        ).knownSizeMB

        dataManager.executeBatchOperations(
            deleteAssets: deleteAssets,
            favoriteAssets: favoriteAssets
        ) { success, error, celebration in
            DispatchQueue.main.async {
                let outcome: BatchCleanupOutcome
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        dataManager.recordDeletedPhotosFromAlbum(
                            albumID: albumInfo?.id,
                            deletedAssets: deleteAssets
                        )
                    }
                    outcome = BatchCleanupOutcome(
                        success: true,
                        deletedAssetIDs: Set(deleteAssets.map(\.localIdentifier)),
                        celebration: celebration ?? CleanupCelebration(
                            deletedPhotos: deleteAssets.count,
                            favoritedPhotos: favoriteAssets.count,
                            organizedPhotos: deleteAssets.count + favoriteAssets.count,
                            estimatedSpaceSavedMB: estimatedSpaceSaved,
                            totalDeletedPhotos: dataManager.cleanupStatsStore.summary.deletedPhotos,
                            totalSpaceSavedMB: dataManager.cleanupStatsStore.summary.estimatedSpaceSavedMB
                        ),
                        error: nil
                    )
                } else {
                    outcome = BatchCleanupOutcome(
                        success: false,
                        deletedAssetIDs: [],
                        celebration: nil,
                        error: error
                    )
                }
                completion(outcome)
            }
        }
    }
}
