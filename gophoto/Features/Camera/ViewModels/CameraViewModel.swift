//
//  CameraViewModel.swift
//  gophoto
//
//  Created by Brian Juniarta Darmadi on 10/10/26.
//
//
//  CameraViewModel.swift
//  gophoto
//

import Observation
import AVFoundation
import UIKit

enum CameraState: Equatable {
    case idle
    case running
    case permissionDenied
    case failed(String)
}

@Observable
final class CameraViewModel {

    // MARK: State the View reads
    private(set) var state: CameraState = .idle
    private(set) var capturedImage: UIImage?
    private(set) var isCapturing = false
    private(set) var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var session: AVCaptureSession { cameraService.session }

    // MARK: Dependency (injected, like swiftshop's repositories)
    @ObservationIgnored private let cameraService: CameraServiceProtocol

    init(cameraService: CameraServiceProtocol = CameraService()) {
        self.cameraService = cameraService
    }

    // MARK: Intents (things the View asks for)

    func startCamera() async {
        guard await cameraService.requestPermission() else {
            state = .permissionDenied
            return
        }
        do {
            try await cameraService.configure()
            await cameraService.start()
            state = .running
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stopCamera() async {
        await cameraService.stop()
    }

    func takePhoto() async {
        guard state == .running, !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        do {
            capturedImage = try await cameraService.capturePhoto()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retake() {
        capturedImage = nil
    }
}
