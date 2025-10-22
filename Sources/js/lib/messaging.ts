//
//  messaging.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

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

export async function sendRuntimeMessage(message: unknown): Promise<unknown> {
  VERBOSE5: console.debug("Sending runtime message:", message);

  return await browser.runtime.sendMessage(message);
}
