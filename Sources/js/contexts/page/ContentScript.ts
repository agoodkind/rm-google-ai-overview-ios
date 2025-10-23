//
//  ContentScript.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

import {
  DEFAULT_DISPLAY_MODE,
  MessagesToBackgroundPage,
} from "@/lib/messaging/constants";
import {
  BaseNativeMessenger,
  registerMessageListener,
} from "@/lib/messaging/messaging";
import type { MessageToNativeAppType } from "@/lib/messaging/native";
import { ExtensionLogger } from "@lib/logging";
import { bindConsole, isDev, isPreview, isProd } from "@lib/shims";

bindConsole();
/**
 * Messenger for content script to background script communication
 */
export class ContentScriptNativeMessenger extends BaseNativeMessenger {
  async sendNativeMessage(
    type: MessageToNativeAppType,
    data?: unknown,
  ): Promise<unknown> {
    const message: {
      type: MessageToNativeAppType;
      data?: unknown;
    } = { type };

    if (data) {
      message.data = data;
    }

    VERBOSE5: console.debug(
      "Forwarding native message to background:",
      message,
    );

    const response = await chrome.runtime.sendMessage({
      type: MessagesToBackgroundPage.ForwardToNativeApp,
      dataToForward: {
        type: message.type,
        data: message.data,
      },
    });

    VERBOSE5: if (response) {
      console.debug("Received native response via background:", response);
    }

    return response;
  }
}

const log = ExtensionLogger.for("content", new ContentScriptNativeMessenger());

const aiTextPatterns = [
  // regex patterns to match "AI overview" in various languages
  /übersicht mit ki/i, // de
  /ai overview/i, // en
  /prezentare generală generată de ai/i, // ro
  /AI による概要/, // ja
  /Обзор от ИИ/, // ru
  /AI 摘要/, // zh-TW
  /AI-overzicht/i, // nl
  /Vista creada con IA/i, // es
  /Přehled od AI/i, // cz
  /Aperçu généré par l'IA/i, // fr

  // patterns for "AI Mode" since Google sometimes uses that instead
  /ki-modus/i, // de
  /AI mode/i, // en
  /modul AI/i, // ro
  /AI モード/, // ja
  /Режим ИИ/, // ru
  /AI 模式/, // zh-TW
  /AI-modus/i, // nl
  /Modo IA/i, // es
  /Režim AI/i, // cz
  /Mode IA/i, // fr

  // patterns for "People also ask"
  /Le persone chiedono anche/i, // it
  /Las personas también preguntan/i, // es
  /Les gens demandent aussi/i, // fr
  /Andere gebruikers fragen auch/i, // de
  /Alte persoane întreabă și/i, // ro
  /人々も尋ねる/i, // ja
  /Другие люди также спрашивают/i, // ru
  /其他人也在问/i, // zh-TW
  /Mensen vragen ook/i, // nl
  /Lidé se také ptají/i, // cz
  /People also ask/i, // en
];

type DisplayMode = "hide" | "highlight";
let mainBodyInitialized = false;
let hasRun = false;
let hideCount = 0;
let dupeCount = 0;
let lastRun = 0;
const elements = new WeakSet<HTMLElement>();

let displayModeCache: DisplayMode | null = null;
const messenger = new ContentScriptNativeMessenger();

async function fetchDisplayMode() {
  if (displayModeCache) {
    return displayModeCache;
  }

  try {
    const response = await messenger.getDisplayMode();
    VERBOSE5: console.debug("Response from background:", { response });
    await log.debug("fetchDisplayMode", "Response from background:", response);

    if (response && "displayMode" in response) {
      displayModeCache = response.displayMode as DisplayMode;
      return displayModeCache;
    }
  } catch (error) {
    console.error("Failed to get display mode:", error);
    await log.error("fetchDisplayMode", "Failed to get display mode:", {
      error,
    });
  }

  return DEFAULT_DISPLAY_MODE;
}

function processHeadings(mainBody: HTMLDivElement) {
  [...mainBody.querySelectorAll("h1, h2")]
    .filter((e): e is HTMLElement => {
      if (e instanceof HTMLElement) {
        return aiTextPatterns.some((pattern) => pattern.test(e.innerText));
      } else {
        return false;
      }
    })
    .map((heading) => {
      let aiOverview = heading.parentElement; // google changes oct 9 2025
      if (!aiOverview) {
        aiOverview = heading.closest("div#rso > div") as HTMLDivElement; // AI overview as a search result
      }
      if (!aiOverview) {
        aiOverview = heading.closest("div#rcnt > div") as HTMLDivElement; // AI overview above search results
      }
      return aiOverview;
    })
    .forEach((heading) =>
      processSingleElement(
        heading,
        `heading ${heading.outerHTML.slice(0, 200)}...`,
      ),
    );
}

function processPeopleAlsoAsk(mainBody: HTMLDivElement) {
  [...mainBody.querySelectorAll("div.related-question-pair")]
    .filter(
      (el) => el.parentElement?.parentElement?.parentElement?.parentElement,
    )
    .map((el) => el.parentElement!.parentElement!.parentElement!.parentElement)
    .filter((el) => el !== null)
    .forEach((el) =>
      processSingleElement(
        el,
        `people also ask ${el.outerHTML.slice(0, 200)}...`,
      ),
    );
}

