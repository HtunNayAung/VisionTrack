//
//  BoundingBoxView.swift
//  Demo
//
//  Created by Htun Nay Aung on 12/3/2025.
//

import UIKit

class BoundingBoxView: UIView {
    var detectedBoxes: [(CGRect, String)] = [] {
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay() // 🔥 Force redraw when boxes update
            }
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.clear(rect)
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.red.withAlphaComponent(0.8).cgColor) // 🔴 Red with 80% opacity

        for (box, label) in detectedBoxes {
            let convertedBox = convertBoundingBox(box, to: rect.size)
            context.stroke(convertedBox)

            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.red,
                .font: UIFont.boldSystemFont(ofSize: 14)
            ]
            let text = NSString(string: label)
            text.draw(at: CGPoint(x: convertedBox.origin.x, y: convertedBox.origin.y - 20), withAttributes: attributes)
        }
    }

    private func convertBoundingBox(_ box: CGRect, to size: CGSize) -> CGRect {
        let x = box.origin.x * size.width
        let y = (1 - box.origin.y - box.height) * size.height // 🔥 Flip Y-axis for iOS
        let width = box.width * size.width
        let height = box.height * size.height

        print("📏 Converted Bounding Box: \(CGRect(x: x, y: y, width: width, height: height))") // Debug log

        return CGRect(x: x, y: y, width: width, height: height)
    }

}

