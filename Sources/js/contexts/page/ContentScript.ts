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

// const DISPLAY_MODE_KEY = "skip-ai-display-mode";
type DisplayMode = "hide" | "highlight";

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

let mainBodyInitialized = false;
let hasRun = false;
let hideCount = 0;
let dupeCount = 0;
let lastStatsPrintTime = 0;
const elements = new WeakSet<HTMLElement>();

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
    .forEach(processSingleElement);
}

function processPeopleAlsoAsk(mainBody: HTMLDivElement) {
  [...mainBody.querySelectorAll("div.related-question-pair")]
    .filter(
      (el) => el.parentElement?.parentElement?.parentElement?.parentElement,
    )
    .map((el) => el.parentElement!.parentElement!.parentElement!.parentElement)
    .filter((el) => el !== null)
    .forEach(processSingleElement);
}

// ai mode inline card has a custom tag: ai-mode-inline-card
function processAICard(mainBody: HTMLDivElement) {
  [...mainBody.getElementsByTagName("ai-mode-inline-card")]
    .map((card) => card.parentElement)
    .filter((el) => el !== null)
    .forEach(processSingleElement);
}

// hide the AI Mode tab in the search navigation
function processAIModeTab() {
  // find all divs with role="tab" or links in the navigation
  const tabs = [
    ...document.querySelectorAll('div[role="tab"]'),
    ...document.querySelectorAll('a[role="tab"]'),
  ];

  tabs
    .filter((tab): tab is HTMLElement => {
      if (tab instanceof HTMLElement) {
        return aiTextPatterns.some((pattern) => pattern.test(tab.innerText));
      }
      return false;
    })
    .forEach(processSingleElement);
}

async function processSingleElement(el: Element) {
  if (!(el instanceof HTMLElement)) {
    return;
  }

  if (elements.has(el)) {
    dupeCount++;
    return;
  }
  VERBOSE5: console.debug("Found new element:", el);

  await hideElement(el);
  await log.debug("processSingleElement", "Found new element:", el);

  elements.add(el);
}

async function hideElement(el: HTMLElement) {
  const mode = await fetchDisplayMode();
  const overlay = document.createElement("div");

  switch (mode) {
    case "highlight":
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
      el.appendChild(overlay);

      break;
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

const observer = new MutationObserver(async () => {
  if (!hasRun) {
    VERBOSE4: console.debug("Initial run");
    hasRun = true;
    log.debug("Observer initial run", "observer");
  }

  const mainBody = document.querySelector("div#main") as HTMLDivElement | null;
  if (mainBody && !mainBodyInitialized) {
    VERBOSE4: console.debug("Main body found");
    mainBodyInitialized = true;
    log.info("Main body found, starting processing", "observer");
  }
  if (!mainBody) {
    return;
  }

  processHeadings(mainBody);
  processPeopleAlsoAsk(mainBody);
  processAICard(mainBody);
  processAIModeTab();

  VERBOSE5: if (Date.now() - lastStatsPrintTime > 500) {
    lastStatsPrintTime = Date.now();
    console.debug("Observer stats:", { hideCount, dupeCount });
    await messenger.sendStats({
      elementsHidden: hideCount,
      duplicatesFound: dupeCount,
    });
  }
});

async function bootstrap() {
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
