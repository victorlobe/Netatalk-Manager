//
//  Public Definitions.swift
//  Netatalk Manager
//
//  Created by Victor on 08.04.25.
//

import Foundation

public var showDockBadge: Bool {
    get { UserDefaults.standard.bool(forKey: "showDockBadge") }
    set { UserDefaults.standard.set(newValue, forKey: "showDockBadge") }
}
