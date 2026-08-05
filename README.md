# FranFkntastic Dalamud Plugins

Custom Dalamud plugin repository for FranFkntastic plugins.

## Installation

In game:

1. Open `/xlsettings`.
2. Go to `Experimental`.
3. Add this URL under `Custom Plugin Repositories`:

```text
https://raw.githubusercontent.com/FranFkntastic/DalamudPlugins/main/pluginmaster.json
```

4. Save and close settings.
5. Open `/xlplugins`.
6. Search for the plugin you want to install.

## Plugins

- `ComplicatedMarketBoard`
- `MarketMafioso`
- `Quartermaster`
- `DalamudAgentBridge`
- `SapphireAvenueRelay` — Sapphire Avenue Discord Bridge

## Maintainer Notes

`pluginmaster.json` is the public Dalamud repository manifest. Plugin release
zips are hosted in each plugin's own GitHub releases and must use immutable,
versioned release URLs. Pull requests validate manifest structure, unique
internal names, version syntax, and every download URL before merging.
