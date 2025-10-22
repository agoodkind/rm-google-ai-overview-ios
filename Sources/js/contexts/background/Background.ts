//
//  Background.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

import type { MessageToBackgroundPage } from "@/lib/messaging/background";
import {
  MessagesToBackgroundPage,
  MessagesToNativeApp,
} from "@/lib/messaging/constants";
import {
  BaseNativeMessenger,
  registerMessageListener,
  validObject,
} from "@/lib/messaging/messaging";
import type { MessageToNativeAppType } from "@/lib/messaging/native";
import { ExtensionLogger } from "@lib/logging";
import { bindConsole } from "@lib/shims";

bindConsole();

/**
 * Messenger for background script to native app communication
 */
export class BackgroundNativeMessenger extends BaseNativeMessenger {
  async sendNativeMessage(
    type: MessageToNativeAppType,
    data?: unknown,
  ): Promise<unknown> {
    const message: { type: MessageToNativeAppType; data?: unknown } = { type };

    if (data) {
      message.data = data;
    }
    VERBOSE5: console.debug("Sending native message:", message);

    const response = await chrome.runtime.sendNativeMessage("", message);
    if (response) {
      VERBOSE5: console.debug("Received native response:", response);
    }

    return response;
  }
}

const nativeMessenger = new BackgroundNativeMessenger();
const log = ExtensionLogger.for("background", nativeMessenger);

export async function broadcastTabMessage(message: unknown) {
  const tabs = await browser.tabs.query({});

  await Promise.all(
    tabs
      .filter((tab) => !!tab.id)
      .map(async (tab) => {
        if (!tab.id) {
          return;
        }

        const response = await sendMessageToTab(tab.id, message);

        VERBOSE4: console.debug(
          "Notified content scripts that service worker initialized:",
          response,
        );
      }),
  );
}

export async function sendMessageToTab(tabId: number, message: unknown) {
  VERBOSE5: console.debug("Sending message to tab:", { tabId, message });

  return await chrome.tabs.sendMessage(tabId, message);
}

/**
 * Handle messages from content scripts and other extension contexts
 */
function handleMessages(
  message: unknown,
  sender: browser.runtime.MessageSender,
  sendResponse: (response?: unknown) => void,
): boolean | void {
  if (!validObject(message)) {
    VERBOSE5: console.debug("Invalid message object received:", message);
    return;
  } else {
    VERBOSE5: console.debug("Received message in background:", message, sender);
  }

  const msg = message as MessageToBackgroundPage;
  const { type } = msg;

  switch (type) {
    case MessagesToBackgroundPage.Ping: {
      // Respond to ping from native app to check if extension is enabled
      VERBOSE4: console.debug("Ping received");
      log.debug("Ping received", "handleMessages");

      // Gather extension API information
      const manifest = chrome.runtime.getManifest();
      const details = {
        version: manifest.version,
        manifestVersion: manifest.manifest_version,
        name: manifest.name,
        extensionId: chrome.runtime.id,
        platform: navigator.platform,
        userAgent: navigator.userAgent,
      };

      sendResponse({ type: "pong", details });
      return;
    }

    case MessagesToBackgroundPage.ForwardToNativeApp: {
      nativeMessenger
        .sendNativeMessage(msg.dataToForward.type, msg.dataToForward.data)
        .then((result) => sendResponse(result));

      return true;
    }
  }
}

nativeMessenger
  .sendNativeMessage(MessagesToNativeApp.ServiceWorkerStarted)
  .catch((error) => {
    VERBOSE4: console.error("Failed to notify native app:", error);
    log.error("onInstalled", "Failed to notify native app:", { error });
  });

// Ping native app to register background script activity
setTimeout(async () => {
  try {
    const result = await nativeMessenger.ping();
    VERBOSE4: console.debug("Ping result:", result);
  } catch (error) {
    VERBOSE4: console.error("Failed to ping native app:", error);
    await log.error("init", "Failed to ping native app:", { error });
  }
}, 1000);

// Register message listener
registerMessageListener(handleMessages);
