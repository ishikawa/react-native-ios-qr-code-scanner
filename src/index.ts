import { requireNativeModule } from "expo-modules-core";
export {
  default as QrCodeScanner,
  Props as QrCodeScannerViewProps,
  QrCodePoint,
  QrCodeBounds,
  QrCodeScannerResult,
  QrCodeSize,
  CameraReadyCallback,
  QrCodeScannedCallback,
} from "./ReactNativeQrCodeScannerView";

// Constants that indicate the status of an app’s authorization to capture media.
export type QrCodeAuthorizationStatus =
  // A status that indicates the user hasn’t yet granted or denied authorization.
  | "notDetermined"
  // A status that indicates the app isn’t permitted to use media capture devices.
  | "restricted"
  // A status that indicates the user has explicitly denied an app permission to capture media.
  | "denied"
  // A status that indicates the user has explicitly granted an app permission to capture media.
  | "authorized";

interface NativeModule {
  getAuthorizationStatus(): QrCodeAuthorizationStatus;
  requestAuthorizationAsync(): Promise<boolean>;
}

const nativeModule = requireNativeModule<NativeModule>(
  "ReactNativeQrCodeScanner"
);

// Checks user's permissions for accessing the camera.
export function getAuthorizationStatus(): QrCodeAuthorizationStatus {
  return nativeModule.getAuthorizationStatus();
}

// Asks the user to grant permissions for accessing the camera.
//
// On iOS this will require apps to specify the `NSCameraUsageDescription` entry in the
// `Info.plist`.
export function requestAuthorizationAsync(): Promise<boolean> {
  return nativeModule.requestAuthorizationAsync();
}
