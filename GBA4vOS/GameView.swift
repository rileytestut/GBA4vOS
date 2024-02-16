//
//  GameView.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import SwiftUI
import GameController
import SwiftData
import AVFoundation

import DeltaCore
import GBADeltaCore

private class DummyGameController: NSObject, GameController
{
    var name: String { "GameView" }
    var playerIndex: Int?
    
    var inputType: GameControllerInputType { .standard }
    var defaultInputMapping: DeltaCore.GameControllerInputMappingProtocol?
}

struct GameView: View
{
    let game: Game?
    
    private let inputGameController = DummyGameController()
    
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
    
    @State
    private var isRotationEnabled: Bool = false
    
    @State
    private var zRotation = Rotation3D()
    
    @State
    private var zStartRotation = Rotation3D()
    
    @Environment(\.modelContext)
    private var context
    
    @Query // Configured in init
    private var saveStates: [SaveState] = []
    
    @AppStorage("preferredSkinID")
    private var preferredSkinID: String?
    
    init(game: Game?)
    {
        self.game = game
        self.inputGameController.playerIndex = 0
        
        let gameID = game?.id ?? ""
        self._saveStates = Query(filter: #Predicate<SaveState> { $0.gameID == gameID },
                                 sort: \.createdDate, order: .forward)
    }
    
    @ViewBuilder
    private var contentView: some View {
        VisionGameViewController.Wrapped(game: game, skin: deltaSkin, isShowingMenu: $isShowingToolbar.animation()) { core in DispatchQueue.main.async { self.emulatorCore = core } }
            .navigationTitle(game?.name ?? "No Game")
            .ornament(visibility: self.isShowingToolbar ? .visible : .hidden, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                VStack {
                    Spacer(minLength: 10)
                    pauseMenuOrnament
                }
            }
            .onTapGesture {
                if deltaSkin == nil && !isRotationEnabled
                {
                    // Only toggle ornament visibility with tap if there's no skin.
                    withAnimation {
                        self.isShowingToolbar.toggle()
                    }
                }
                
                self.emulatorCore?.resume()
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            //TODO: Figure out why this approach didn't work...
//            let gesture = DragGesture(minimumDistance: 0)
//                .updating($isPressingScreen) { (_, isPressing, _) in
//                    isPressing = true
//                }
            
            let tapGesture = TapGesture(count: 1).onEnded {
                activateInput(.a)
                
                // I hate using timers like this, but YOLO.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    deactivateInput(.a)
                }
            }
            
            // Scale contentView so it can rotate without being clipped by window bounds.
            let scale = scale(for: geometry)
            contentView
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20),
                                       displayMode: isRotationEnabled ? .never : .always)
                .scaleEffect(CGSize(width: scale, height: scale), anchor: .center)
                .rotation3DEffect(zRotation)
                .simultaneousGesture(rotateGesture.exclusively(before: tapGesture))
        }
        .onLongPressGesture {
            withAnimation { isShowingToolbar.toggle() }
        }
        .overlay {
            // Show floating buttons in corners when rotation is enabled.
            Color.clear
                .if(isRotationEnabled && isShowingToolbar) {
                    $0.overlay(alignment: .bottomTrailing) {
                        controllerButton(for: .a)
                    }
                    .overlay(alignment: .bottomLeading) {
                        controllerButton(for: .b)
                    }
                    .overlay(alignment: .topTrailing) {
                        controllerButton(for: .start)
                    }
                }
        }
        .onChange(of: isRotationEnabled, initial: true) { _, isRotationEnabled in
            guard isRotationEnabled else { return }
            self.deltaSkin = nil
        }
        .onChange(of: emulatorCore) {
            guard let emulatorCore else { return }
            inputGameController.addReceiver(emulatorCore)
        }
        .onChange(of: deltaSkin?.id, updateDeltaSkin)
        .onAppear {
            do
            {
                guard !isRotationEnabled else { return }
                
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
        .onReceive(NotificationCenter.default.publisher(for: GBA.didActivateGyroNotification).receive(on: RunLoop.main)) { _ in
            isRotationEnabled = true
        }
        //FIXME: This breaks pausing
//        .onReceive(NotificationCenter.default.publisher(for: GBA.didDeactivateGyroNotification).receive(on: RunLoop.main)) { _ in
//            isRotationEnabled = false
//        }
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
    var rotateGesture: some Gesture {
        RotateGesture3D(constrainedToAxis: .z)
            .onChanged { value in
                self.handleRotation(value)
            }
            .onEnded { value in
                self.zStartRotation = self.zRotation
            }
    }
    
    @ViewBuilder
    func controllerButton(for input: StandardGameControllerInput) -> some View
    {
        Button(action: {}) {
            Text(input.stringValue.capitalized)
                .padding()
        }
        .buttonStyle(.bordered)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 0.0, perform: {
            // Ignore
        }, onPressingChanged: { isPressed in
            if isPressed
            {
                activateInput(input)
            }
            else
            {
                deactivateInput(input)
            }
        })
    }
    
    func scale(for geometry: GeometryProxy) -> Double
    {
        guard self.isRotationEnabled else { return 1.0 }
        
        let frame = geometry.frame(in: .local)
        
        let preferredSize = CGSize(width: 480 * 2, height: 320 * 2)
        let aspectFrame = AVMakeRect(aspectRatio: preferredSize, insideRect: frame)
        let hypotenuse = sqrt(pow(aspectFrame.width, 2) + pow(aspectFrame.height, 2))
        
        let scaleX = frame.width / hypotenuse
        let scaleY = frame.height / hypotenuse
        
        let scale = min(scaleX, scaleY)
        
        return scale
    }
    
    func activateInput(_ input: StandardGameControllerInput)
    {
        self.inputGameController.activate(input)
    }
    
    func deactivateInput(_ input: StandardGameControllerInput)
    {
        self.inputGameController.deactivate(input)
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

private extension GameView
{
    func handleRotation(_ value: RotateGesture3D.Value)
    {
        var rotationRate = Vector3D(x: 0, y: 0, z: 0)
        rotationRate.z = value.velocity(about: .z).radians
        
        self.zRotation = self.zStartRotation.rotated(by: value.rotation)
        
        let controllerRotation = GBARotation(rotation: value.rotation, rate: rotationRate)
        GBAEmulatorBridge.shared.controllerRotation = controllerRotation
    }
}

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = try! Game(fileURL: fileURL)
    
    return GameView(game: game)
        .modelContainer(.preview)
}
