import Testing
@testable import PhotoDelete

struct PhotoWallConfigurationTests {
    @Test func columnCountFillsThreeRowsPerColumn() {
        #expect(PhotoWallConfiguration.columnCount(assetCount: 36) == 12)
        #expect(PhotoWallConfiguration.columnCount(assetCount: 37) == 13)
        #expect(PhotoWallConfiguration.columnCount(assetCount: 3) == 1)
    }

    @Test func columnCountForEmptyLibraryIsZero() {
        #expect(PhotoWallConfiguration.columnCount(assetCount: 0) == 0)
    }
}
