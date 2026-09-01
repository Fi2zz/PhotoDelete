//
//  HomePhotoWall.swift
//  PhotoDelete
//

import SwiftUI
import Photos

enum PhotoWallConfiguration {
    static let maxAssets = 36
    static let rowCount = 3
    static let tileSide: CGFloat = 104
    static let tileGap: CGFloat = 1
    static let pixelsPerSecond: Double = 34

    static var wallHeight: CGFloat {
        tileSide * CGFloat(rowCount) + tileGap * CGFloat(rowCount - 1)
    }

    static func columnCount(assetCount: Int) -> Int {
        guard assetCount > 0 else { return 0 }
        return Int(ceil(Double(assetCount) / Double(rowCount)))
    }

    static func setWidth(columnCount: Int) -> Double {
        Double(columnCount) * Double(tileSide + tileGap)
    }
}

enum PhotoWallScrollMath {
    static func normalize(_ value: Double, setWidth: Double) -> Double {
        guard setWidth > 0 else { return 0 }
        var wrapped = value.truncatingRemainder(dividingBy: setWidth)
        if wrapped > 0 { wrapped -= setWidth }
        return wrapped
    }

    static func offsetX(
        elapsed: Double,
        speed: Double,
        setWidth: Double,
        phase: Double
    ) -> Double {
        guard setWidth > 0, speed > 0 else { return 0 }
        let travelled = phase + elapsed * speed
        return normalize(-travelled, setWidth: setWidth)
    }
}

struct HomePhotoWall: View {
    let assets: [PHAsset]
    let photoLibraryManager: PhotoLibraryManager

    @State private var touchActive = false
    @State private var liveDragWidth: Double = 0
    @State private var wallVisible = false
    @State private var scrollPhase: Double = 0
    @State private var scrollAnchorDate = Date()
    @State private var scrollOffset: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var wallScrolling: Bool {
        wallVisible && !touchActive && !reduceMotion
    }

    private var displayedOffset: Double {
        scrollOffset + liveDragWidth
    }

    private var loopedColumnCount: Int {
        PhotoWallConfiguration.columnCount(assetCount: assets.count) * 2
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !wallScrolling)) { timeline in
            wallGrid
                .offset(x: displayedOffset)
                .onChange(of: timeline.date) { tickDate in
                    advance(with: tickDate)
                }
        }
        .onAppear { wallVisible = true }
        .onDisappear { wallVisible = false }
        .onChange(of: wallScrolling) { _ in rebaseScroll() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    touchActive = true
                    liveDragWidth = Double(value.translation.width)
                }
                .onEnded { value in
                    liveDragWidth = Double(value.translation.width)
                    touchActive = false
                    commitLiveDrag()
                }
        )
    }

    private var wallGrid: some View {
        HStack(spacing: PhotoWallConfiguration.tileGap) {
            ForEach(0..<loopedColumnCount, id: \.self) { column in
                wallColumn(column)
            }
        }
        .fixedSize()
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

    private func advance(with tickDate: Date) {
        guard wallScrolling else { return }
        let elapsed = tickDate.timeIntervalSince(scrollAnchorDate)
        scrollOffset = PhotoWallScrollMath.offsetX(
            elapsed: elapsed,
            speed: PhotoWallConfiguration.pixelsPerSecond,
            setWidth: currentSetWidth,
            phase: scrollPhase
        )
    }

    private func commitLiveDrag() {
        scrollOffset = PhotoWallScrollMath.normalize(displayedOffset, setWidth: currentSetWidth)
        scrollPhase = -scrollOffset
        scrollAnchorDate = Date()
        liveDragWidth = 0
    }

    private func rebaseScroll() {
        scrollPhase = -scrollOffset
        scrollAnchorDate = Date()
    }

    private var currentSetWidth: Double {
        PhotoWallConfiguration.setWidth(
            columnCount: PhotoWallConfiguration.columnCount(assetCount: assets.count)
        )
    }
}
