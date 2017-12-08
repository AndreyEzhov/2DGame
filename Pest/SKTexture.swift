//
//  SKTexture.swift
//  Pest
//
//  Created by Andrey on 12/8/17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import SpriteKit
extension SKTexture {
    convenience init(pixelImageNamed: String) {
        self.init(imageNamed: pixelImageNamed)
        self.filteringMode = .nearest
    }
}
