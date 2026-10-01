# Agent guidance for img-gen

img-gen is a Bun, TypeScript and React desktop app using Electrobun, with a
Windows Explorer context menu and a macOS shell launcher. All source is in this
repo.

## Working here

- Use test-first development for non-trivial changes. If there is no clean test
  seam, extract one and test it before changing behaviour.
- Rerun relevant tests when behaviour, UI copy, layout, persistence or startup
  changes. Update affected test expectations in the same change.
- Before committing, run `bun test`, `bunx tsc --noEmit`, and `bun run build:dev`.
  Smoke-test the app as well. Mock OpenRouter for automated tests so CI needs no
  API keys or paid requests.
- Keep `.env` in this repo root. Never commit keys, generated images or logs.
- GUI launch on Windows goes through `img-gen.vbs` and `wscript.exe`, using window
  style 0 for the app. Do not add a visible console to the GUI launch path.
- If adding `.bat` stubs, use ASCII and PowerShell `-Encoding ASCII`.
- Never put source in `C:\dev\tools`. That directory is for generated stubs and
  large binaries only. Never commit `.exe` or `.dll` files. If adding a dependency
  on binaries there, support `EXEDIR` instead of hardcoding their location.
- `deps.ps1` must remain self-contained, idempotent, and runnable directly from
  any directory. Check dependencies before installing, and print clear results.
  Check system tools with `Get-Command`. Do not auto-download large manually
  installed binaries.
- `install.ps1` runs this repo's `deps.ps1`; `-SkipDeps` skips that step.
- Keep the shared Mike's Tools submenu. Add or remove only the `ImgGen` verb.
  Existing source edits do not need reinstalling, but moving the clone or changing
  installer registrations does.
- Test PowerShell scripts with PowerShell and the Windows launcher through
  `wscript.exe`. A parse check on macOS cannot prove Explorer or WebView2 works.

## Paths and commands

- `src/bun/generation.ts`: testable generation logic and OpenRouter attribution.
- `src/bun/index.ts`: Electrobun window, RPC, temporary images and downloads.
- `src/bun/events.ts`: local HTTP server and the SSE stream the UI listens to.
- `src/ui/`: React UI and annotation tools.
- `tests/`: mocked generation tests and disposable launcher/installer checks.
- `electrobun.config.ts`: app configuration. Keep the existing app identifier
  `com.mikerosoft.img-gen` stable when changing repo ownership or paths.
- `img-gen`: macOS launcher; opens a folder and loads this clone's `.env`.
- `img-gen.vbs`: Windows launcher; opens the folder passed by Explorer.
- `install.sh`: installs a symlink, optionally installs Bun dependencies.
- `install.ps1`, `install-lib.ps1`, `uninstall.ps1`: Windows registration.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
wscript.exe .\img-gen.vbs "C:\path\to\images"
```

```sh
bun test
bunx tsc --noEmit
bun run build:dev
./img-gen /path/to/images
```
