//
//  SwiftLocationPlayground
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import CoreLocation
import MapKit

protocol MapDrawViewDelegate: class {
    
    func drawView(view: MapDrawView, didCompletedPolygon points: [CGPoint])
    
    func drawView(view: MapDrawView, didCompleteTap center: CGPoint)
    
}


class MapDrawView: UIView, UIGestureRecognizerDelegate {
    
    public enum Mode {
        case disabled
        case drawPolygon
        case drawCircle
        
        public var canEdit: Bool {
            switch self {
            case .disabled: return false
            default: return true
            }
        }
    }
    
    public var mode: Mode = .disabled {
        didSet {
            setMode(mode)
        }
    }
    
    weak var delegate: MapDrawViewDelegate?
    weak var mapView: MKMapView?

    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!

    private var points = [CGPoint]()
    private var lastPosition = CGPoint()
    
    private var path = UIBezierPath()
    
    init() {
        super.init(frame: .zero)
        
        setupDrawing()
        
        defer {
            self.mode = .disabled
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let strokeColor = UIColor.blue
        strokeColor.setStroke()
        
        path.stroke()
    }
    
    @objc private func didReceivePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            start(gestureRecognizer: gesture)
        case .changed:
            move(gestureRecognizer: gesture)
        case .ended:
            end(gestureRecognizer: gesture)
        default:
            break
        }
    }

    private func setMode(_ mode: Mode) {
        switch mode {
        case .disabled:
            isUserInteractionEnabled = false
            panGesture.isEnabled = false
            tapGesture.isEnabled = false
            
        case .drawCircle:
            isUserInteractionEnabled = true
            panGesture.isEnabled = false
            tapGesture.isEnabled = true


        case .drawPolygon:
            isUserInteractionEnabled = true
            panGesture.isEnabled = true
            tapGesture.isEnabled = false

        }
    }
    
    private func setupDrawing() {
        isMultipleTouchEnabled = true
        isOpaque = false
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture))
        addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCenterOfPoint))
        addGestureRecognizer(tapGesture)
    }
    
    
    @objc private func didTapCenterOfPoint(_ gesture: UITapGestureRecognizer) {
        let center = gesture.location(in: gesture.view)
        delegate?.drawView(view: self, didCompleteTap: center)
    }
    
    private func start(gestureRecognizer: UIPanGestureRecognizer) {
        lastPosition = gestureRecognizer.location(in: gestureRecognizer.view)
        points = [lastPosition]
        
        path = UIBezierPath()
        path.lineWidth = 2.0
        path.move(to: lastPosition)
        setNeedsDisplay()
    }
    
    private func move(gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        points.append(location)
        
        path.addLine(to: location)
        setNeedsDisplay()
    }
    
    private func end(gestureRecognizer: UIPanGestureRecognizer) {
        guard points.count > 2 else {
            return
        }
        
        var startIndex = 0
        var endIndex = 1
        var newPoints = [points[startIndex]]
        while endIndex < points.count - 1 {
            let dist = distance(lineStart: points[startIndex], lineEnd: points[endIndex], point: points[endIndex + 1])
            print(dist)
            
            if dist > 0.5 {
                newPoints.append(points[endIndex])
                startIndex = endIndex
            }
            
            endIndex += 1
        }
        newPoints.append(points.last!)
        delegate?.drawView(view: self, didCompletedPolygon: newPoints)
        
        path = UIBezierPath()
        setNeedsDisplay()
    }
    
    // Distance between line and point: https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    private func distance(lineStart: CGPoint, lineEnd: CGPoint, point: CGPoint) -> Double {
        let x0 = point.x, y0 = point.y
        let x1 = lineStart.x, y1 = lineStart.y
        let x2 = lineEnd.x, y2 = lineEnd.y
        
        let numerator =  abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1)
        let denominator = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2))
        
        return denominator == 0.0 ? 0.0 : Double(numerator / denominator)
    }
    
}
