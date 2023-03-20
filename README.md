# react-native-ios-qr-code-scanner

> Yet another QR code reader for React Native and Expo projects, focusing on iOS support.

## Features

- **iOS-centric:** Utilizes iOS SDK's built-in QR code reader for reliable and efficient QR code scanning.
- **Structured format support:** Seamlessly reads "Structured Append" QR codes, providing extended functionality.
- **Based on [Expo Modules API](https://docs.expo.dev/modules/overview/):** Leverages cutting-edge technologies, such as Swift, TypeScript, and [React Native New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page).

## Installation

To install the `react-native-ios-qr-code-scanner` package, run the following command in your terminal:

```
$ npx expo install react-native-ios-qr-code-scanner
```

This command installs the package and links it to your project automatically.

## Configuration in app.json/app.config.js

You can configure `react-native-ios-qr-code-scanner` using its built-in config plugin if you use config plugins in your project (EAS Build or `npx expo run:ios`). The plugin allows you to configure various properties that cannot be set at runtime and require building a new app binary to take effect.

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-ios-qr-code-scanner",
        {
          "cameraPermission": "Allow the app to access camera."
        }
      ]
    ]
  }
}
```

## Usage

The following example demonstrates how to use `react-native-ios-qr-code-scanner` in your React Native application:

```typescript
import { useEffect, useCallback, useState } from "react";
import { StyleSheet, Text, Button } from "react-native";
import {
  QrCodeScannedCallback,
  QrCodeScanner,
  requestAuthorizationAsync,
} from "react-native-ios-qr-code-scanner";

export default function App() {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scanned, setScanned] = useState(false);

  useEffect(() => {
    const getBarCodeScannerPermissions = async () => {
      const status = await requestAuthorizationAsync();
      setHasPermission(status);
    };

    getBarCodeScannerPermissions();
  }, []);

  const handleQrCode: QrCodeScannedCallback = useCallback((code) => {
    setScanned(true);

    console.log("QR code =", code);
    alert(`QR code with data ${code.data} has been scanned!`);
  }, []);

  if (hasPermission === null) {
    return <Text>Requesting for camera permission</Text>;
  }
  if (hasPermission === false) {
    return <Text>No access to camera</Text>;
  }

  return (
    <QrCodeScanner
      style={styles.container}
      onQrCodeScanned={scanned ? undefined : handleQrCode}
    >
      {scanned && (
        <Button title="Tap to Scan Again" onPress={() => setScanned(false)} />
      )}
    </QrCodeScanner>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
});
```
