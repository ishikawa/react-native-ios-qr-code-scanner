import {
  AndroidConfig,
  ConfigPlugin,
  createRunOncePlugin,
} from "expo/config-plugins";

//const pkg = require("react-native-ios-qr-code-scanner/package.json");

const CAMERA_USAGE = "Allow $(PRODUCT_NAME) to access your camera";
const MICROPHONE_USAGE = "Allow $(PRODUCT_NAME) to access your microphone";

const withQrCodeScanner: ConfigPlugin<
  {
    microphonePermission?: string;
    cameraPermission?: string;
  } | void
> = (config, { microphonePermission, cameraPermission } = {}) => {
  if (!config.ios) config.ios = {};
  if (!config.ios.infoPlist) config.ios.infoPlist = {};
  config.ios.infoPlist.NSCameraUsageDescription =
    cameraPermission ||
    config.ios.infoPlist.NSCameraUsageDescription ||
    CAMERA_USAGE;
  config.ios.infoPlist.NSMicrophoneUsageDescription =
    microphonePermission ||
    config.ios.infoPlist.NSMicrophoneUsageDescription ||
    MICROPHONE_USAGE;

  return AndroidConfig.Permissions.withPermissions(config, [
    "android.permission.CAMERA",
  ]);
};

export default createRunOncePlugin(
  withQrCodeScanner,
  "react-native-ios-qr-code-scanner" // pkg.name, pkg.version
);
