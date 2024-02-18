//
//  ChooseGameView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/18/24.
//

import SwiftUI
import UniformTypeIdentifiers

import DeltaCore

extension UTType
{
    static let gbaGame = UTType(filenameExtension: "gba")!
    static let gbcGame = UTType(filenameExtension: "gbc")!
}

struct ChooseGameView: View 
{
    @SwiftUI.State
    private var isChoosingGame: Bool = false
    
    @Environment(\.openWindow)
    private var openWindow
    
    var body: some View {
        Button("Choose Game") {
            isChoosingGame = true
        }
        .fileImporter(isPresented: $isChoosingGame, allowedContentTypes: [.gbaGame, .gbcGame]) { result in
            do
            {
                let fileURL = try result.get()
                playGame(at: fileURL)
            }
            catch
            {
                print("Failed to open game.", error.localizedDescription)
            }
        }
    }
}

private extension ChooseGameView
{
    func playGame(at fileURL: URL)
    {
        guard fileURL.startAccessingSecurityScopedResource() else { return }
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
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
        
        do
        {
            let destinationURL = Game.gamesDirectory().appending(path: fileURL.lastPathComponent)
            
            if !FileManager.default.fileExists(atPath: destinationURL.path)
            {
                try FileManager.default.copyItem(at: fileURL, to: destinationURL)
            }
            
            let game = try Game(fileURL: destinationURL)
            
            if game.type == .gbc
            {
                openWindow(id: SceneType.gbcGame.rawValue, value: game)
            }
            else
            {
                openWindow(id: SceneType.game.rawValue, value: game)
            }
        }
        catch
        {
            print("Failed to launch game at path \(fileURL).", error.localizedDescription)
        }
    }
}

#Preview {
    ChooseGameView()
}
