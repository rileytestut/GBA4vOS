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
    
    @State
    private var emulatorCore: EmulatorCore?
    
    @State
    private var isPaused: Bool = false
    
    @State
    private var isFastForwarding: Bool = false
    
    @ViewBuilder
    var body: some View {
        VisionGameViewController.Wrapped(game: game) { core in DispatchQueue.main.async { self.emulatorCore = core } }
            .navigationTitle(game?.name ?? "No Game")
            .ornament(visibility: .visible, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                VStack {
                    Spacer(minLength: 10)
                    pauseMenuOrnament
                }
            }
    }
    
    private var pauseMenuOrnament: some View {
        HStack(spacing: 0) {
            Button(action: pauseGame) {
                Image(systemName: self.isPaused ? "play.fill" : "pause.fill")
            }
            .help(self.isPaused ? "Resume Game" : "Pause Game")
            .buttonStyle(.borderless)
            
            Button(action: fastForward) {
                Image(systemName: self.isFastForwarding ? "forward.fill" : "forward")
            }
            .help(self.isFastForwarding ? "Disable Fast Forward" : "Fast Forward")
        }
        .buttonStyle(.borderless)
        .padding()
        .glassBackgroundEffect()
    }
}

private extension GameView
{
    private func pauseGame()
    {
        guard let emulatorCore else { return }
        
        switch emulatorCore.state
        {
        case .paused, .stopped: 
            emulatorCore.resume()
            self.isPaused = false
            
        case .running:
            emulatorCore.pause()
            self.isPaused = true
        }
    }
    
    private func fastForward()
    {
        guard let emulatorCore else { return }
        
        if emulatorCore.rate > 1.0
        {
            emulatorCore.rate = 1.0
            self.isFastForwarding = false
        }
        else
        {
            emulatorCore.rate = 4.0
            self.isFastForwarding = true
        }
    }
}

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = Game(fileURL: fileURL)
    
    return GameView(game: game)
}
