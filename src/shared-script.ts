export function show(
  platform: string,
  enabled: boolean | undefined,
  useSettingsInsteadOfPreferences: boolean,
) {
  document.body.classList.add(`platform-${platform}`);
  const macOn = document.getElementsByClassName('platform-mac state-on')[0] as HTMLElement;
  const macOff = document.getElementsByClassName('platform-mac state-off')[0] as HTMLElement;
  const macUnknown = document.getElementsByClassName(
    'platform-mac state-unknown',
  )[0] as HTMLElement;
  const macOpenPreferences = document.getElementsByClassName(
    'platform-mac open-preferences',
  )[0] as HTMLElement;
  if (useSettingsInsteadOfPreferences) {
    macOn.innerText =
      'rm-google-ai-overview’s extension is currently on. You can turn it off in the Extensions section of Safari Settings.';
    macOff.innerText =
      'rm-google-ai-overview’s extension is currently off. You can turn it on in the Extensions section of Safari Settings.';
    macUnknown.innerText =
      'You can turn on rm-google-ai-overview’s extension in the Extensions section of Safari Settings.';
    macOpenPreferences.innerText = 'Quit and Open Safari Settings…';
  }

  if (typeof enabled === 'boolean') {
    document.body.classList.toggle(`state-on`, enabled);
    document.body.classList.toggle(`state-off`, !enabled);
  } else {
    document.body.classList.remove(`state-on`);
    document.body.classList.remove(`state-off`);
  }
}

function openPreferences() {
  webkit.messageHandlers.controller.postMessage('open-preferences');
}

document?.querySelector('button.open-preferences')?.addEventListener('click', openPreferences);
