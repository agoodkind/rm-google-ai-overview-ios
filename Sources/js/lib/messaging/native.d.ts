//
//  message-types.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  Type-safe message definitions for extension communication

import type { LogEntry } from "../logging";
import type { ErrorResponse, PingMessage, PingResponse } from "./common";
import { MessagesToNativeApp } from "./constants";

export type MessageToNativeAppType =
  (typeof MessagesToNativeApp)[keyof typeof MessagesToNativeApp];

export interface INativeMessenger {
  sendNativeMessage(
    type: MessageToNativeAppType,
    data?: unknown,
  ): Promise<unknown>;
  getDisplayMode(): Promise<{ displayMode: string }>;
  sendLog(logData: LogEntry): Promise<{ status: string }>;
  ping(): Promise<{ type: string; details?: unknown }>;
  sendStats(statsData: {
    elementsHidden: number;
    duplicatesFound: number;
  }): Promise<{ status: string }>;
}

/******************************************************************************
 * Get display mode ************************************************************
 ******************************************************************************/
export interface GetDisplayModeMessage {
  type: typeof MessagesToNativeApp.GetDisplayMode;
}

export interface GetDisplayModeResponse {
  displayMode: string;
}

/******************************************************************************
 * Send log entry **************************************************************
 ******************************************************************************/
export interface ExtensionLogMessage {
  type: typeof MessagesToNativeApp.ExtensionLog;
  data: LogEntry;
}

export interface ExtensionLogResponse {
  status: string;
}

/******************************************************************************
 * Stats **********************************************************************
 ******************************************************************************/
export interface StatsData {
  elementsHidden: number;
  duplicatesFound: number;
}

export interface StatsMessage {
  type: typeof MessagesToNativeApp.ExtensionStats;
  data: StatsData;
}

export interface StatsResponse {
  status: string;
}

/**
 * Union of all possible messages to background
 */
export type MessageToNativeApp =
  | GetDisplayModeMessage
  | ExtensionLogMessage
  | StatsMessage
  | PingMessage;

/**
 * Map message types to their responses
 */
export type NativeMessageResponse<T extends MessageToNativeApp> =
  T extends GetDisplayModeMessage
    ? GetDisplayModeResponse | ErrorResponse
    : T extends ExtensionLogMessage
      ? ExtensionLogResponse | ErrorResponse
      : T extends PingMessage
        ? PingResponse
        : never;
