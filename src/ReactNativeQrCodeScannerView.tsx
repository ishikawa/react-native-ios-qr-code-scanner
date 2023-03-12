import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { ReactNativeQrCodeScannerViewProps } from './ReactNativeQrCodeScanner.types';

const NativeView: React.ComponentType<ReactNativeQrCodeScannerViewProps> =
  requireNativeViewManager('ReactNativeQrCodeScanner');

export default function ReactNativeQrCodeScannerView(props: ReactNativeQrCodeScannerViewProps) {
  return <NativeView {...props} />;
}
