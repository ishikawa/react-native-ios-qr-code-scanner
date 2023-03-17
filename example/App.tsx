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
