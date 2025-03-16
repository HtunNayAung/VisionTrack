//
//  LiveMetalCameraViewController.swift
//  Demo
//
//  Created by Htun Nay Aung on 5/3/2025.
//

import UIKit
import Vision
import AVFoundation

class LiveMetalCameraViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var metalVideoPreview: MetalVideoView!
    var boundingBoxView: BoundingBoxView!
    var modelCounter = 0
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    var cameraTextureGenerater = CameraTextureGenerater()
    var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
    var overlayingTexturesGenerater = OverlayingTexturesGenerater()
    
    var cameraTexture: Texture?
    var segmentationTexture: Texture?
    
    // Speech Synthesizer
    let speechSynthesizer = AVSpeechSynthesizer()
    var lastSpokenTime: [String: TimeInterval] = [:] // Tracks when each object was last spoken
    let speechCooldown: TimeInterval = 3.0
    var isSpeaking = false
    
    // MARK: - AV Properties
    var videoCapture: VideoCapture!
    lazy var segmentationModel = { return try! lane_deeplabv3_ImageTensor() }()
    let numberOfLabels = 2
    lazy var detectionModel = { return try! newd11() }()
    lazy var potholeModel = { return try! pothole_v12n() }()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var detectionRequest: VNCoreMLRequest?
    var potholeRequest: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    var isInferencing = false
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boundingBoxView = BoundingBoxView(frame: view.bounds)
        boundingBoxView.backgroundColor = UIColor.clear // Transparent background
        boundingBoxView.alpha = 0.8
        self.view.addSubview(boundingBoxView)

        // setup ml model
        setUpModel()
        
        // setup camera
        setUpCamera()
        
        // setup delegate for performance measurement
        👨‍🔧.delegate = self
        
        speechSynthesizer.delegate = self // ✅ Ensure delegate is set
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .centerCrop
        } else {
            fatalError()
        }

        if let objectModel = try? VNCoreMLModel(for: detectionModel.model) {
            detectionRequest = VNCoreMLRequest(model: objectModel, completionHandler: detectionRequestDidComplete)
            detectionRequest?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("Failed to load object detection model")
        }
        
        // Load Pothole Detection Model
        if let potholeVisionModel = try? VNCoreMLModel(for: potholeModel.model) {
            potholeRequest = VNCoreMLRequest(model: potholeVisionModel, completionHandler: potholeRequestDidComplete)
            potholeRequest?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("Failed to load pothole detection model")
        }
    }
    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 10
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            
            if success {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.videoCapture.start()
                }
            }
        }
    }
    
    func speak(_ message: String) {
        let currentTime = Date().timeIntervalSince1970

        // Check if object was spoken recently
        if let lastTime = lastSpokenTime[message], currentTime - lastTime < speechCooldown {
            print("⏳ Skipping speech for \(message), spoken too recently.")
            return
        }

        lastSpokenTime[message] = currentTime // Update last spoken time
        
        DispatchQueue.main.async {
            print("🔊 Speaking:", message)
            let utterance = AVSpeechUtterance(string: message)
            utterance.rate = 0.5
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            self.speechSynthesizer.speak(utterance)
        }
    }
}
// MARK: - AVSpeechSynthesizerDelegate
extension LiveMetalCameraViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ Finished speaking:", utterance.speechString)
        
        isSpeaking = false // Ensure it resets
        print("✅ inside didFINISH isSpeaking", isSpeaking)
//        DispatchQueue.main.async { // Small delay
//            self.processSpeechQueue() // Continue processing speech queue
//        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
//        DispatchQueue.main.async {
//            self.processSpeechQueue()
//        }
    }
}


// MARK: - VideoCaptureDelegate
extension LiveMetalCameraViewController: VideoCaptureDelegate {
    
    func videoCapture(_ capture: VideoCapture, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        
        cameraTexture = cameraTextureGenerater.texture(from: sampleBuffer)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if !isInferencing {
            isInferencing = true

            // start of measure
            self.👨‍🔧.🎬👏()

            // predict!
            predict(with: pixelBuffer)
            predictDetection(with: pixelBuffer)
            predictPotholeDetection(with: pixelBuffer)

//
        }
    }
    
}

// MARK: - Inference
extension LiveMetalCameraViewController {
    // prediction
    func predict(with pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    func predictDetection(with pixelBuffer: CVPixelBuffer){
        guard let detectionRequest = detectionRequest else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([detectionRequest])
    }
    
    func predictPotholeDetection(with pixelBuffer: CVPixelBuffer) {
        guard let potholeRequest = potholeRequest else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([potholeRequest])
    }

    
    // post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")

        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationmap = observations.first?.featureValue.multiArrayValue {
            
            print("Segmentation map shape: \(segmentationmap.shape)")

            if segmentationmap.shape.count == 4 {
                // Custom Model (Shape: [1, 512, 512, 2])
                let batch = segmentationmap.shape[0].intValue
                let row = segmentationmap.shape[1].intValue
                let col = segmentationmap.shape[2].intValue
                let channels = segmentationmap.shape[3].intValue

                print("Batch: \(batch), Rows: \(row), Cols: \(col), Channels: \(channels)")

                if batch != 1 {
                    print("⚠️ Unexpected batch size: \(batch)")
                    return
                }

                // Convert multi-channel output to class indices
                let processedMap = extractClassIndices(from: segmentationmap, row: row, col: col, channels: channels)

                processSegmentationMap(processedMap, row, col)
            } else {
                print("Unexpected shape for segmentation map.")
            }
        } else {
            print("No segmentation results.")
        }

        self.👨‍🔧.🎬🤚()
        isInferencing = false
    }

