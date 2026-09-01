//
//  HomePhotoWall.swift
//  PhotoDelete
//

import SwiftUI
import Photos

enum PhotoWallConfiguration {
    static let maxAssets = 28
    static let tileWidth: CGFloat = 92
    static let tileHeight: CGFloat = 120
    static let tileSpacing: CGFloat = 10
    static let tileCornerRadius: CGFloat = 12
    static let pixelsPerSecond: Double = 34

    static func setWidth(assetCount: Int) -> Double {
        Double(assetCount) * Double(tileWidth + tileSpacing)
    }
}

enum PhotoWallScrollMath {
    static func offsetX(
        elapsed: Double,
        speed: Double,
        setWidth: Double,
        phase: Double
    ) -> Double {
        guard setWidth > 0, speed > 0 else { return 0 }
        let travelled = phase + elapsed * speed
        let wrapped = travelled.truncatingRemainder(dividingBy: setWidth)
        return -wrapped
    }
}

struct HomePhotoWall: View {
    let assets: [PHAsset]
    let photoLibraryManager: PhotoLibraryManager

    @State private var touchActive = false
    @State private var wallVisible = false
    @State private var scrollPhase: Double = 0
    @State private var scrollAnchorDate = Date()
    @State private var scrollOffset: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var wallScrolling: Bool {
        wallVisible && !touchActive && !reduceMotion
    }

    private var loopedAssets: [PHAsset] {
        assets + assets
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !wallScrolling)) { timeline in
            wallRow
                .offset(x: scrollOffset)
                .onChange(of: timeline.date) { tickDate in
                    advance(with: tickDate)
                }
        }
        .onAppear { wallVisible = true }
        .onDisappear { wallVisible = false }
        .onChange(of: wallScrolling) { _ in rebaseScroll() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in touchActive = true }
                .onEnded { _ in touchActive = false }
        )
    }

    private var wallRow: some View {
        HStack(spacing: PhotoWallConfiguration.tileSpacing) {
            ForEach(loopedAssets, id: \.localIdentifier) { asset in
                HomePhotoWallTile(asset: asset, photoLibraryManager: photoLibraryManager)
            }
        }
        .fixedSize()
    }

    private func advance(with tickDate: Date) {
        guard wallScrolling else { return }
        let elapsed = tickDate.timeIntervalSince(scrollAnchorDate)
        scrollOffset = PhotoWallScrollMath.offsetX(
            elapsed: elapsed,
            speed: PhotoWallConfiguration.pixelsPerSecond,
            setWidth: PhotoWallConfiguration.setWidth(assetCount: assets.count),
            phase: scrollPhase
        )
    }

    private func rebaseScroll() {
        scrollPhase = -scrollOffset
        scrollAnchorDate = Date()
    }
}
