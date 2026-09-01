//
//  HomePhotoWall.swift
//  PhotoDelete
//

import SwiftUI
import Photos

enum PhotoWallConfiguration {
    static let maxAssets = 48
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
}

struct HomePhotoWall: View {
    let assets: [PHAsset]
    let containerWidth: CGFloat
    let photoLibraryManager: PhotoLibraryManager

    private var tileSide: CGFloat {
        PhotoWallConfiguration.tileSide(for: containerWidth)
    }

    private var columnCount: Int {
        PhotoWallConfiguration.columnCount(assetCount: assets.count)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: PhotoWallConfiguration.tileGap) {
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
        }
    }

    private func asset(atColumn column: Int, row: Int) -> PHAsset? {
        guard !assets.isEmpty else { return nil }
        let index = column * PhotoWallConfiguration.rowCount + row
        return assets[index % assets.count]
    }
}
