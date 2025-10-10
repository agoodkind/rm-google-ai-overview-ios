const patterns = [
  /übersicht mit ki/i, // de
  /ai overview/i, // en
  /prezentare generală generată de ai/i, // ro
  /AI による概要/, // ja
  /Обзор от ИИ/, // ru
  /AI 摘要/, // zh-TW
  /AI-overzicht/i, // nl
  /Vista creada con IA/i, // es
  /Přehled od AI/i, // cz
];

if (process.env.DEV_MODE) {
  const logLabel = '[rm-google-ai-overview-ios]';
  const doSOmethingElse = () => {
    console.log('test');
  };

  // Bind the timestamp object - toString() gets called at log-time
  console.log = console.log.bind(console, logLabel, doSOmethingElse);
  console.warn = console.warn.bind(console, logLabel, doSOmethingElse);
  console.error = console.error.bind(console, logLabel, doSOmethingElse);
  console.debug = console.debug.bind(console, logLabel, doSOmethingElse);

  console.warn('Debug mode is enabled');
  console.warn('Build TS: ', process.env.BUILD_TS);
}

const observer = new MutationObserver(() => {
  // each time there's a mutation in the document see if there's an ai overview to hide
  const mainBody = document.querySelector('div#rcnt') as HTMLDivElement | null;
  if (!mainBody) {
    return;
  }

  const headings = mainBody.querySelectorAll('h1, h2');
  const aiText = [...headings].find((e) => {
    if (e instanceof HTMLElement) {
      return patterns.some((pattern) => pattern.test(e.innerText));
    }
  });

  if (!aiText) {
    return;
  }

  let aiOverview = aiText.parentElement; // google changes oct 9 2025
  if (!aiOverview) {
    aiOverview = aiText.closest('div#rso > div') as HTMLDivElement; // AI overview as a search result
  }
  if (!aiOverview) {
    aiOverview = aiText.closest('div#rcnt > div') as HTMLDivElement; // AI overview above search results
  }

  if (process.env.DEV_MODE) {
    console.debug('AI Overview Element:', aiOverview);
  }

  // Hide AI overview
  if (aiOverview) {
    aiOverview.style.display = 'none';
  }

  // Restore padding after header tabs
  const headerTabs = document.querySelector('div#hdtb-sc > div') as HTMLElement | null;
  if (headerTabs) {
    headerTabs.style.paddingBottom = '12px';
  }

  // For debugging
  if (process.env.DEV_MODE) {
    console.debug('Headings:', headings, [...headings]);
    console.debug('Header tabs:', headerTabs);
  }

  const mainElement = document.querySelector('[role="main"]') as HTMLElement | null;
  if (mainElement) {
    mainElement.style.marginTop = '24px';
  }

  // Remove entries in "People also ask" section if it contains "AI overview"
  const peopleAlsoAskAiOverviews = [
    ...document.querySelectorAll('div.related-question-pair'),
  ].filter((el) => patterns.some((pattern) => pattern.test(el.innerHTML)));

  peopleAlsoAskAiOverviews.forEach((el) => {
    if (el.parentElement && el.parentElement.parentElement) {
      el.parentElement.parentElement.style.display = 'none';
    }
  });
});

observer.observe(document, {
  childList: true,
  subtree: true,
});