    func extractClassIndices(from multiArray: MLMultiArray, row: Int, col: Int, channels: Int) -> MLMultiArray {
        let outputArray = try! MLMultiArray(shape: [row, col] as [NSNumber], dataType: .int32)

        for i in 0..<row {
            for j in 0..<col {
                let index1 = i * col * channels + j * channels
                let index2 = index1 + 1

                let class0_prob = multiArray[index1].floatValue
                let class1_prob = multiArray[index2].floatValue

                // Use argmax to determine class index
                outputArray[i * col + j] = class0_prob > class1_prob ? 0 : 1
            }
        }
        
        return outputArray
    }
    
    func processSegmentationMap(_ segmentationMap: MLMultiArray, _ row: Int, _ col: Int) {
        guard let cameraTexture = cameraTexture else {
            print("Camera texture is nil")
            return
        }

        // Convert the segmentation output into a texture
        guard let segmentationTexture = multitargetSegmentationTextureGenerater.texture(segmentationMap, row, col, numberOfLabels) else {
            print("Failed to generate segmentation texture")
            return
        }

        // Overlay segmentation result on top of the camera preview
        let overlayedTexture = overlayingTexturesGenerater.texture(cameraTexture, segmentationTexture)
        
        DispatchQueue.main.async {
            self.metalVideoPreview.currentTexture = overlayedTexture
            self.isInferencing = false
        }
    }
    
    func detectionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNRecognizedObjectObservation] {

            let allowedObjects: Set<String> = [
                "motorcycle", "person", "skateboard", "bicycle", "traffic light",
                "cat", "dog", "train", "car", "bus", "truck"
            ]
            
            var detectedObjects: Set<String> = []
            var detectedBoxes: [(CGRect, String)] = []

            for observation in observations {
                let label = observation.labels.first?.identifier ?? "Unknown"
                let confidence = observation.labels.first?.confidence ?? 0.0
                let box = observation.boundingBox

                if confidence > 0.5 && allowedObjects.contains(label) {
                    print(label, " detected")
                    detectedBoxes.append((box, label))
                    detectedObjects.insert(label)
                }
            }

            // Handle UI Updates
            DispatchQueue.main.async {
                if detectedBoxes.isEmpty {
                    print("No bounding boxes detected. Clearing previous boxes.")
                    self.boundingBoxView.detectedBoxes = []
                } else {
                    print("Filtered \(detectedBoxes.count) objects.")
                    self.drawBoundingBoxes(detectedBoxes)
                }
            }

            // Prepare the speech announcement
            for object in detectedObjects {
                speak(object + " detected") // Speak out each unique detected object naturally
           }
        } else {
            print("No observations from Core ML model.")
            DispatchQueue.main.async {
                self.boundingBoxView.detectedBoxes = []
            }
        }
    }

    
    func potholeRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNRecognizedObjectObservation] {
            print("🔍 Pothole Observations: \(observations)")

            var potholeBoxes: [(CGRect, String)] = []

            for observation in observations {
                let label = observation.labels.first?.identifier ?? "Unknown"
                let confidence = observation.labels.first?.confidence ?? 0.0
                let box = observation.boundingBox

                print("Detected: \(label) (\(confidence * 100)%) at \(box)")

                if confidence > 0.5 { // Adjust threshold if needed
                    potholeBoxes.append((box, "Pothole")) // Always label as "Pothole"
                }
            }

            // Merge pothole detection with object detection
            DispatchQueue.main.async {
                self.boundingBoxView.detectedBoxes += potholeBoxes
            }
        } else {
            print("No potholes detected.")
        }
    }
    
    func drawBoundingBoxes(_ detectedBoxes: [(CGRect, String)]) {
            DispatchQueue.main.async {
                guard !detectedBoxes.isEmpty else {
                            print("No bounding boxes detected.")
                            return
                        }
                guard let boundingBoxView = self.boundingBoxView else {
                    print("Error: boundingBoxView is nil!")
                    return
                }
                boundingBoxView.detectedBoxes = detectedBoxes
            }
        }
}

// MARK: - 📏(Performance Measurement) Delegate
extension LiveMetalCameraViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        DispatchQueue.main.async {
            self.maf1.append(element: Int(inferenceTime*1000.0))
            self.maf2.append(element: Int(executionTime*1000.0))
            self.maf3.append(element: fps)
            
            self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
            self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
            self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
        }
    }
}


class MovingAverageFilter {
    private var arr: [Int] = []
    private let maxCount = 10
    
    public func append(element: Int) {
        arr.append(element)
        if arr.count > maxCount {
            arr.removeFirst()
        }
    }
    
    public var averageValue: Int {
        guard !arr.isEmpty else { return 0 }
        let sum = arr.reduce(0) { $0 + $1 }
        return Int(Double(sum) / Double(arr.count))
    }
}
