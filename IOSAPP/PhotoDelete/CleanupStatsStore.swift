//
//  CleanupStatsStore.swift
//  PhotoDelete
//
//  Created by PhotoDelete Team on 11/7/25.
//

import Foundation
import Combine
import OSLog

private let cleanupStatsLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "PhotoDelete",
    category: "CleanupStats"
)

struct CleanupSession: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let deletedPhotos: Int
    let favoritedPhotos: Int
    let organizedPhotos: Int
    let estimatedSpaceSavedMB: Double
    let sizeMeasurementVersion: Int?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        deletedPhotos: Int,
        favoritedPhotos: Int,
        organizedPhotos: Int,
        estimatedSpaceSavedMB: Double,
        sizeMeasurementVersion: Int? = 2
    ) {
        self.id = id
        self.date = date
        self.deletedPhotos = deletedPhotos
        self.favoritedPhotos = favoritedPhotos
        self.organizedPhotos = organizedPhotos
        self.estimatedSpaceSavedMB = estimatedSpaceSavedMB
        self.sizeMeasurementVersion = sizeMeasurementVersion
    }

    var formattedSpaceSaved: String {
        CleanupStatsFormatter.fileSize(countedDeletedContentSizeMB)
    }

    var countedDeletedContentSizeMB: Double {
        guard sizeMeasurementVersion == 2,
              estimatedSpaceSavedMB.isFinite else {
            return 0
        }
        return max(estimatedSpaceSavedMB, 0)
    }
}

struct CleanupStatsSummary: Equatable {
    let sessions: Int
    let deletedPhotos: Int
    let favoritedPhotos: Int
    let organizedPhotos: Int
    let estimatedSpaceSavedMB: Double

    static let empty = CleanupStatsSummary(
        sessions: 0,
        deletedPhotos: 0,
        favoritedPhotos: 0,
        organizedPhotos: 0,
        estimatedSpaceSavedMB: 0
    )

    var formattedSpaceSaved: String {
        CleanupStatsFormatter.fileSize(estimatedSpaceSavedMB)
    }
}

final class CleanupStatsStore: ObservableObject {
    @Published private(set) var sessions: [CleanupSession] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var summary: CleanupStatsSummary {
        sessions.reduce(.empty) { partial, session in
            CleanupStatsSummary(
                sessions: partial.sessions + 1,
                deletedPhotos: partial.deletedPhotos + session.deletedPhotos,
                favoritedPhotos: partial.favoritedPhotos + session.favoritedPhotos,
                organizedPhotos: partial.organizedPhotos + session.organizedPhotos,
                estimatedSpaceSavedMB: partial.estimatedSpaceSavedMB + session.countedDeletedContentSizeMB
            )
        }
    }

    func recordSession(
        deletedPhotos: Int,
        favoritedPhotos: Int,
        organizedPhotos: Int,
        estimatedSpaceSavedMB: Double,
        date: Date = Date()
    ) {
        guard deletedPhotos > 0 || favoritedPhotos > 0 || organizedPhotos > 0 else { return }

        let safeDeletedContentSizeMB = estimatedSpaceSavedMB.isFinite
            ? max(estimatedSpaceSavedMB, 0)
            : 0
        let session = CleanupSession(
            date: date,
            deletedPhotos: max(deletedPhotos, 0),
            favoritedPhotos: max(favoritedPhotos, 0),
            organizedPhotos: max(organizedPhotos, 0),
            estimatedSpaceSavedMB: safeDeletedContentSizeMB
        )
        sessions.insert(session, at: 0)
        save()
    }

    func clearAll() {
        sessions.removeAll()
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try decoder.decode([CleanupSession].self, from: data)
                .sorted { $0.date > $1.date }
        } catch {
            sessions = []
            backupCorruptStoreFile(loadError: error)
        }
    }

    private func backupCorruptStoreFile(loadError: Error) {
        let backupURL = Self.corruptBackupURL(for: fileURL)

        do {
            try FileManager.default.moveItem(at: fileURL, to: backupURL)
            cleanupStatsLogger.error("Failed to load cleanup stats. Moved corrupt file to \(backupURL.lastPathComponent, privacy: .public): \(loadError.localizedDescription, privacy: .public)")
        } catch {
            cleanupStatsLogger.error("Failed to back up corrupt cleanup stats: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            cleanupStatsLogger.error("Failed to save cleanup stats: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func defaultFileURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("PhotoDelete", isDirectory: true)
            .appendingPathComponent("cleanup-history.json")
    }

    static func corruptBackupURL(for fileURL: URL, timestamp: Int = Int(Date().timeIntervalSince1970), id: UUID = UUID()) -> URL {
        let baseURL = fileURL.deletingPathExtension()
        let fileExtension = fileURL.pathExtension
        let backupName = "\(baseURL.lastPathComponent).corrupt-\(timestamp)-\(id.uuidString)"
        let backupFileName = fileExtension.isEmpty ? backupName : "\(backupName).\(fileExtension)"
        return fileURL
            .deletingLastPathComponent()
            .appendingPathComponent(backupFileName)
    }

}

enum CleanupStatsFormatter {
    static var sessionDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    static func space(_ megabytes: Double) -> String {
        if megabytes < 1000 {
            return "\(megabytes.formatted(.number.grouping(.never).precision(.fractionLength(1)))) MB"
        }
        return "\((megabytes / 1000).formatted(.number.grouping(.never).precision(.fractionLength(1)))) GB"
    }

    static func fileSize(_ mebibytes: Double) -> String {
        let bytes = max(mebibytes, 0) * 1_048_576
        if bytes < 1_000_000_000 {
            let megabytes = bytes / 1_000_000
            return "\(megabytes.formatted(.number.grouping(.never).precision(.fractionLength(1)))) MB"
        }
        let gigabytes = bytes / 1_000_000_000
        return "\(gigabytes.formatted(.number.grouping(.never).precision(.fractionLength(1)))) GB"
    }
}
