//
//  GameView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI

import DeltaCore

struct GameView: View
{
    let game: Game?
    
    var body: some View {
        WrappedGameView(game: game)
            .navigationTitle(game?.name ?? "No Game")
    }
}

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = Game(fileURL: fileURL)
    
    return GameView(game: game)
}
