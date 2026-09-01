import Testing
@testable import PhotoDelete

struct PhotoWallScrollMathTests {
    private let tileWidth = Double(PhotoWallConfiguration.tileWidth)
    private let spacing = Double(PhotoWallConfiguration.tileSpacing)

    private func setWidth(for count: Int) -> Double {
        PhotoWallConfiguration.setWidth(assetCount: count)
    }

    @Test func setWidthCoversTilesAndSpacing() {
        let width = setWidth(for: 4)
        #expect(width == 4 * (tileWidth + spacing))
    }

    @Test func setWidthForEmptyLibraryIsZero() {
        #expect(setWidth(for: 0) == 0)
    }

    @Test func offsetStartsAtPhaseAndMovesLeft() {
        let offset = PhotoWallScrollMath.offsetX(
            elapsed: 1,
            speed: 30,
            setWidth: 1000,
            phase: 0
        )
        #expect(offset == -30)
    }

    @Test func offsetWrapsWithinOneSetWidth() {
        let width = setWidth(for: 28)
        let offset = PhotoWallScrollMath.offsetX(
            elapsed: 1_000,
            speed: 1_000,
            setWidth: width,
            phase: 0
        )
        #expect(offset > -width)
        #expect(offset <= 0)
    }

    @Test func offsetIsContinuousAcrossWrap() {
        let width = setWidth(for: 28)
        let before = PhotoWallScrollMath.offsetX(elapsed: 10.0, speed: 30, setWidth: width, phase: 0)
        let after = PhotoWallScrollMath.offsetX(elapsed: 10.001, speed: 30, setWidth: width, phase: 0)
        let jump = abs(before - after)
        #expect(jump < 1)
    }

    @Test func offsetHandlesZeroSetWidthSafely() {
        let offset = PhotoWallScrollMath.offsetX(elapsed: 5, speed: 30, setWidth: 0, phase: 0)
        #expect(offset == 0)
    }

    @Test func offsetResumesFromPhaseWithoutJump() {
        let width = setWidth(for: 28)
        let pausedOffset = PhotoWallScrollMath.offsetX(elapsed: 3, speed: 30, setWidth: width, phase: 0)
        let resumePhase = -pausedOffset
        let resumedOffset = PhotoWallScrollMath.offsetX(
            elapsed: 0.5,
            speed: 30,
            setWidth: width,
            phase: resumePhase
        )
        #expect(resumedOffset == pausedOffset - 15)
    }
}
