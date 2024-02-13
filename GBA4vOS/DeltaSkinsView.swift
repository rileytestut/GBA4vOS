//
//  DeltaSkinsMenu.swift
//  GBA4vOS
//
//  Created by Riley Testut on 2/12/24.
//

import SwiftUI
import SwiftData

import DeltaCore

struct DeltaSkinsMenu: View
{
    let game: Game?
    
    @Binding
    var selection: DeltaSkin?
    
    @Binding
    private var isImportingSkin: Bool
    
    @Environment(\.modelContext)
    private var context
    
    @Query // Configured in init
    private var deltaSkins: [DeltaSkin] = []
    
    init(game: Game?, selection: Binding<DeltaSkin?>, isImportingSkin: Binding<Bool>)
    {
        self.game = game
        self._selection = selection
        self._isImportingSkin = isImportingSkin
        
        let gameType = game?.type ?? .gba
        self._deltaSkins = Query(filter: #Predicate<DeltaSkin> { $0.gameType == gameType.rawValue as String },
                                 sort: \.name, order: .forward)
    }
    
    var body: some View {
        Menu {
            Button(action: { isImportingSkin = true }) {
                Label("Add Delta Skin", systemImage: "plus")
            }
            
            Divider()
            
            Button(action: { chooseStandardSkin() }) {
                Text("Default")
            }
            
            Button(action: { choose(nil) }) {
                Text("None")
            }
            
            Divider()
            
            ForEach(deltaSkins) { deltaSkin in
                Button(action: { choose(deltaSkin) }) {
                    Text(deltaSkin.name)
                }
            }
        } label: {
            Image(systemName: "gamecontroller")
        }
        .help("Change Delta Skin")
    }
}

private extension DeltaSkinsMenu
{
    func choose(_ deltaSkin: DeltaSkin?)
    {
        self.selection = deltaSkin
    }
    
    func chooseStandardSkin()
    {
        let controllerSkin = ControllerSkin.standardControllerSkin(for: self.game?.type ?? .gba)!
        
        let deltaSkin = DeltaSkin(controllerSkin: controllerSkin)
        
        // Don't insert into context
        // self.context.insert(deltaSkin)
        
        self.choose(deltaSkin)
    }
}
