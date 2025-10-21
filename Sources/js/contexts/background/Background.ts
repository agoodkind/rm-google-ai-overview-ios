//
//  Background.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

import {
  registerMessageListener,
  sendRuntimeMessage,
  validObject,
} from "@lib/messaging";
import { isDev, verbose } from "@lib/shims";

type DisplayMode = "hide" | "highlight";

export const broadcastTabMessage = async (message: unknown) => {
  const tabs = await browser.tabs.query({});

  await Promise.all(
    tabs
      .filter((tab) => !!tab.id)
      .map(async (tab) => {
        if (!tab.id) {
          return;
        }

        const response = await sendMessageToTab(tab.id, message);

        if (verbose) {
          console.debug(
            "Notified content scripts that service worker initialized:",
            response,
          );
        }
      }),
  );
};

export const sendMessageToTab = async (tabId: number, message: unknown) => {
  if (verbose) {
    console.debug("Sending message to tab:", { tabId, message });
  }

  return await browser.tabs.sendMessage(tabId, message);
};

export const sendNativeMessage = async (message: unknown) => {
  if (verbose) {
    console.debug("Sending native message:", message);
  }

  // safari ignores  application ID parameter
  // and only sends to the native application that contains
  const result = await browser.runtime.sendNativeMessage(
    "application.id",
    message,
  );
  return result;
};

const fetchDisplayModeFromNative = async (): Promise<DisplayMode> => {
  const result = await sendNativeMessage({
    type: "getDisplayMode",
  });

  return result.displayMode;
};

const relayMessage = async (
  message: unknown,
  sender: browser.runtime.MessageSender,
) => {
  const relayMessage = {
    type: "relayMessage",
    originalMessage: message,
    originalSender: sender,
  };

  await Promise.all([
    sendRuntimeMessage(relayMessage),
    broadcastTabMessage(relayMessage),
  ]);
};

// Listen for messages from content scripts
registerMessageListener((message, sender, sendResponse) => {
  if (isDev) {
    relayMessage(message, sender);
  }

  if (!validObject(message) || !("type" in message)) {
    return;
  }

  switch (message.type) {
    case "ping": {
      // respond to ping from native app to check if extension is enabled
      if (verbose) {
        console.debug("Ping received from native app");
      }

      // gather extension API information
      const manifest = browser.runtime.getManifest();
      const details = {
        version: manifest.version,
        manifestVersion: manifest.manifest_version,
        name: manifest.name,
        extensionId: browser.runtime.id,
        platform: navigator.platform,
        userAgent: navigator.userAgent,
      };

      sendResponse({ type: "pong", details });
      return true;
    }
    case "getDisplayMode":
      // fetch display mode from native app
      fetchDisplayModeFromNative()
        .then((displayMode) => {
          sendResponse({ type: "getDisplayMode", displayMode });
        })
        .catch((error) => {
          sendResponse({ error: error.message });
        });

      return true; // return true to indicate async response
    default:
      return;
  }
});

// Listen for extension installation/enabling
browser.runtime.onInstalled.addListener((details) => {
  if (verbose) {
    console.debug("Extension installed/updated:", details);
  }

  // Notify native app that extension is active
  sendNativeMessage({ type: "serviceWorkerStarted" }).catch((error) => {
    console.error("Failed to notify native app:", error);
  });
});

// Also notify on service worker startup (Safari reopened)
if (verbose) {
  console.debug("Service worker initialized");
}

sendNativeMessage({ type: "serviceWorkerStarted" }).catch((error) => {
  if (verbose) {
    console.error("Failed to notify native app:", error);
  }
});
