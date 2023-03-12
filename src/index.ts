import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to ReactNativeQrCodeScanner.web.ts
// and on native platforms to ReactNativeQrCodeScanner.ts
import ReactNativeQrCodeScannerModule from './ReactNativeQrCodeScannerModule';
import ReactNativeQrCodeScannerView from './ReactNativeQrCodeScannerView';
import { ChangeEventPayload, ReactNativeQrCodeScannerViewProps } from './ReactNativeQrCodeScanner.types';

// Get the native constant value.
export const PI = ReactNativeQrCodeScannerModule.PI;

export function hello(): string {
  return ReactNativeQrCodeScannerModule.hello();
}

export async function setValueAsync(value: string) {
  return await ReactNativeQrCodeScannerModule.setValueAsync(value);
}

const emitter = new EventEmitter(ReactNativeQrCodeScannerModule ?? NativeModulesProxy.ReactNativeQrCodeScanner);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { ReactNativeQrCodeScannerView, ReactNativeQrCodeScannerViewProps, ChangeEventPayload };
