import AVFoundation
import Darwin
import ExpoModulesCore

enum CaptureSessionError: Error {
  case noCaptureDevice
  case noCaptureDeviceInput(Error)
  case permissionDenied
}

protocol CaptureSessionDelegate: AnyObject {
  func captureSessionOnReady(_ session: CaptureSession)
  func captureSession(
    _ session: CaptureSession, didScanQrCode descriptor: CIQRCodeDescriptor,
    with metadataObject: AVMetadataMachineReadableCodeObject)
}

actor CaptureSession: NSObject {
  private weak var delegate: CaptureSessionDelegate?

  private var cameraPosition: AVCaptureDevice.Position = .back

  private let session = AVCaptureSession()

  private var sessionPaused = false

  let previewLayer: AVCaptureVideoPreviewLayer

  private var deviceInput: AVCaptureDeviceInput?

  private let metadataOutput = AVCaptureMetadataOutput()

  private let metadataOutputQueue = DispatchQueue(label: "metadataOutputQueue")

  private var sessionRuntimeErrorObserver: NSObjectProtocol?

  init(delegate: CaptureSessionDelegate?) {
    self.delegate = delegate

    // Preview layer
    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    self.previewLayer.videoGravity = .resizeAspectFill
    self.previewLayer.needsDisplayOnBoundsChange = true

    super.init()

    // Configure metadata output
    self.metadataOutput.setMetadataObjectsDelegate(self, queue: self.metadataOutputQueue)
  }

  deinit {
    if let observer = self.sessionRuntimeErrorObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  func resume() {
    if self.session.isRunning || !self.sessionPaused {
      return
    }

    // Resume session
    self.sessionPaused = false
    self.session.startRunning()
  }

  func suspend() {
    if !self.session.isRunning || self.sessionPaused {
      return
    }

    // Suspend session
    self.sessionPaused = true
    self.session.stopRunning()
  }

  func changePreviewOrientation(_ orientation: UIInterfaceOrientation) {
    let videoOrientation = QrCodeScannerUtils.videoOrientationForInterfaceOrientation(
      orientation)

    if let conn = self.previewLayer.connection,
      conn.isVideoOrientationSupported
    {
      conn.videoOrientation = videoOrientation
    }
  }

  func changeCameraPosition(
    _ cameraPosition: AVCaptureDevice.Position, orientation: UIInterfaceOrientation
  ) throws {
    if self.cameraPosition == cameraPosition {
      return
    }

    self.cameraPosition = cameraPosition
    try self.initializeSession(orientation)
  }

  func initializeSession(_ interfaceOrientation: UIInterfaceOrientation) throws {
    if let devicePosition = self.deviceInput?.device.position,
      devicePosition == self.cameraPosition
    {
      // Already initialized
      return
    }

    // Initialize device input
    guard
      let captureDevice = AVCaptureDevice.default(
        .builtInWideAngleCamera, for: .video, position: self.cameraPosition)
    else {
      throw CaptureSessionError.noCaptureDevice
    }

    let captureDeviceInput: AVCaptureDeviceInput

    do {
      captureDeviceInput = try AVCaptureDeviceInput.init(device: captureDevice)
    } catch {
      throw CaptureSessionError.noCaptureDeviceInput(error)
    }

    // Apply configuration changes
    self.session.beginConfiguration()

    if let deviceInput = self.deviceInput {
      self.session.removeInput(deviceInput)
    }

    if self.session.canAddInput(captureDeviceInput) {
      self.session.addInput(captureDeviceInput)

      self.deviceInput = captureDeviceInput
      self.changePreviewOrientation(interfaceOrientation)
    }

    if self.session.canAddOutput(self.metadataOutput) {
      self.session.removeOutput(self.metadataOutput)
      session.addOutput(self.metadataOutput)

      // Configure metadataObjectTypes
      if self.metadataOutput.availableMetadataObjectTypes.contains(.qr) {
        self.metadataOutput.metadataObjectTypes = [.qr]
      }
    }

    self.session.commitConfiguration()

    // Start session
    if self.session.isRunning {
      return
    }

    if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
      throw CaptureSessionError.permissionDenied
    }
    if self.cameraPosition == .unspecified {
      return
    }

    if let observer = self.sessionRuntimeErrorObserver {
      NotificationCenter.default.removeObserver(observer)
    }

    self.sessionRuntimeErrorObserver = NotificationCenter.default.addObserver(
      forName: .AVCaptureSessionRuntimeError,
      object: self.session,
      queue: nil,
      using: { [weak self] (note) in
        // Manually restarting the session since it must have been stopped due to an error.
        Task.detached { [weak self] in
          if let it = self {
            await it.startSession()
          }
        }
      }
    )

    self.startSession()
  }

  private func startSession() {
    self.session.startRunning()
    self.delegate?.captureSessionOnReady(self)
  }

  func stopSession() {
    self.previewLayer.removeFromSuperlayer()
    self.session.commitConfiguration()
    self.session.stopRunning()
    for input in self.session.inputs {
      self.session.removeInput(input)
    }
    for output in self.session.outputs {
      self.session.removeOutput(output)
    }
  }
}

extension CaptureSession: AVCaptureMetadataOutputObjectsDelegate {
  @objc nonisolated func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    for metadataObject in metadataObjects {
      let codeMetadata = self.previewLayer.transformedMetadataObject(for: metadataObject)

      guard let readableObject = codeMetadata as? AVMetadataMachineReadableCodeObject else {
        continue
      }
      guard let qrCodeDescriptor = readableObject.descriptor as? CIQRCodeDescriptor else {
        continue
      }

      Task {
        await self.delegate?.captureSession(
          self, didScanQrCode: qrCodeDescriptor, with: readableObject)
      }
    }
  }
}

