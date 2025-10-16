import { registerMessageListener, sendRuntimeMessage } from "@/lib/messaging";
import { isDev, isPreview, isProd, verbose } from "@lib/shims";

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

// const DISPLAY_MODE_KEY = "rm-ai-display-mode";
type DisplayMode = "hide" | "highlight";

const fetchDisplayMode = async (): Promise<DisplayMode> => {
  const response = await sendRuntimeMessage({
    type: "getDisplayMode",
  });

  if (verbose) {
    console.debug("Response from service worker fetch:", {
      response,
    });
  }

  if ("displayMode" in response) {
    return response.displayMode;
  }

  throw new Error("Invalid response from service worker");
};

let mainBodyInitialized = false;
let hasRun = false;
let dupeCount = 0;
let hideCount = 0;
let lastStatsPrintTime = 0;
const elements = new WeakSet<HTMLElement>();

const processHeadings = (mainBody: HTMLDivElement) =>
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

const processPeopleAlsoAsk = (mainBody: HTMLDivElement) =>
  [...mainBody.querySelectorAll("div.related-question-pair")]
    .filter(
      (el) => el.parentElement?.parentElement?.parentElement?.parentElement,
    )
    .map((el) => el.parentElement!.parentElement!.parentElement!.parentElement)
    .filter((el) => el !== null)
    .forEach(processSingleElement);

// ai mode inline card has a custom tag: ai-mode-inline-card
const processAICard = (mainBody: HTMLDivElement) =>
  [...mainBody.getElementsByTagName("ai-mode-inline-card")]
    .map((card) => card.parentElement)
    .filter((el) => el !== null)
    .forEach(processSingleElement);

const processSingleElement = async (el: Element) => {
  if (!(el instanceof HTMLElement)) {
    return;
  }

  if (elements.has(el)) {
    dupeCount++;
    return;
  }
  if (verbose) {
    console.debug("Found new element:", el);
  }

  await hideElement(el);

  elements.add(el);
};

const hideElement = async (el: HTMLElement) => {
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
      if (verbose) {
        console.error("Unknown display mode:", mode);
      }
      return;
  }

  hideCount++;
};

const observer = new MutationObserver(async () => {
  if (!hasRun) {
    if (verbose) {
      console.debug("Initial run");
    }
    hasRun = true;
  }

  const mainBody = document.querySelector("div#main") as HTMLDivElement | null;
  if (mainBody && !mainBodyInitialized) {
    if (verbose) {
      console.debug("Main body found");
    }
    mainBodyInitialized = true;
  }
  if (!mainBody) {
    return;
  }

  processHeadings(mainBody);
  processPeopleAlsoAsk(mainBody);
  processAICard(mainBody);

  if (verbose && Date.now() - lastStatsPrintTime > 500) {
    lastStatsPrintTime = Date.now();
    console.debug(
      "Stats:",
      "Duplicates found:",
      dupeCount,
      "Elements hidden:",
      hideCount,
    );
  }
});

const bootStrap = async () => {
  const displayMode = await fetchDisplayMode();
  observer.observe(document, {
    childList: true,
    subtree: true,
  });

  if (verbose) {
    console.debug({ displayMode, isDev, isPreview, isProd });
  }
};

bootStrap().catch((error) => {
  console.error("Error in bootstrap:", error);
});

if (verbose) {
  console.warn("Verbose logging is enabled");
  console.warn("Build env:", process.env.BUILD_ENV);
  console.warn("Build time: ", process.env.BUILD_TS);
  console.warn("Current time: ", new Date().toString());

  if (isDev) {
    registerMessageListener((message) => {
      console.debug("Content script received message:", message);
    });
  }
}
