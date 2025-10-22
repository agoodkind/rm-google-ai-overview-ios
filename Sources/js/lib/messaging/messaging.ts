//
//  messaging.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

import type { LogEntry } from "../logging";
import { MessagesToNativeApp } from "./constants";
import type { INativeMessenger, MessageToNativeAppType } from "./native";

export function registerMessageListener(
  handler: (
    message: unknown,
    sender: browser.runtime.MessageSender,
    sendResponse: (response?: unknown) => void,
  ) => boolean | Promise<unknown> | void,
) {
  return browser.runtime.onMessage.addListener(handler);
}

export function validObject(
  response: unknown,
): response is NonNullable<object> {
  return (
    typeof response === "object" && response !== null && "type" in response
  );
}

/**
 * Base messenger class with shared functionality
 */
export abstract class BaseNativeMessenger implements INativeMessenger {
  abstract sendNativeMessage(
    type: MessageToNativeAppType,
    data?: unknown,
  ): Promise<unknown>;

  async getDisplayMode(): Promise<{ displayMode: string }> {
    return this.sendNativeMessage(
      MessagesToNativeApp.GetDisplayMode,
    ) as Promise<{
      displayMode: string;
    }>;
  }

  async sendLog(logData: LogEntry): Promise<{ status: string }> {
    return this.sendNativeMessage(
      MessagesToNativeApp.ExtensionLog,
      logData,
    ) as Promise<{ status: string }>;
  }

  async ping(): Promise<{ type: string; details?: unknown }> {
    return this.sendNativeMessage(MessagesToNativeApp.Ping) as Promise<{
      type: string;
      details?: unknown;
    }>;
  }

  async sendStats(statsData: {
    elementsHidden: number;
    duplicatesFound: number;
  }): Promise<{ status: string }> {
    return this.sendNativeMessage(
      MessagesToNativeApp.ExtensionStats,
      statsData,
    ) as Promise<{
      status: string;
    }>;
  }
}
