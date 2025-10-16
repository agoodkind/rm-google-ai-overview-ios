import { NATIVE_MESSAGING_ID } from "@lib/constants";
import { verbose } from "@lib/shims";

type DisplayMode = "hide" | "highlight";

type MessageFromContent = {
  action: "getDisplayMode";
};

const validMessage = <T extends MessageFromContent>(
  message: unknown,
): message is T => {
  return typeof message === "object" && message !== null && "action" in message;
};

const fetchDisplayModeFromNative = async (): Promise<DisplayMode> => {
  const result = await browser.runtime.sendNativeMessage(NATIVE_MESSAGING_ID, {
    action: "getDisplayMode",
  });

  return result.displayMode;
};

// Listen for messages from content scripts
browser.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (verbose) {
    console.debug("Service worker received message:", message);
  }

  // Type guard to check if message is MessageFromContent
  if (validMessage<MessageFromContent>(message)) {
    switch (message.action) {
      case "getDisplayMode":
        // fetch display mode from native app
        fetchDisplayModeFromNative().then((displayMode) => {
          if (verbose) {
            console.debug("Fetched display mode from native app:", displayMode);
          }
          sendResponse({ displayMode });
        });

        return true; // return true to indicate async response
      default:
        if (verbose) {
          console.debug("Unknown action:", message.action);
        }
        return;
    }
  } else {
    throw new Error("Invalid message format");
  }
});

if (verbose) {
  console.debug("Service worker initialized");
}
browser.runtime
  .sendMessage({
    action: "serviceWorkerInitialized",
  })
  .then((response) => {
    if (verbose) {
      console.debug(
        "Notified content scripts that service worker initialized:",
        response,
      );
    }
  })
  .catch((error) => {
    console.error(
      "Error notifying content scripts that service worker initialized:",
      error,
    );
  });

// Notify native app that service worker has started
browser.runtime
  .sendNativeMessage(NATIVE_MESSAGING_ID, {
    action: "serviceWorkerStarted",
  })
  .then((response) => {
    if (verbose) {
      console.debug(
        "Notified native app that service worker started:",
        response,
      );
    }
  })
  .catch((error) => {
    console.error(
      "Error notifying native app that service worker started:",
      error,
    );
  });
