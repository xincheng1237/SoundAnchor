#!/usr/bin/env swift

import Foundation

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: build-icns.swift <AppIcon.appiconset> <output.icns>\n".utf8))
    exit(64)
}

let sourceDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

let representations: [(type: String, filename: String)] = [
    ("icp4", "icon_16x16.png"),
    ("ic11", "icon_16x16@2x.png"),
    ("icp5", "icon_32x32.png"),
    ("ic12", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic13", "icon_128x128@2x.png"),
    ("ic08", "icon_256x256.png"),
    ("ic14", "icon_256x256@2x.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png")
]

func appendBigEndian(_ value: UInt32, to data: inout Data) {
    var bigEndianValue = value.bigEndian
    withUnsafeBytes(of: &bigEndianValue) { bytes in
        data.append(contentsOf: bytes)
    }
}

do {
    var elements = Data()

    for representation in representations {
        guard let typeData = representation.type.data(using: .ascii), typeData.count == 4 else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let imageURL = sourceDirectory.appendingPathComponent(representation.filename)
        let imageData = try Data(contentsOf: imageURL)
        elements.append(typeData)
        appendBigEndian(UInt32(imageData.count + 8), to: &elements)
        elements.append(imageData)
    }

    var icon = Data("icns".utf8)
    appendBigEndian(UInt32(elements.count + 8), to: &icon)
    icon.append(elements)
    try icon.write(to: outputURL, options: .atomic)
} catch {
    FileHandle.standardError.write(Data("Could not build ICNS: \(error.localizedDescription)\n".utf8))
    exit(1)
}
