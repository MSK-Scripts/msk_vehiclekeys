<img width="1920" height="1080" alt="msk_vehiclekeys-banner" src="https://github.com/user-attachments/assets/8a3f072c-5c12-43b7-ad9e-6942b6ea8d0f" />

<div align="center">

[![Discord](https://img.shields.io/badge/Discord-MSK%20Scripts-5865F2?logo=discord&logoColor=white)](https://discord.gg/5hHSBRHvJE)
[![Documentation](https://img.shields.io/badge/Docs-docu.msk--scripts.de-00E676)](https://docu.msk-scripts.de/docs/msk_vehiclekeys/)
[![Version](https://img.shields.io/badge/version-3.4.1-blue)](https://github.com/MSK-Scripts/msk_vehiclekeys/releases)
[![License](https://img.shields.io/badge/license-LGPL--3.0-green)](LICENSE)

</div>

Vehicle keys as items for ESX and QBCore, with lock and unlock, a key menu, job vehicles and an in-game admin dashboard.

Every vehicle has its own key item, with primary, secondary and temporary keys. Keys can be given to other players, and a locksmith exchanges the locks, which removes everyone else's key. Players with a matching job can lock and unlock job vehicles. ox_target and msk_enginetoggle are supported when installed.

MSK VehicleKeys used to be a paid script. It is free and open source since November 2026.

## Quick start

Requires [msk_core](https://github.com/MSK-Scripts/msk_core) 4.1.0+, [ox_lib](https://github.com/overextended/ox_lib) and [oxmysql](https://github.com/overextended/oxmysql). Download the latest [release](https://github.com/MSK-Scripts/msk_vehiclekeys/releases), put `msk_vehiclekeys` into your `resources` folder and start it after its dependencies:

```ini
ensure oxmysql
ensure ox_lib
ensure msk_core
ensure msk_vehiclekeys
```

## Documentation

| Topic | Link |
|---|---|
| Installation | [docu.msk-scripts.de/docs/msk_vehiclekeys/guides/installation](https://docu.msk-scripts.de/docs/msk_vehiclekeys/guides/installation) |
| Configuration | [docu.msk-scripts.de/docs/msk_vehiclekeys/config](https://docu.msk-scripts.de/docs/msk_vehiclekeys/config) |
| Integrations | [docu.msk-scripts.de/docs/msk_vehiclekeys/guides/integrations](https://docu.msk-scripts.de/docs/msk_vehiclekeys/guides/integrations) |
| Changelog | [CHANGELOGS.md](CHANGELOGS.md) |

## Help and contributing

Ask in the public support channel on [Discord](https://discord.gg/5hHSBRHvJE) or open an issue. [GitHub Sponsors](https://github.com/sponsors/MSK-Scripts) get ticket support. Pull requests are welcome.

## License

[LGPL-3.0](LICENSE), see also [GPL-3.0.txt](GPL-3.0.txt).
