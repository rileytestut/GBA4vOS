//
//  GBA4vOSApp.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI
import SwiftData

import DeltaCore
import GBADeltaCore
import GBCDeltaCore

enum SceneType: String
{
    case main
    case game
    case gbcGame
}

@main
struct GBA4vOSApp: App {
    
    init()
    {
        Delta.register(GBA.core)
        Delta.register(GBC.core)
        
        ExternalGameControllerManager.shared.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup(id: SceneType.main.rawValue) {
            ChooseGameView()
        }
        .modelContainer(.main)
        
        WindowGroup(id: SceneType.game.rawValue, for: Game.self) { $game in
            GameView(game: game)
        }
        .windowStyle(.plain)
        .defaultSize(width: 480 * 2, height: 320 * 2)
        .modelContainer(.main)
        
        WindowGroup(id: SceneType.gbcGame.rawValue, for: Game.self) { $game in
            GameView(game: game)
        }
        .windowStyle(.plain)
        .defaultSize(width: 667, height: 375)
        .modelContainer(.main)
    }
}
