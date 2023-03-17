import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { ViewProps } from "react-native";

// Those coordinates are represented in the coordinate space of the source. When you are using the
// scanner view, these values are adjusted to the dimensions of the view.
export type QrCodePoint = {
  x: number;
  y: number;
};

// Those coordinates are represented in the coordinate space of the source. When you are using the
// scanner view, these values are adjusted to the dimensions of the view.
export type QrCodeSize = {
  width: number;
  height: number;
};

export type QrCodeBounds = {
  origin: QrCodePoint;
  size: QrCodeSize;
};

export type QrCodeScannerResult = {
  data: string | null;
  cornerPoints: QrCodePoint[];
  bounds: QrCodeBounds;
  structuredAppendIndex?: number;
  structuredAppendTotal?: number;
};

// Callback invoked when camera preview has been set.
export type CameraReadyCallback = () => void;

// A callback that is invoked when a bar code has been successfully scanned.
export type QrCodeScannedCallback = (result: QrCodeScannerResult) => void;

export type QrCodeCameraPosition = "front" | "back" | number;

export type Props = {
  // Camera facing.
  type?: QrCodeCameraPosition;
  // Callback invoked when camera preview has been set.
  onCameraReady?: CameraReadyCallback;
  // A callback that is invoked when a bar code has been successfully scanned.
  onQrCodeScanned?: QrCodeScannedCallback;
} & ViewProps;

type NativeViewProps = {
  type?: QrCodeCameraPosition;
  onCameraReady?: (event: NativeOnCameraReadyEvent) => void;
  onQrCodeScanned?: (event: NativeOnQrCodeScannedEvent) => void;
} & ViewProps;

interface NativeOnCameraReadyEvent {
  nativeEvent: {
    target: number;
  };
}

interface NativeOnQrCodeScannedEvent {
  nativeEvent: {
    target: number;
  } & QrCodeScannerResult;
}

const NativeView: React.ComponentType<NativeViewProps> =
  requireNativeViewManager("ReactNativeQrCodeScanner");

export default function ReactNativeQrCodeScannerView(props: Props) {
  const onCameraReady = props.onCameraReady;
  const onQrCodeScanned = props.onQrCodeScanned;

  delete props["onCameraReady"];
  delete props["onQrCodeScanned"];

  const nativeOnCameraReady = () => {
    onCameraReady?.();
  };

  const nativeOnQrCodeScanned = (event: NativeOnQrCodeScannedEvent) => {
    onQrCodeScanned?.(event.nativeEvent);
  };

  return (
    <NativeView
      {...props}
      onCameraReady={nativeOnCameraReady}
      onQrCodeScanned={nativeOnQrCodeScanned}
    />
  );
}
