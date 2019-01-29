//
//  main.swift
//  FlawedCli
//
//  Created by Cowsay on 2019/1/29.
//  Copyright © 2019 Cowsay. All rights reserved.
//

import Foundation
import Flawed

let source = "x <- 42"
let tokens = try scan(source: source)
print(tokens)
