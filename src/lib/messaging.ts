import { verbose } from "./shims";

export type RuntimeMessageRequest =
  | {
      type: "getDisplayMode";
    }
  | {
      type: "relayMessage";
      originalMessage: unknown;
      originalSender: browser.runtime.MessageSender;
    }
  | {
      type: "serviceWorkerInitialized";
    };

export type RuntimeMessageResponse = {
  type: "getDisplayMode";
  displayMode: "hide" | "highlight";
};

export type RuntimeMessageResponseError = {
  error: string;
  details?: unknown;
};

export const registerMessageListener = (
  handler: (
    message: RuntimeMessageRequest,
    sender: browser.runtime.MessageSender,
    sendResponse: (
      response?: RuntimeMessageResponse | RuntimeMessageResponseError,
    ) => void,
  ) => boolean | Promise<unknown> | void,
) => browser.runtime.onMessage.addListener(handler);

export const validMessage = (
  message: unknown,
): message is RuntimeMessageRequest => {
  return typeof message === "object" && message !== null && "action" in message;
};

export const sendRuntimeMessage = async (
  message: RuntimeMessageRequest,
): Promise<RuntimeMessageResponse> => {
  if (typeof browser === "undefined") {
    throw new Error("browser is not available");
  }

  if (!browser.runtime?.sendMessage) {
    throw new Error("browser.runtime.sendMessage is not available");
  }

  if (verbose) {
    console.debug("Sending runtime message:", message);
  }

  const response = await browser.runtime.sendMessage(message);

  if (typeof response === "object") {
    if ("error" in response) {
      throw new Error(response.error);
    }
    return response;
  } else {
    throw new Error("Invalid response from runtime message");
  }
};
