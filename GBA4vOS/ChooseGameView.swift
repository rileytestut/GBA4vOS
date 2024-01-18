//
//  ChooseGameView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/18/24.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType
{
    static let gbaGame = UTType(filenameExtension: "gba")!
}

struct ChooseGameView: View 
{
    @State
    private var isChoosingGame: Bool = false
    
    @Environment(\.openWindow)
    private var openWindow
    
    var body: some View {
        Button("Choose Game") {
            isChoosingGame = true
        }
        .fileImporter(isPresented: $isChoosingGame, allowedContentTypes: [.gbaGame]) { result in
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
        
        let game = Game(fileURL: fileURL)
        openWindow(id: SceneType.game.rawValue, value: game)
    }
}

#Preview {
    ChooseGameView()
}
