//
//  Game.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import DeltaCore
import GBADeltaCore

struct Game: GameProtocol, Codable, Hashable
{
    var fileURL: URL
    var type: GameType { .gba }
    
    var name: String {
        self.fileURL.lastPathComponent
    }
}

extension Game: Identifiable
{
    public var id: URL {
        return self.fileURL
    }
}
