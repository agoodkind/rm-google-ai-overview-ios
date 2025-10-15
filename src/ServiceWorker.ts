import { verbose } from "@lib/shims";

type DisplayMode = "hide" | "highlight";

type MessageFromContent = {
  action: "getDisplayMode";
};

type MessageResponse = {
  displayMode: DisplayMode;
};

// Listen for messages from content scripts
// @ts-expect-error - browser is available in Safari extension
browser.runtime.onMessage.addListener(
  (
    message: MessageFromContent,
    _sender: unknown,
    sendResponse: (response: MessageResponse | { error: string }) => void,
  ) => {
    if (verbose) {
      console.debug("Service worker received message:", message);
    }

    if (message.action === "getDisplayMode") {
      // @ts-expect-error - browser is available in Safari extension
      browser.runtime
        .sendNativeMessage("application.id", {
          action: "getDisplayMode",
        })
        .then((response: MessageResponse) => {
          if (verbose) {
            console.debug("Received from native:", response);
          }
          sendResponse(response);
        })
        .catch((error: Error) => {
          console.error("Error communicating with native app:", error);
          sendResponse({ error: error.message });
        });

      // Return true to indicate we'll send a response asynchronously
      return true;
    }

    return false;
  },
);

if (verbose) {
  console.debug("Service worker initialized");
}
