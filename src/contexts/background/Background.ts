import {
  registerMessageListener,
  sendRuntimeMessage,
  validMessage,
  type RuntimeMessageRequest,
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
  return await browser.runtime.sendNativeMessage("application.id", message);
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
  } satisfies RuntimeMessageRequest;

  await Promise.all([
    sendRuntimeMessage(relayMessage),
    broadcastTabMessage(relayMessage),
  ]);
};

// Listen for messages from content scripts
registerMessageListener((message, sender, sendResponse) => {
  if (isDev) {
    console.debug("Service worker received message:", message);
    relayMessage(message, sender);
  }

  // Type guard to check if message is MessageFromContent
  if (!validMessage(message)) {
    console.error("Invalid message received in service worker:", message);
    return;
  }

  switch (message.type) {
    case "getDisplayMode":
      // fetch display mode from native app
      fetchDisplayModeFromNative()
        .then((displayMode) => {
          if (verbose) {
            console.debug("Fetched display mode from native app:", displayMode);
          }
          sendResponse({ type: "getDisplayMode", displayMode });
        })
        .catch((error) => {
          console.error("Error fetching display mode from native app:", error);
          sendResponse({ error: error.message });
        });

      return true; // return true to indicate async response
    default:
      if (verbose) {
        console.debug("Unknown type:", message.type);
      }
      return;
  }
});

if (verbose) {
  console.debug("Service worker initialized");
}

// Notify native app that service worker has started
sendNativeMessage({ type: "serviceWorkerStarted" });
