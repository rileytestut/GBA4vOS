//
//  VisionGameViewController.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/11/24.
//

import UIKit
import SwiftUI

import DeltaCore

extension VisionGameViewController
{
    struct Wrapped: UIViewControllerRepresentable
    {
        let game: Game?
        let coreHandler: (EmulatorCore) -> Void
        
        let deltaSkin: DeltaSkin?
        
        @Binding
        var isShowingMenu: Bool
        
        func makeUIViewController(context: Context) -> VisionGameViewController
        {
            let gameViewController = VisionGameViewController()
            gameViewController.game = game
            
            if let emulatorCore = gameViewController.emulatorCore
            {
                self.coreHandler(emulatorCore)
            }
            
            return gameViewController
        }
        
        func updateUIViewController(_ gameViewController: VisionGameViewController, context: Context)
        {
            if let deltaSkin
            {
                gameViewController.controllerView.controllerSkin = deltaSkin.skin
            }
            else
            {
                gameViewController.controllerView.controllerSkin = nil
            }
            
            gameViewController.isShowingMenu = isShowingMenu
            
            gameViewController.showMenuHandler = { isShowingMenu in
                self.isShowingMenu = isShowingMenu
            }
        }
        
        init(game: Game?, skin: DeltaSkin?, isShowingMenu: Binding<Bool>, coreHandler: @escaping (EmulatorCore) -> Void)
        {
            self.game = game
            self.deltaSkin = skin
            self._isShowingMenu = isShowingMenu
            self.coreHandler = coreHandler
        }
    }
}

class VisionGameViewController: GameViewController
{
    var showMenuHandler: ((Bool) -> Void)?
    
    fileprivate var isShowingMenu: Bool = false
    
    required init()
    {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.delegate = self
        self.view.backgroundColor = .clear

        let traits = ControllerSkin.Traits(device: .iphone, displayType: .standard, orientation: .landscape)
        self.controllerView.overrideControllerSkinTraits = traits
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisionGameViewController.didConnectGameController(_:)), name: .externalGameControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VisionGameViewController.didDisconnectGameController(_:)), name: .externalGameControllerDidDisconnect, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) 
    {
        super.viewDidAppear(animated)
        
        self.updateGameControllers()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let window = self.view.window
        {
            var traits = ControllerSkin.Traits.defaults(for: window)
            
            if traits.orientation == .portrait
            {
                traits.displayType = .edgeToEdge // Use edge-to-edge display type for portrait skins
            }
            
            if traits != self.controllerView.overrideControllerSkinTraits
            {
                self.controllerView.overrideControllerSkinTraits = traits
                self.controllerView.controllerSkin = self.controllerView.controllerSkin
            }
        }
    }
}

private extension VisionGameViewController
{
    func updateGameControllers()
    {
        guard let emulatorCore = self.emulatorCore else { return }
        
        let isExternalControllerConnected = ExternalGameControllerManager.shared.connectedControllers.contains(where: { $0.playerIndex != nil })
        if isExternalControllerConnected
        {
            self.controllerView.playerIndex = nil
            self.controllerView.removeReceiver(emulatorCore)
            
            self.controllerView.isHidden = true
        }
        else
        {
            self.controllerView.playerIndex = 0
            self.controllerView.addReceiver(emulatorCore)
            
            self.controllerView.isHidden = false
        }
        
        for controller in ExternalGameControllerManager.shared.connectedControllers
        {
            if controller.playerIndex != nil
            {
                controller.addReceiver(emulatorCore)
            }
            else
            {
                controller.removeReceiver(emulatorCore)
            }
        }
    }
}

@objc
private extension VisionGameViewController
{
    func didConnectGameController(_ notification: Notification)
    {
        self.updateGameControllers()
    }
    
    func didDisconnectGameController(_ notification: Notification)
    {
        self.updateGameControllers()
    }
}

extension VisionGameViewController: GameViewControllerDelegate
{
    func gameViewController(_ gameViewController: GameViewController, handleMenuInputFrom gameController: GameController) 
    {
        self.isShowingMenu.toggle()
        
        self.showMenuHandler?(self.isShowingMenu)
    }
}

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = try! Game(fileURL: fileURL)
        
    let viewController = VisionGameViewController()
    viewController.game = game
    return viewController
}
