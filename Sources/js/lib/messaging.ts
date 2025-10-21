//
//  messaging.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

import { verbose } from "./shims";

export const registerMessageListener = (
  handler: (
    message: unknown,
    sender: browser.runtime.MessageSender,
    sendResponse: (response?: unknown) => void,
  ) => boolean | Promise<unknown> | void,
) => browser.runtime.onMessage.addListener(handler);

export const validObject = (
  response: unknown,
): response is NonNullable<object> => {
  return (
    typeof response === "object" && response !== null && "type" in response
  );
};

export const sendRuntimeMessage = async (
  message: unknown,
): Promise<unknown> => {
  if (verbose) {
    console.debug("Sending runtime message:", message);
  }

  return await browser.runtime.sendMessage(message);
};
