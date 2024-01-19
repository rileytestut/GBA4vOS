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
        
        func makeUIViewController(context: Context) -> GameViewController
        {
            let gameViewController = VisionGameViewController()
            gameViewController.game = game
            
            if let emulatorCore = gameViewController.emulatorCore
            {
                self.coreHandler(emulatorCore)
            }
            
            return gameViewController
        }
        
        func updateUIViewController(_ gameViewController: GameViewController, context: Context)
        {
        }
        
        init(game: Game?, coreHandler: @escaping (EmulatorCore) -> Void)
        {
            self.game = game
            self.coreHandler = coreHandler
        }
    }
}

class VisionGameViewController: GameViewController
{
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
        
        self.controllerView.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisionGameViewController.didConnectGameController(_:)), name: .externalGameControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VisionGameViewController.didDisconnectGameController(_:)), name: .externalGameControllerDidDisconnect, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) 
    {
        super.viewDidAppear(animated)
        
        self.updateGameControllers()
    }
}

private extension VisionGameViewController
{
    func updateGameControllers()
    {
        guard let emulatorCore = self.emulatorCore else { return }
        
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

#Preview {
    let fileURL = Bundle.main.url(forResource: "Emerald", withExtension: "gba")!
    let game = try! Game(fileURL: fileURL)
        
    let viewController = VisionGameViewController()
    viewController.game = game
    return viewController
}
