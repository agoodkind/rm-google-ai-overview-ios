/**
 * Safari WebKit message handler types
 */
interface WebKitMessageHandler {
  postMessage(message: string): void;
}

interface WebKitMessageHandlers {
  controller: WebKitMessageHandler;
}

interface WebKit {
  messageHandlers: WebKitMessageHandlers;
}

declare const webkit: WebKit;
