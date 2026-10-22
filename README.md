# fuckjunk

A zsh command that frees disk space by deleting regenerable dependency, build and cache directories across all your dev projects.
It covers Node, Angular, Next.js, Nuxt, Turborepo, Vite, Expo, SvelteKit, Python, .NET, Gradle, Android, Flutter and CocoaPods.
It supersedes `fuckbinobj`, which deleted every `bin` and `obj` directory regardless of what was inside.

## Install

Add to `~/.zshrc`:

```zsh
source ~/projects/personal/fuckjunk/fuckjunk.zsh
```

## Usage

```zsh
fuckjunk -n            # dry run: list what would be deleted, with sizes and a total
fuckjunk               # list, then ask before deleting
fuckjunk -y ~/projects # delete without asking
```

The directory defaults to the current one.

## What gets deleted

| Rule | Names | Deleted when |
|---|---|---|
| always | `node_modules` `.angular` `.next` `.nuxt` `.turbo` `.svelte-kit` `.parcel-cache` `.vite` `.expo` `__pycache__` `.pytest_cache` `.mypy_cache` `.ruff_cache` `.tox` `.gradle` `.cxx` `.dart_tool` | always |
| venv | `.venv` `venv` | it contains `pyvenv.cfg` |
| dotnet | `bin` `obj` | it sits next to a `*.csproj`, `*.fsproj`, `*.vbproj` or `*.sqlproj` |
| ignored | `dist` `build` `out` `target` `coverage` `Pods` | git ignores it |

Rules live in `_FUCKJUNK_RULES` at the top of `fuckjunk.zsh`.

## Safety

- A directory that contains git-tracked files is never deleted, whatever its name.
- Generic names are only deleted when git ignores them, so a committed `build` or `dist` is safe, and so is anything outside a git repo.
- A `bin` without a .NET project next to it (`node_modules/.bin`, `.venv/bin`, a scripts folder) is left alone.
- Matched directories are not searched further, and `.git` directories are skipped.

## Before you run it

- Stop dev servers and watchers running from the projects you are cleaning.
- A virtual environment without a `requirements.txt`, `pyproject.toml` or lockfile is the only record of its packages.
  Freeze it first with `pip freeze > requirements-frozen.txt`.
- Afterwards, reinstall before working on a project again (`npm i`, `pnpm i`, `uv sync`, `dotnet restore`).

## Tests

```zsh
zsh test/fuckjunk.test.zsh
```
