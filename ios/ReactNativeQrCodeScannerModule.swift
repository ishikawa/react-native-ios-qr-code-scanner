import ExpoModulesCore

public class ReactNativeQrCodeScannerModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    Name("ReactNativeQrCodeScanner")

    View(ReactNativeQrCodeScannerView.self) {}
  }
}
