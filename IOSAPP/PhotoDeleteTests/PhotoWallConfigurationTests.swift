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
}
