//
//  FileManager_Ext.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 12/8/24.
//

import Foundation

extension FileManager {
    static func copyScriptToDocuments() {
        let fileManager = FileManager.default
        let documentsPath = Documents_Path
        
        do {
            try fileManager.createDirectory(
                atPath: documentsPath,
                withIntermediateDirectories: true
            )
            
            guard let scriptPath = Bundle.main.path(forResource: "transcribe", ofType: "py") else {
                print("[Error] Could not find `transcribe.py` in bundle")
                return
            }
            
            let transcribePath = documentsPath + "/transcribe.py"
            
            if !fileManager.fileExists(atPath: transcribePath) {
                try fileManager.copyItem(atPath: scriptPath, toPath: transcribePath)
            }
            
            guard let scriptPath = Bundle.main.path(forResource: "createDocument", ofType: "py") else {
                print("[Error] Could not find `createDocument.py` in bundle")
                return
            }
            
            let createDocPath = documentsPath + "/createDocument.py"
            
            if !fileManager.fileExists(atPath: createDocPath) {
                try fileManager.copyItem(atPath: scriptPath, toPath: createDocPath)
            }
        } catch {
            print("[Error] Error copying script: \(error)")
        }
    }
    
}
