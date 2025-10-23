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

const allowDomains = [
  "google.com",
  "google.ad",
  "google.ae",
  "google.com.af",
  "google.com.ag",
  "google.al",
  "google.am",
  "google.co.ao",
  "google.com.ar",
  "google.as",
  "google.at",
  "google.com.au",
  "google.az",
  "google.ba",
  "google.com.bd",
  "google.be",
  "google.bf",
  "google.bg",
  "google.com.bh",
  "google.bi",
  "google.bj",
  "google.com.bn",
  "google.com.bo",
  "google.com.br",
  "google.bs",
  "google.bt",
  "google.co.bw",
  "google.by",
  "google.com.bz",
  "google.ca",
  "google.cd",
  "google.cf",
  "google.cg",
  "google.ch",
  "google.ci",
  "google.co.ck",
  "google.cl",
  "google.cm",
  "google.cn",
  "google.com.co",
  "google.co.cr",
  "google.com.cu",
  "google.cv",
  "google.com.cy",
  "google.cz",
  "google.de",
  "google.dj",
  "google.dk",
  "google.dm",
  "google.com.do",
  "google.dz",
  "google.com.ec",
  "google.ee",
  "google.com.eg",
  "google.es",
  "google.com.et",
  "google.fi",
  "google.com.fj",
  "google.fm",
  "google.fr",
  "google.ga",
  "google.ge",
  "google.gg",
  "google.com.gh",
  "google.com.gi",
  "google.gl",
  "google.gm",
  "google.gr",
  "google.com.gt",
  "google.gy",
  "google.com.hk",
  "google.hn",
  "google.hr",
  "google.ht",
  "google.hu",
  "google.co.id",
  "google.ie",
  "google.co.il",
  "google.im",
  "google.co.in",
  "google.iq",
  "google.is",
  "google.it",
  "google.je",
  "google.com.jm",
  "google.jo",
  "google.co.jp",
  "google.co.ke",
  "google.com.kh",
  "google.ki",
  "google.kg",
  "google.co.kr",
  "google.com.kw",
  "google.kz",
  "google.la",
  "google.com.lb",
  "google.li",
  "google.lk",
  "google.co.ls",
  "google.lt",
  "google.lu",
  "google.lv",
  "google.com.ly",
  "google.co.ma",
  "google.md",
  "google.me",
  "google.mg",
  "google.mk",
  "google.ml",
  "google.com.mm",
  "google.mn",
  "google.com.mt",
  "google.mu",
  "google.mv",
  "google.mw",
  "google.com.mx",
  "google.com.my",
  "google.co.mz",
  "google.com.na",
  "google.com.ng",
  "google.com.ni",
  "google.ne",
  "google.nl",
  "google.no",
  "google.com.np",
  "google.nr",
  "google.nu",
  "google.co.nz",
  "google.com.om",
  "google.com.pa",
  "google.com.pe",
  "google.com.pg",
  "google.com.ph",
  "google.com.pk",
  "google.pl",
  "google.pn",
  "google.com.pr",
  "google.ps",
  "google.pt",
  "google.com.py",
  "google.com.qa",
  "google.ro",
  "google.ru",
  "google.rw",
  "google.com.sa",
  "google.com.sb",
  "google.sc",
  "google.se",
  "google.com.sg",
  "google.sh",
  "google.si",
  "google.sk",
  "google.com.sl",
  "google.sn",
  "google.so",
  "google.sm",
  "google.sr",
  "google.st",
  "google.com.sv",
  "google.td",
  "google.tg",
  "google.co.th",
  "google.com.tj",
  "google.tl",
  "google.tm",
  "google.tn",
  "google.to",
  "google.com.tr",
  "google.tt",
  "google.com.tw",
  "google.co.tz",
  "google.com.ua",
  "google.co.ug",
  "google.co.uk",
  "google.com.uy",
  "google.co.uz",
  "google.com.vc",
  "google.co.ve",
  "google.co.vi",
  "google.com.vn",
  "google.vu",
  "google.ws",
  "google.rs",
  "google.co.za",
  "google.co.zm",
  "google.co.zw",
  "google.cat",
];

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
    .slice(0, 1) // only process the first tab
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

      if (isDev) {
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
      }

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
