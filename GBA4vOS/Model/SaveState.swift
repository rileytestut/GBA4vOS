//
//  SaveState.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/19/24.
//

import SwiftData

import DeltaCore

@Model
final class SaveState
{
    @Attribute(.unique)
    let id: UUID
    
    // Store just game's ID vs full relationship
    let gameID: String
    
    let createdDate: Date
    var modifiedDate: Date
    
    init(game: Game)
    {
        self.id = UUID()
        self.gameID = game.id
        
        let date = Date.now
        self.createdDate = date
        self.modifiedDate = date        
    }
}

extension SaveState
{
    var name: String {
        return self.modifiedDate.formatted()
    }
}

extension SaveState: SaveStateProtocol
{
    var gameType: GameType { .gba }
    
    var fileURL: URL {
        let directoryURL = SaveState.saveStatesDirectory(forGameID: self.gameID)
        
        let fileURL = directoryURL.appendingPathComponent(self.id.uuidString)
        return fileURL
    }
}

extension SaveState
{
    static func saveStatesDirectory(forGameID gameID: String) -> URL
    {
        let databaseDirectory = URL.documentsDirectory.appending(path: "Database")
        let saveStatesDirectory = databaseDirectory.appending(path: "Save States", directoryHint: .isDirectory)
        let gameDirectory = saveStatesDirectory.appending(path: gameID, directoryHint: .isDirectory)
        
        do
        {
            try FileManager.default.createDirectory(at: gameDirectory, withIntermediateDirectories: true)
        }
        catch
        {
            print("Failed to create Save States directory.", error.localizedDescription)
        }
        
        return gameDirectory
    }
}
