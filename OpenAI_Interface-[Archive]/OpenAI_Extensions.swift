//
//  OpenAI_Extensions.swift
//  LMCC Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import Foundation
import UniformTypeIdentifiers

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension UTType {
    static var m4a: UTType {
        UTType(filenameExtension: "m4a")!
    }
}
