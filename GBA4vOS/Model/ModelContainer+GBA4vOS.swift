//
//  ModelContainer+Previews.swift
//  GBA4vOS
//
//  Created by Riley Testut on 1/19/24.
//

import Foundation
import SwiftData

extension ModelContainer
{
    @MainActor
    static let main: ModelContainer = {
        do
        {
            let container = try ModelContainer(for: SaveState.self, DeltaSkin.self)
            return container
        }
        catch
        {
            fatalError("Failed to load model container. \(error.localizedDescription)")
        }
    }()
    
    @MainActor
    static let preview: ModelContainer = {
        do
        {
            let container = try ModelContainer(for: SaveState.self, DeltaSkin.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            return container
        }
        catch
        {
            fatalError("Failed to load model container. \(error.localizedDescription)")
        }
    }()
}