@MainActor
class ReactNativeQrCodeScannerView: ExpoView, CaptureSessionDelegate {
  // Expo Module: View callbacks
  let onCameraReady = EventDispatcher()
  let onQrCodeScanned = EventDispatcher()

  // To configure with `self` as delegate, we have to initialize an actor lazily.
  private var captureSession: CaptureSession!

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    self.clipsToBounds = true
    self.captureSession = CaptureSession(delegate: self)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(type(of: self).onOrientationChanged(notification:)),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(type(of: self).onAppDidBecomeActive(notification:)),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(type(of: self).onAppDidEnterBackgrounded(notification:)),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )

    Task.detached {
      do {
        try await self.captureSession!.initializeSession(self.currentInterfaceOrientation())
      } catch CaptureSessionError.noCaptureDevice {
        await self.onMountingError(message: "Camera could not be started - no device.")
      } catch CaptureSessionError.noCaptureDeviceInput(let error) {
        await self.onMountingError(
          message: "Camera could not be started - \(error.localizedDescription)")
      }
    }
  }

  // MARK: - events
  nonisolated func captureSessionOnReady(_ session: CaptureSession) {
    Task { @MainActor in
      self.onCameraReady()
    }
  }

  nonisolated func captureSession(
    _ session: CaptureSession, didScanQrCode descriptor: CIQRCodeDescriptor,
    with metadataObject: AVMetadataMachineReadableCodeObject
  ) {
    let payload = descriptor.errorCorrectedPayload

    // Structured Append: parse QR code metadata to determine structured or not.
    //
    // - If a QR code is structured, `mode` is `0x3`.
    // - `seq total` is 0 based.
    //
    // +--------------------+-------------------+-------------------+
    // | mode (4bits = 0x3) | seq index (4bits) | seq total (4bits) |
    // +--------------------+-------------------+-------------------+
    var seqIndex: Int? = nil
    var seqTotal: Int? = nil

    if payload.count >= 2 && ((payload[0] >> 4) & 0b1111) == 3 {
      seqIndex = Int(payload[0] & 0b1111)
      seqTotal = Int((payload[1] >> 4) & 0b1111) + 1
    }

    let data = metadataObject.stringValue
    let cornerPoints = metadataObject.corners.map { point in
      ["x": point.x, "y": point.y]
    }
    let bounds = [
      "origin": [
        "x": metadataObject.bounds.origin.x,
        "y": metadataObject.bounds.origin.y,
      ],
      "size": [
        "width": metadataObject.bounds.size.width,
        "height": metadataObject.bounds.size.height,
      ],
    ]

    Task { @MainActor[seqIndex, seqTotal] in
      var eventData: [String: Any] = [
        "cornerPoints": cornerPoints,
        "bounds": bounds,
        "data": data as Any,
      ]

      if let seqIndex = seqIndex {
        eventData["structuredAppendIndex"] = seqIndex
      }
      if let seqTotal = seqTotal {
        eventData["structuredAppendTotal"] = seqTotal
      }

      self.onQrCodeScanned(eventData)
    }
  }

  private func onMountingError(message: String) {
    fputs("[QrCodeScannerView] ERROR: \(message)\n", stderr)
  }

  override func layoutSubviews() {
    let bounds = self.bounds

    self.backgroundColor = UIColor.black
    super.layoutSubviews()

    let previewLayer = self.captureSession.previewLayer

    previewLayer.frame = bounds
    self.layer.insertSublayer(previewLayer, at: 0)
  }

  override func removeFromSuperview() {
    Task.detached {
      await self.captureSession.stopSession()
    }

    super.removeFromSuperview()
    NotificationCenter.default.removeObserver(
      self,
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
  }

  @objc private func onOrientationChanged(notification: Notification) {
    let orientation = self.currentInterfaceOrientation()
    self.changePreviewOrientation(orientation)
  }

  @objc private func onAppDidBecomeActive(notification: Notification) {
    Task {
      await self.captureSession.resume()
    }
  }

  @objc private func onAppDidEnterBackgrounded(notification: Notification) {
    Task {
      await self.captureSession.suspend()
    }
  }

  // MARK: - methods

  func changeCameraPosition(_ cameraPosition: AVCaptureDevice.Position) {
    Task.detached {
      do {
        try await self.captureSession!.changeCameraPosition(
          cameraPosition, orientation: self.currentInterfaceOrientation())
      } catch CaptureSessionError.noCaptureDevice {
        await self.onMountingError(message: "Camera could not be started - no device.")
      } catch CaptureSessionError.noCaptureDeviceInput(let error) {
        await self.onMountingError(
          message: "Camera could not be started - \(error.localizedDescription)")
      }
    }
  }

  private func changePreviewOrientation(_ orientation: UIInterfaceOrientation) {
    Task {
      await self.captureSession.changePreviewOrientation(orientation)
    }
  }

  private func currentInterfaceOrientation() -> UIInterfaceOrientation {
    // Fallback to `UIApplication.shared.statusBarOrientation` (deprecated) because
    // WindowScene.interfaceOrientation returns `nil` if the view is not present.
    return self.window?.windowScene!.interfaceOrientation
      ?? UIApplication.shared.statusBarOrientation
  }
}

struct QrCodeScannerUtils {
  static func videoOrientationForInterfaceOrientation(_ orientation: UIInterfaceOrientation)
    -> AVCaptureVideoOrientation
  {
    switch orientation {
    case .portrait:
      return .portrait
    case .portraitUpsideDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeLeft
    case .landscapeRight:
      return .landscapeRight
    default:
      return .portrait
    }
  }
}
