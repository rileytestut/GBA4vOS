//
//  GBA4vOSApp.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI

import DeltaCore
import GBADeltaCore

enum SceneType: String
{
    case main
    case game
}

@main
struct GBA4vOSApp: App {
    
    init()
    {
        Delta.register(GBA.core)
        
        ExternalGameControllerManager.shared.startMonitoring()
        
        #if targetEnvironment(simulator)
                
        // Ignore hardware keyboard in simulator by default.
        for controller in ExternalGameControllerManager.shared.connectedControllers
        {
            if controller is KeyboardGameController
            {
                controller.playerIndex = nil
            }
            else
            {
                controller.playerIndex = 0
            }
        }
        
        #endif
    }
    
    var body: some Scene {
        WindowGroup(id: SceneType.main.rawValue) {
            GameLibraryView()
        }
        
        WindowGroup(id: SceneType.game.rawValue, for: Game.self) { $game in
            GameView(game: game)
        }
    }
}
