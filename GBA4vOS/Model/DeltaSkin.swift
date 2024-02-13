//
//  DeltaSkin.swift
//  GBA4vOS
//
//  Created by Riley Testut on 2/12/24.
//

import SwiftData
import UniformTypeIdentifiers

import DeltaCore

extension UTType
{
    static let deltaSkin = UTType(filenameExtension: "deltaskin")!
}

extension DeltaSkin
{
    struct Orientations: RawRepresentable, OptionSet, Codable
    {
        var id: Int16 { self.rawValue }
        
        static let portrait = Orientations(rawValue: 1 << 1)
        static let landscape = Orientations(rawValue: 1 << 2)
        
        let rawValue: Int16
        
        init(rawValue: Int16)
        {
            self.rawValue = rawValue
        }
            
        init()
        {
            self.rawValue = 0
        }
    }
}

@Model
final class DeltaSkin
{
    @Attribute(.unique)
    let identifier: String
    
    let gameType: String
    
    let name: String
    let filename: String
    
    let orientations: Orientations
    
    var skin: ControllerSkin? {
        if _skin == nil
        {
            _skin = ControllerSkin(fileURL: self.fileURL)
        }
        
        return _skin
    }
    
    @Transient
    private var _skin: ControllerSkin?
    
    init?(fileURL: URL)
    {
        guard let controllerSkin = DeltaCore.ControllerSkin(fileURL: fileURL) else { return nil }
        
        self.identifier = controllerSkin.identifier
        self.gameType = controllerSkin.gameType.rawValue
        
        self.name = controllerSkin.name
        self.filename = fileURL.lastPathComponent
        
        var orientations = Orientations()
        
        let portraitTraits = ControllerSkin.Traits(device: .iphone, displayType: .standard, orientation: .portrait)
        if controllerSkin.supports(portraitTraits)
        {
            orientations.formUnion(.portrait)
        }
        
        var landscapeTraits = portraitTraits
        landscapeTraits.orientation = .landscape
        
        if controllerSkin.supports(landscapeTraits)
        {
            orientations.formUnion(.landscape)
        }
        
        self.orientations = orientations
    }
    
    convenience init?(controllerSkin: ControllerSkin)
    {
        self.init(fileURL: controllerSkin.fileURL)
        
        self._skin = controllerSkin
    }
}

extension DeltaSkin
{
    var fileURL: URL {
        let directoryURL = DeltaSkin.skinsDirectory()
        
        let fileURL = directoryURL.appending(path: self.filename)
        return fileURL
    }
}

extension DeltaSkin
{
    static func skinsDirectory() -> URL
    {
        let databaseDirectory = URL.documentsDirectory.appending(path: "Database")
        let skinsDirectory = databaseDirectory.appending(path: "Skins", directoryHint: .isDirectory)
        
        do
        {
            try FileManager.default.createDirectory(at: skinsDirectory, withIntermediateDirectories: true)
        }
        catch
        {
            print("Failed to create Skins directory.", error.localizedDescription)
        }
        
        return skinsDirectory
    }
}
