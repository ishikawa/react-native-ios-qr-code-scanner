import * as React from 'react';

import { ReactNativeQrCodeScannerViewProps } from './ReactNativeQrCodeScanner.types';

export default function ReactNativeQrCodeScannerView(props: ReactNativeQrCodeScannerViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
