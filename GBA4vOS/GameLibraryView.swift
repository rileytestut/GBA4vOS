//
//  GameLibraryView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI

import DeltaCore
import GBADeltaCore

struct GameLibraryView: View {
    
    @SwiftUI.State
    var games: [Game] = [
        try! Game(fileURL: Bundle.main.url(forResource: "Emerald", withExtension: "gba")!),
        try! Game(fileURL: Bundle.main.url(forResource: "Twisted", withExtension: "gba")!)
    ]
    
    @Environment(\.openWindow)
    private var openWindow
    
    var body: some View {
        List(self.games) { game in
            Button(action: { play(game) }) {
                Text(game.fileURL.lastPathComponent)
            }
        }
    }
    
    func play(_ game: Game)
    {
        openWindow(id: SceneType.game.rawValue, value: game)
    }
}

#Preview {
    GameLibraryView()
}
