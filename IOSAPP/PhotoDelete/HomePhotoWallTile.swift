//
//  HomePhotoWallTile.swift
//  PhotoDelete
//

import SwiftUI
import Photos

struct HomePhotoWallTile: View {
    let asset: PHAsset
    let photoLibraryManager: PhotoLibraryManager

    @State private var image: UIImage?

    private var pixelSize: CGSize {
        CGSize(
            width: PhotoWallConfiguration.tileSide * PhotoWallConfiguration.pixelScale,
            height: PhotoWallConfiguration.tileSide * PhotoWallConfiguration.pixelScale
        )
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                PhotoWallTilePlaceholder()
            }
        }
        .frame(
            width: PhotoWallConfiguration.tileSide,
            height: PhotoWallConfiguration.tileSide
        )
        .clipped()
        .task(id: asset.localIdentifier) { loadThumbnail() }
    }

    private func loadThumbnail() {
        photoLibraryManager.loadAlbumListThumbnail(
            for: asset,
            size: pixelSize,
            quality: .precise
        ) { loaded in
            if let loaded {
                image = loaded
            }
        }
    }
}

private struct PhotoWallTilePlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(PhotoDeleteStyle.hairline)
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(PhotoDeleteStyle.secondaryText)
        }
    }
}
