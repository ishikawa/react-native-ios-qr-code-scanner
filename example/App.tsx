import { StyleSheet, Text } from "react-native";
import { QrCodeScannerView } from "react-native-qr-code-scanner";

export default function App() {
  return (
    <QrCodeScannerView style={styles.container}>
      <Text>Hello, native module!</Text>
    </QrCodeScannerView>
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
