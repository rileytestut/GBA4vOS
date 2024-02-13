//
//  GameView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI
import SwiftData

import DeltaCore

struct GameView: View
{
    let game: Game?
    
    @State
    private var emulatorCore: EmulatorCore?
    
    @State
    private var deltaSkin: DeltaSkin?
    
    @State
    private var isPaused: Bool = false
    
    @State
    private var isFastForwarding: Bool = false
    
    @State
    private var isShowingToolbar: Bool = true
    
    @State
    private var isImportingSkin: Bool = false
    
    @Environment(\.modelContext)
    private var context
    
    @Query // Configured in init
    private var saveStates: [SaveState] = []
    
    @AppStorage("preferredSkinID")
    private var preferredSkinID: String?
    
    init(game: Game?)
    {
        self.game = game
        
        let gameID = game?.id ?? ""
        self._saveStates = Query(filter: #Predicate<SaveState> { $0.gameID == gameID },
                                 sort: \.createdDate, order: .forward)
    }
    
    @ViewBuilder
    var body: some View {
        VisionGameViewController.Wrapped(game: game, skin: deltaSkin) { core in DispatchQueue.main.async { self.emulatorCore = core } }
            .navigationTitle(game?.name ?? "No Game")
            .ornament(visibility: self.isShowingToolbar ? .visible : .hidden, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                VStack {
                    Spacer(minLength: 10)
                    pauseMenuOrnament
                }
            }
            .onTapGesture {
                withAnimation {
                    self.isShowingToolbar.toggle()
                }
                
                self.emulatorCore?.resume()
            }
            .onChange(of: deltaSkin?.id, updateDeltaSkin)
            .onAppear {
                do
                {
                    let preferredSkinID = self.preferredSkinID ?? ""
                    let fetchDescriptor = FetchDescriptor<DeltaSkin>(predicate: #Predicate<DeltaSkin> { $0.identifier == preferredSkinID })
                    
                    if let deltaSkin = try context.fetch(fetchDescriptor).first
                    {
                        self.deltaSkin = deltaSkin
                    }
                    else if let game, let controllerSkin = ControllerSkin.standardControllerSkin(for: game.type)
                    {
                        self.deltaSkin = DeltaSkin(controllerSkin: controllerSkin)
                    }
                }
                catch
                {
                    print("Failed to load preferred delta skin.", error.localizedDescription)
                }
            }
            .onDisappear {
                self.emulatorCore?.stop()
            }
            .fileImporter(isPresented: $isImportingSkin, allowedContentTypes: [.deltaSkin]) { result in
                do
                {
                    let fileURL = try result.get()
                    try importDeltaSkin(at: fileURL)
                }
                catch
                {
                    print("Failed to import skin.", error.localizedDescription)
                }
            }
    }
    
    @ViewBuilder
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
            
            Divider()
                .padding(.horizontal, 8)
            
            Menu {
                Button(action: newSaveState) {
                    Label("New Save State", systemImage: "plus")
                }
                
                Divider()
                
                ForEach(saveStates) { saveState in
                    Button(action: { updateSaveState(saveState) }) {
                        Text(saveState.name)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.down.on.square")
            }
            .help("New Save State")
            
            Menu {
                ForEach(saveStates) { saveState in
                    Button(action: { loadSaveState(saveState) }) {
                        Text(saveState.name)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up.on.square")
            }
            .help("Load Save State")
            .disabled(saveStates.isEmpty) // Disable unless there are save states to load
            
            Divider()
                .padding(.horizontal, 8)
            
            DeltaSkinsMenu(game: self.game, selection: $deltaSkin, isImportingSkin: $isImportingSkin)
        }
        .buttonStyle(.borderless)
        .padding()
        .glassBackgroundEffect()
    }
}

private extension GameView
{
    func pauseGame()
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
    
    func fastForward()
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
    
    func newSaveState()
    {
        guard let game, let emulatorCore else { return }
        
        let isRunning = (emulatorCore.state == .running)
        if isRunning
        {
            emulatorCore.pause()
        }
        
        let saveState = SaveState(game: game)
        emulatorCore.saveSaveState(to: saveState.fileURL)
        
        self.context.insert(saveState)
        
        if isRunning
        {
            emulatorCore.resume()
        }
    }
    
    func updateSaveState(_ saveState: SaveState)
    {
        guard let emulatorCore else { return }
        
        let isRunning = (emulatorCore.state == .running)
        if isRunning
        {
            emulatorCore.pause()
        }
        
        saveState.modifiedDate = .now
        emulatorCore.saveSaveState(to: saveState.fileURL)
        
        if isRunning
        {
            emulatorCore.resume()
        }
    }
    
    func loadSaveState(_ saveState: SaveState)
    {
        guard let emulatorCore else { return }
        
        let isRunning = (emulatorCore.state == .running)
        if isRunning
        {
            emulatorCore.pause()
        }
        
        do
        {
            try emulatorCore.load(saveState)
        }
        catch
        {
            print("Failed to load save state.", error.localizedDescription)
        }
        
        if isRunning
        {
            emulatorCore.resume()
        }
    }
}

private extension GameView
{
    func importDeltaSkin(at fileURL: URL) throws
    {
        guard fileURL.startAccessingSecurityScopedResource() else { return }
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        let destinationURL = DeltaSkin.skinsDirectory().appending(path: fileURL.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path)
        {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        
        guard let deltaSkin = DeltaSkin(fileURL: destinationURL) else { throw CocoaError(.fileReadCorruptFile) }
        self.context.insert(deltaSkin)
        
        // Immediately update to new skin
        self.deltaSkin = deltaSkin
    }
    
    func updateDeltaSkin()
    {
        self.preferredSkinID = self.deltaSkin?.identifier
    }
}

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = try! Game(fileURL: fileURL)
    
    return GameView(game: game)
        .modelContainer(.preview)
}
