# react-native-ios-qr-code-scanner

> An yet another QR code reader for React Native and Expo projects.

## Features

- **Supports iOS only.** Using iOS SDK built-in QR code reader that can read even obfuscated QR codes.
- **Supports structured format.** The library can read "Structured Append" metadata.
- **Based on [Expo Modules API](https://docs.expo.dev/modules/overview/)**. Empowered by modern technologies: Swift, TypeScript and [React Native New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page).

## Installation

```
$ npx expo install react-native-ios-qr-code-scanner
```

## Configuration in app.json/app.config.js

You can configure `react-native-ios-qr-code-scanner` using its built-in config plugin if you use config plugins in your project (EAS Build or `npx expo run:[android|ios]`). The plugin allows you to configure various properties that cannot be set at runtime and require building a new app binary to take effect.

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

```jsx
import { useEffect, useCallback, useState } from "react";
import { StyleSheet, Text, Button } from "react-native";
import {
  QrCodeScannedCallback,
  QrCodeScanner,
  requestAuthorizationAsync,
} from "react-native-ios-qr-code-scanner";

export default function App() {
  const [hasPermission, setHasPermission] =
    (useState < boolean) | (null > null);
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