// ai mode inline card has a custom tag: ai-mode-inline-card
function processAICard(mainBody: HTMLDivElement) {
  [...mainBody.getElementsByTagName("ai-mode-inline-card")]
    .map((card) => card.parentElement)
    .filter((el) => el !== null)
    .forEach((card) =>
      processSingleElement(card, `ai card ${card.outerHTML.slice(0, 200)}...`),
    );
}

// hide the AI Mode tab in the search navigation
function processAIModeTab(mainBody: HTMLDivElement) {
  const tabs = [...mainBody.querySelectorAll('div[role="listitem"]')];

  console.log("ASDASDS", tabs);
  tabs
    .filter((tab): tab is HTMLElement => {
      if (tab instanceof HTMLElement) {
        return aiTextPatterns.some((pattern) => pattern.test(tab.innerText));
      }
      return false;
    })
    .forEach((tab) =>
      processSingleElement(
        tab,
        `ai mode tab ${tab.outerHTML.slice(0, 200)}...`,
      ),
    );
}

async function processSingleElement(el: Element, reason: string) {
  if (!(el instanceof HTMLElement)) {
    return;
  }

  if (elements.has(el)) {
    dupeCount++;
    return;
  }

  VERBOSE5: console.debug("Found new element:", el);

  await hideElement(el, reason);
  await log.debug("processSingleElement", "Found new element:", el);

  elements.add(el);
}

async function hideElement(el: HTMLElement, reason: string) {
  const mode = await fetchDisplayMode();
  const overlay = document.createElement("div");

  switch (mode) {
    case "highlight": {
      el.style.outline = "3px solid orange";
      el.style.outlineOffset = "-1px";
      el.style.backgroundColor = "rgba(255, 165, 0, 0.1)";
      el.style.position = "relative";
      el.style.display = "";

      overlay.style.position = "absolute";
      overlay.style.top = "0";
      overlay.style.left = "0";
      overlay.style.width = "100%";
      overlay.style.height = "100%";
      overlay.style.backgroundColor = "rgba(255, 165, 0, 0.15)";
      overlay.style.pointerEvents = "none";
      overlay.style.zIndex = "1";

      // Add a tiny text box in the top-right corner of the overlay
      const textbox = document.createElement("div");
      textbox.textContent = reason;
      textbox.style.position = "absolute";
      textbox.style.top = "4px";
      textbox.style.right = "6px";
      textbox.style.background = "rgba(255,255,255,0.95)";
      textbox.style.color = "black";
      textbox.style.fontSize = "10px";
      textbox.style.fontFamily = "monospace";
      textbox.style.padding = "8px";
      textbox.style.borderRadius = "3px";
      textbox.style.zIndex = "50";
      textbox.style.pointerEvents = "none";
      overlay.appendChild(textbox);

      el.appendChild(overlay);

      break;
    }
    case "hide":
      el.style.display = "none";
      break;
    default:
      VERBOSE3: console.error("Unknown display mode:", mode);
      await log.error("hideElement", "Unknown display mode:", { mode });
      return;
  }

  hideCount++;
}

function createObserver() {
  return new MutationObserver(async () => {
    if (!hasRun) {
      VERBOSE4: console.debug("Initial run");
      hasRun = true;
      log.debug("Observer initial run", "observer");
    }

    const mainBody = document.querySelector(
      "div#main",
    ) as HTMLDivElement | null;

    if (mainBody && !mainBodyInitialized) {
      VERBOSE4: console.debug("Main body found");
      mainBodyInitialized = true;
      log.info("observer", "Main body found, starting processing");
    }

    if (!mainBody) {
      return;
    }

    if (!lastRun || Date.now() - lastRun > 200) {
      processHeadings(mainBody);
      processPeopleAlsoAsk(mainBody);
      processAICard(mainBody);
      processAIModeTab(mainBody);

      lastRun = Date.now();

      VERBOSE5: console.debug("Observer run:", { hideCount, dupeCount });
      await messenger.sendStats({
        elementsHidden: hideCount,
        duplicatesFound: dupeCount,
      });
    }
  });
}

async function bootstrap() {
  const observer = createObserver();
  const displayMode = await fetchDisplayMode();
  VERBOSE4: console.debug({ displayMode, isDev, isPreview, isProd });
  await log.info("bootstrap", "Content script initialized, mode:", displayMode);

  // Ping native app to register content script activity
  messenger.ping().catch(async (error) => {
    VERBOSE4: console.error("Failed to ping native app:", error);
    await log.error("bootstrap", "Failed to ping native app:", { error });
  });

  observer.observe(document, {
    childList: true,
    subtree: true,
  });
}

bootstrap().catch(async (error) => {
  VERBOSE4: console.error("Error in bootstrap:", error);
  await log.error("bootstrap", "Bootstrap failed:", { error });
});

VERBOSE3: {
  console.info("Content script loaded");
  console.info("Build:", process.env.BUILD_TS);
  console.info("Config:", process.env.CONFIGURATION);
}

if (isDev) {
  registerMessageListener(async (message) => {
    log.debug("messageListener", "Content script received message:", message);
    VERBOSE5: console.debug("Content script received message:", message);
  });
}
