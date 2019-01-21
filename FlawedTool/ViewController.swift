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
    case success(LangNode.Statement)
    case failure(Error)
    case empty
}

class ViewController: NSViewController, NSTextViewDelegate {

    @IBOutlet var input: NSTextView!
    @IBOutlet var output: NSTextView!
    
    let font: NSFont! = NSFont(name: "Fira Mono", size: 12)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.font = font
        input.font = font
        
        representedObject = CompiledSource.empty
        NSLog("initialized")
    }
    
    override var representedObject: Any? {
        didSet {
            switch (representedObject as! CompiledSource) {
            case .empty:
                output.string = "Input your program above."
                output.textColor = NSColor.gray
            case .success(let node):
                output.string = "\(node)"
                output.textColor = NSColor.green
            case .failure(let error):
                output.string = "\(error)"
                output.textColor = NSColor.red
            }
        }
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }
        guard textView === input else {
            preconditionFailure()
        }
        let source = input.string
        guard !source.isEmpty else {
            representedObject = CompiledSource.empty
            return
        }
        do {
            let node = try parse(tokens: try scan(source: source))
            representedObject = CompiledSource.success(node)
        } catch {
            representedObject = CompiledSource.failure(error)
        }
    }
    
}

