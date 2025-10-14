import { isDev, log } from '@lib/shims';

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
];

let mainBodyInitialized = false;
let hasRun = false;
const elements = new Set<HTMLElement>();

const processHeadings = (mainBody: HTMLDivElement) =>
  [...mainBody.querySelectorAll('h1, h2')]
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
        aiOverview = heading.closest('div#rso > div') as HTMLDivElement; // AI overview as a search result
      }
      if (!aiOverview) {
        aiOverview = heading.closest('div#rcnt > div') as HTMLDivElement; // AI overview above search results
      }
      return aiOverview;
    })
    .forEach(processSingleElement);

const processPeopleAlsoAsk = (mainBody: HTMLDivElement) =>
  [...mainBody.querySelectorAll('div.related-question-pair')]
    .filter(
      (el) => el.parentElement?.parentElement?.parentElement?.parentElement,
    )
    .map((el) => el.parentElement!.parentElement!.parentElement!.parentElement)
    .filter((el) => el !== null)
    .forEach(processSingleElement);

// ai mode inline card has a custom tag: ai-mode-inline-card
const processAICard = (mainBody: HTMLDivElement) =>
  [...mainBody.getElementsByTagName('ai-mode-inline-card')]
    .map((card) => card.parentElement)
    .filter((el) => el !== null)
    .forEach(processSingleElement);

const processSingleElementWithApply = (el: Element) => {
  if (!(el instanceof HTMLElement)) {
    return;
  }

  if (elements.has(el)) {
    return;
  }
  if (isDev) {
    console.debug('Found new element:', el);
  }
  elements.add(el);
};
const processSingleElement = (el: Element) => processSingleElementWithApply(el);

const observer = new MutationObserver(() => {
  if (!hasRun) {
    if (isDev) {
      console.debug('Initial run');
    }
    hasRun = true;
  }

  const mainBody = document.querySelector('div#main') as HTMLDivElement | null;
  if (mainBody && !mainBodyInitialized) {
    if (isDev) {
      console.debug('Main body found');
    }
    mainBodyInitialized = true;
  }
  if (!mainBody) {
    return;
  }

  processHeadings(mainBody);
  processPeopleAlsoAsk(mainBody);
  processAICard(mainBody);

  [...elements].forEach((el) => {
    if (isDev) {
      el.style.outline = '3px solid orange';
      el.style.outlineOffset = '-1px';
      el.style.backgroundColor = 'rgba(255, 165, 0, 0.1)';
    } else {
      el.style.display = 'none';
    }
  });
});

observer.observe(document, {
  childList: true,
  subtree: true,
});

if (isDev) {
  log('warn', () => {
    console.log(
      'Dev mode is enabled - AI overview sections will be highlighted but not removed',
    );
  });
  console.warn('Debug mode is enabled');
  console.warn('Build time: ', process.env.BUILD_TS);
  console.warn('Current time: ', new Date().toString());
}
