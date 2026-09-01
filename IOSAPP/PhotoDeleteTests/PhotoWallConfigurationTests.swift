import Testing
@testable import PhotoDelete

struct PhotoWallConfigurationTests {
    @Test func columnCountFillsFourRowsPerColumn() {
        #expect(PhotoWallConfiguration.columnCount(assetCount: 48) == 12)
        #expect(PhotoWallConfiguration.columnCount(assetCount: 49) == 13)
        #expect(PhotoWallConfiguration.columnCount(assetCount: 4) == 1)
    }

    @Test func columnCountForEmptyLibraryIsZero() {
        #expect(PhotoWallConfiguration.columnCount(assetCount: 0) == 0)
    }

    @Test func tileSideFitsThreeVisibleColumns() {
        let side = PhotoWallConfiguration.tileSide(for: 393)
        #expect(abs(side - 130.333) < 0.01)
    }

    @Test func tileSideClampsToSaneBounds() {
        #expect(PhotoWallConfiguration.tileSide(for: 100) == 72)
        #expect(PhotoWallConfiguration.tileSide(for: 900) == 150)
    }
}
