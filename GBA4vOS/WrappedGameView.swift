//
//  WrappedGameView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI

import DeltaCore

struct WrappedGameView: UIViewControllerRepresentable
{
    let game: Game?
    
    func makeUIViewController(context: Context) -> GameViewController
    {
        let gameViewController = GameViewController()
        gameViewController.game = game
        return gameViewController
    }
    
    func updateUIViewController(_ gameViewController: GameViewController, context: Context)
    {
        gameViewController.controllerView.isHidden = true
    }
}

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = Game(fileURL: fileURL)
    
    return WrappedGameView(game: game)
}
