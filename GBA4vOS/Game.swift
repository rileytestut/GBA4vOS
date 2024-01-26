//
//  Game.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import CryptoKit

import DeltaCore
import GBADeltaCore

struct Game: GameProtocol, Codable, Hashable
{
    var fileURL: URL
    var type: GameType { .gba }
    
    var sha1: String

    init(fileURL: URL) throws
    {
        self.fileURL = fileURL

        let data = try Data(contentsOf: fileURL)
        let sha1Hash = Insecure.SHA1.hash(data: data)
        
        let hashString = sha1Hash.compactMap { String(format: "%02x", $0) }.joined()
        self.sha1 = hashString
    }
}

extension Game
{
    var name: String {
        self.fileURL.lastPathComponent
    }
}

extension Game: Identifiable
{
    public var id: String {
        return self.sha1
    }
}

extension Game
{
    static func gamesDirectory() -> URL
    {
        let databaseDirectory = URL.documentsDirectory.appending(path: "Database")
        let gamesDirectory = databaseDirectory.appending(path: "Games", directoryHint: .isDirectory)
        
        do
        {
            try FileManager.default.createDirectory(at: gamesDirectory, withIntermediateDirectories: true)
        }
        catch
        {
            print("Failed to create Games directory.", error.localizedDescription)
        }
        
        return gamesDirectory
    }
}
