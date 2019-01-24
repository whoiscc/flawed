//
//  ViewController.swift
//  FlawedTool
//
//  Created by Cowsay on 2019/1/20.
//  Copyright © 2019 Cowsay. All rights reserved.
//

import Cocoa
import Flawed

enum CompiledSource {
    case success([Instruction])
    case failure(Error)
    case empty
}

let env = [
    "+": BindName.alloc(),
    "-": BindName.alloc(),
    "*": BindName.alloc(),
    "/": BindName.alloc(),
    "abs": BindName.alloc(),
]

class ViewController: NSViewController, NSWindowDelegate {

    @IBOutlet var input: NSTextView!
    @IBOutlet var output: NSTextView!
    
    let font: NSFont! = NSFont(name: "Fira Mono", size: 12)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.font = font
        input.font = font
        
        representedObject = CompiledSource.empty
        
        input.heightAnchor.constraint(equalTo: output.heightAnchor, multiplier: 1.0).isActive = true
    }

    override func viewDidAppear() {
        view.window?.delegate = self
    }
    
    override var representedObject: Any? {
        didSet {
            switch (representedObject as! CompiledSource) {
            case .empty:
                output.string = "Input your program above."
                output.textColor = NSColor.gray
            case .success(let node):
                output.string = "\(node)"
                output.textColor = NSColor.blue
            case .failure(let error):
                output.string = "\(error)"
                output.textColor = NSColor.red
            }
        }
    }

    @IBAction func onCompile(_ sender: Any) {
        NSLog("compile")
        let source = input.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            representedObject = CompiledSource.empty
            return
        }
        do {
            let node = try parse(tokens: try scan(source: source))
            let inst = try eval(stat: node, env: env)
            representedObject = CompiledSource.success(inst)
        } catch {
            representedObject = CompiledSource.failure(error)
        }
    }
    
}

