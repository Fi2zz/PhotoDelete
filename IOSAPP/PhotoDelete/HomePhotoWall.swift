//
//  HomePhotoWall.swift
//  PhotoDelete
//

import SwiftUI
import Photos

enum PhotoWallConfiguration {
    static let initialBatch = 48
    static let batchSize = 48
    static let rowCount = 4
    static let visibleColumns = 3
    static let tileGap: CGFloat = 1
    static let pixelScale: CGFloat = 3

    static func tileSide(for containerWidth: CGFloat) -> CGFloat {
        let gaps = tileGap * CGFloat(visibleColumns - 1)
        let fitted = (containerWidth - gaps) / CGFloat(visibleColumns)
        return min(150, max(72, fitted))
    }

    static func columnCount(assetCount: Int) -> Int {
        guard assetCount > 0 else { return 0 }
        return Int(ceil(Double(assetCount) / Double(rowCount)))
    }

    static func nextBatchCount(displayed: Int, total: Int) -> Int {
        guard displayed < total else { return displayed }
        return min(displayed + batchSize, total)
    }
}

struct HomePhotoWall: View {
    let allAssets: [PHAsset]
    let containerWidth: CGFloat
    let photoLibraryManager: PhotoLibraryManager

    @State private var displayedCount = PhotoWallConfiguration.initialBatch

    private var displayedAssets: [PHAsset] {
        Array(allAssets.prefix(displayedCount))
    }

    private var tileSide: CGFloat {
        PhotoWallConfiguration.tileSide(for: containerWidth)
    }

    private var columnCount: Int {
        PhotoWallConfiguration.columnCount(assetCount: displayedAssets.count)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: PhotoWallConfiguration.tileGap) {
                ForEach(0..<columnCount, id: \.self) { column in
                    wallColumn(column)
                }
            }
        }
    }

    private func wallColumn(_ column: Int) -> some View {
        VStack(spacing: PhotoWallConfiguration.tileGap) {
            ForEach(0..<PhotoWallConfiguration.rowCount, id: \.self) { row in
                if let asset = asset(atColumn: column, row: row) {
                    HomePhotoWallTile(
                        asset: asset,
                        side: tileSide,
                        photoLibraryManager: photoLibraryManager
                    )
                }
            }

            if column == columnCount - 1 {
                loadMoreProbe
            }
        }
    }

    private var loadMoreProbe: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear(perform: loadMorePhotos)
    }

    private func asset(atColumn column: Int, row: Int) -> PHAsset? {
        guard !displayedAssets.isEmpty else { return nil }
        let index = column * PhotoWallConfiguration.rowCount + row
        return displayedAssets[index % displayedAssets.count]
    }

    private func loadMorePhotos() {
        displayedCount = PhotoWallConfiguration.nextBatchCount(
            displayed: displayedCount,
            total: allAssets.count
        )
    }
}
