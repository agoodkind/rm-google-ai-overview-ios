import { useEffect, useState } from 'react';

type Platform = 'ios' | 'mac';
type ExtensionState = 'on' | 'off' | 'unknown';

function App() {
  const [platform, setPlatform] = useState<Platform | null>(null);
  const [state, setState] = useState<ExtensionState>('unknown');
  const [useSettingsInsteadOfPreferences, setUseSettingsInsteadOfPreferences] = useState(false);

  useEffect(() => {
    // Expose show function globally for Swift to call
    window.show = (platformParam: Platform, enabled?: boolean, useSettings?: boolean) => {
      setPlatform(platformParam);

      if (useSettings !== undefined) {
        setUseSettingsInsteadOfPreferences(useSettings);
      }

      if (typeof enabled === 'boolean') {
        setState(enabled ? 'on' : 'off');
      } else {
        setState('unknown');
      }
    };

    return () => {
      delete window.show;
    };
  }, []);

  const getButtonText = () => {
    return useSettingsInsteadOfPreferences
      ? 'Quit and Open Safari Settings…'
      : 'Quit and Open Safari Extensions Preferences…';
  };

  const getStateMessage = () => {
    if (platform === 'ios') {
      return "You can turn on Remove Google AI Overview's Safari extension in Settings.";
    }

    const location = useSettingsInsteadOfPreferences
      ? 'the Extensions section of Safari Settings'
      : 'Safari Extensions preferences';

    switch (state) {
      case 'on':
        return `Remove Google AI Overview's extension is currently on. You can turn it off in ${location}.`;
      case 'off':
        return `Remove Google AI Overview's extension is currently off. You can turn it on in ${location}.`;
      case 'unknown':
        return `You can turn on Remove Google AI Overview's extension in ${location}.`;
    }
  };

  const handleOpenPreferences = () => {
    if (window.webkit?.messageHandlers?.controller) {
      window.webkit.messageHandlers.controller.postMessage('open-preferences');
    }
  };

  if (!platform) {
    return null; // Don't render until show() is called
  }

  return (
    <div className="flex h-screen items-center justify-center flex-col gap-5 mx-10 text-center select-none">
      <img
        src="icon.png"
        width="128"
        height="128"
        alt="Remove Google AI Overview Icon"
        className="pointer-events-none"
      />
      <p className="font-system">{getStateMessage()}</p>
      {platform === 'mac' && (
        <button onClick={handleOpenPreferences} className="text-base cursor-default">
          {getButtonText()}
        </button>
      )}
    </div>
  );
}

export default App;
