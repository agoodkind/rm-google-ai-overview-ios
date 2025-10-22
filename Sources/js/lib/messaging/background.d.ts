import type { ErrorResponse } from "./common";
import { MessagesToBackgroundPage } from "./constants";
import type { MessageToNativeApp } from "./native";

export type MessageToBackgroundPageType =
  (typeof MessagesToBackgroundPage)[keyof typeof MessagesToBackgroundPage];

export interface ForwardToNativeAppMessage {
  type: typeof MessagesToBackgroundPage.ForwardToNativeApp;
  dataToForward: MessageToNativeApp;
}

export type MessageToBackgroundPage = PingMessage | ForwardToNativeAppMessage;

export type BackgroundMessageResponse<T extends MessageToBackgroundPage> =
  T extends PingMessage
    ? PingResponse | ErrorResponse
    : T extends ForwardToNativeAppMessage
      ? ForwardToNativeAppResponse | ErrorResponse
      : never;
