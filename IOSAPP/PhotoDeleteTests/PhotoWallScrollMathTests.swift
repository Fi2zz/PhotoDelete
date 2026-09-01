import Testing
@testable import PhotoDelete

struct PhotoWallScrollMathTests {
    private let tileSide = Double(PhotoWallConfiguration.tileSide)
    private let gap = Double(PhotoWallConfiguration.tileGap)

    private func setWidth(columns: Int) -> Double {
        PhotoWallConfiguration.setWidth(columnCount: columns)
    }

    @Test func columnCountFillsThreeRowsPerColumn() {
        #expect(PhotoWallConfiguration.columnCount(assetCount: 36) == 12)
        #expect(PhotoWallConfiguration.columnCount(assetCount: 37) == 13)
        #expect(PhotoWallConfiguration.columnCount(assetCount: 3) == 1)
    }

    @Test func columnCountForEmptyLibraryIsZero() {
        #expect(PhotoWallConfiguration.columnCount(assetCount: 0) == 0)
    }

    @Test func setWidthCoversColumnsIncludingGap() {
        #expect(setWidth(columns: 4) == 4 * (tileSide + gap))
    }

    @Test func offsetStartsAtPhaseAndMovesLeft() {
        let offset = PhotoWallScrollMath.offsetX(elapsed: 1, speed: 30, setWidth: 1000, phase: 0)
        #expect(offset == -30)
    }

    @Test func offsetStaysWithinOneSetWidth() {
        let width = setWidth(columns: 12)
        let offset = PhotoWallScrollMath.offsetX(elapsed: 1_000, speed: 1_000, setWidth: width, phase: 0)
        #expect(offset > -width)
        #expect(offset <= 0)
    }

    @Test func offsetIsContinuousAcrossWrap() {
        let width = setWidth(columns: 12)
        let before = PhotoWallScrollMath.offsetX(elapsed: 10.0, speed: 30, setWidth: width, phase: 0)
        let after = PhotoWallScrollMath.offsetX(elapsed: 10.001, speed: 30, setWidth: width, phase: 0)
        #expect(abs(before - after) < 1)
    }

    @Test func offsetHandlesZeroSetWidthSafely() {
        #expect(PhotoWallScrollMath.offsetX(elapsed: 5, speed: 30, setWidth: 0, phase: 0) == 0)
    }

    @Test func normalizeKeepsValueInNegativeHalfOpenRange() {
        let width = setWidth(columns: 12)
        #expect(PhotoWallScrollMath.normalize(-width, setWidth: width) == 0)
        #expect(PhotoWallScrollMath.normalize(0, setWidth: width) == 0)
        #expect(PhotoWallScrollMath.normalize(width + 5, setWidth: width) == -width + 5)
        #expect(PhotoWallScrollMath.normalize(-width - 5, setWidth: width) == -5)
        #expect(PhotoWallScrollMath.normalize(5, setWidth: width) == 5 - width)
    }

    @Test func dragCommitContinuesFromDraggedPosition() {
        let width = setWidth(columns: 12)
        let autoOffset = PhotoWallScrollMath.offsetX(elapsed: 3, speed: 30, setWidth: width, phase: 0)
        let draggedOffset = PhotoWallScrollMath.normalize(autoOffset + 120, setWidth: width)
        let resumedOffset = PhotoWallScrollMath.offsetX(
            elapsed: 0.5,
            speed: 30,
            setWidth: width,
            phase: -draggedOffset
        )
        #expect(resumedOffset == PhotoWallScrollMath.normalize(draggedOffset - 15, setWidth: width))
    }
}
