import { StyleSheet, Text, View } from 'react-native';

import * as ReactNativeQrCodeScanner from 'react-native-qr-code-scanner';

export default function App() {
  return (
    <View style={styles.container}>
      <Text>{ReactNativeQrCodeScanner.hello()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
