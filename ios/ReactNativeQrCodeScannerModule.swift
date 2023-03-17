import AVFoundation
import ExpoModulesCore

public class ReactNativeQrCodeScannerModule: Module {
  // We cannot resolve "Generic parameter R could not be inferred" error without this...
  let getAuthorizationStatusFunction = {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    @unknown default:
      return "notDetermined"
    }
  }

  public func definition() -> ModuleDefinition {
    Name("ReactNativeQrCodeScanner")

    Function("getAuthorizationStatus", getAuthorizationStatusFunction)

    AsyncFunction("requestAuthorizationAsync") { (promise: Promise) in
      AVCaptureDevice.requestAccess(for: .video) { granted in
        promise.resolve(granted)
      }
    }

    View(ReactNativeQrCodeScannerView.self) {
      Prop("type") { (view: ReactNativeQrCodeScannerView, cameraPosition: Either<String, Int>) in
        Task { @MainActor[cameraPosition] in
          if let cameraPosition: String = cameraPosition.get() {
            switch cameraPosition {
            case "front":
              view.changeCameraPosition(.front)
              break
            case "back":
              view.changeCameraPosition(.back)
              break
            default:
              NSLog("Unrecognized camera type = \(cameraPosition)")
              break
            }
          } else if let cameraPosition: Int = cameraPosition.get() {
            view.changeCameraPosition(
              AVCaptureDevice.Position(rawValue: cameraPosition) ?? .unspecified)
          }
        }
      }
      Events("onCameraReady", "onQrCodeScanned")
    }
  }
}
