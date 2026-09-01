//
//  HomePhotoWall.swift
//  PhotoDelete
//

import SwiftUI
import Photos

enum PhotoWallConfiguration {
    static let maxAssets = 48
    static let rowCount = 4
    static let tileSide: CGFloat = 104
    static let tileGap: CGFloat = 1
    static let pixelScale: CGFloat = 3

    static func columnCount(assetCount: Int) -> Int {
        guard assetCount > 0 else { return 0 }
        return Int(ceil(Double(assetCount) / Double(rowCount)))
    }
}

struct HomePhotoWall: View {
    let assets: [PHAsset]
    let photoLibraryManager: PhotoLibraryManager

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
                    HomePhotoWallTile(asset: asset, photoLibraryManager: photoLibraryManager)
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
