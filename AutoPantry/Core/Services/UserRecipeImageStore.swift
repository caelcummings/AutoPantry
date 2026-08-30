import Foundation
import UIKit

/// Stores user recipe photos on disk, keyed by recipe ID.
enum UserRecipeImageStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AutoPantry/UserRecipeImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    static func imageURL(for recipeID: String) -> URL {
        directory.appendingPathComponent("\(recipeID).jpg")
    }

    static func imageURLIfExists(for recipeID: String) -> URL? {
        let url = imageURL(for: recipeID)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func save(_ data: Data, for recipeID: String) {
        let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) ?? data
        try? jpeg.write(to: imageURL(for: recipeID), options: .atomic)
    }

    static func loadData(for recipeID: String) -> Data? {
        guard let url = imageURLIfExists(for: recipeID) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func delete(for recipeID: String) {
        let url = imageURL(for: recipeID)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
