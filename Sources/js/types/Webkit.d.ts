//
//  Webkit.d.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

/**
 * Safari WebKit message handler types
 */
export type Platform = "ios" | "mac";

declare global {
  interface Window {
    webkit?: {
      messageHandlers: {
        [x: string]: {
          postMessage: (data: unknown) => void;
        };
      };
    };
  }
}
export global {}
