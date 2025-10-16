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

if (verbose) {
  console.debug("Service worker initialized");
}

// Notify native app that service worker has started
sendNativeMessage({ type: "serviceWorkerStarted" });
