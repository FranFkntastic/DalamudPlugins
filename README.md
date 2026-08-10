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

To publish a plugin update, run the `Publish Plugin to PluginMaster` workflow
and provide its `InternalName`, published stable release tag, and exact ZIP
asset name. The workflow verifies the release, updates the manifest, validates
every download, and opens a ready pull request. Merging that pull request is
the explicit publication step. If a repository uses a tag that is not already
four-part numeric, provide the manifest assembly version separately.
