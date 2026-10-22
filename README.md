# fuckjunk

Free up disk space by deleting the dependency, build and cache folders your dev projects can regenerate.

```console
$ fuckjunk -n ~/projects
  13421.2 MB  ./shop/frontend/.angular
   2694.7 MB  ./dashboard/.turbo
   1675.2 MB  ./chatbot/.venv
    916.1 MB  ./landing/node_modules
  ...

Total: 44.21 GB in 233 dirs
```

## Install

Needs zsh and git.

```zsh
git clone https://github.com/todor-jovanovski/fuckjunk.git ~/.fuckjunk
echo 'source ~/.fuckjunk/fuckjunk.zsh' >> ~/.zshrc
source ~/.zshrc
```

## Usage

```zsh
fuckjunk -n   # preview what would be deleted, biggest first
fuckjunk      # show the same list, then ask before deleting
fuckjunk -y   # delete without asking
```

It cleans the current folder, or the one you pass: `fuckjunk -n ~/projects`.
Always preview first.

## What it deletes

| Stack | Folders |
|---|---|
| JavaScript | `node_modules` `.next` `.nuxt` `.angular` `.turbo` `.vite` `.svelte-kit` `.parcel-cache` `.expo` |
| Python | `.venv` `venv` `__pycache__` `.pytest_cache` `.mypy_cache` `.ruff_cache` `.tox` |
| .NET | `bin` `obj` |
| Android and Flutter | `.gradle` `.cxx` `.dart_tool` |
| Build output and iOS | `dist` `build` `out` `target` `coverage` `Pods` |

## What it won't touch

A folder is only deleted when it is clearly regenerable:

- `.venv` and `venv` only if they are real virtual environments (they contain `pyvenv.cfg`).
- `bin` and `obj` only next to a .NET project file (`.csproj`, `.fsproj`, `.vbproj`, `.sqlproj`).
- `dist`, `build`, `out`, `target`, `coverage` and `Pods` only if git ignores them.
- Never a folder that contains files committed to git.

## Before and after

- Stop dev servers running from the folders you are cleaning.
- If a Python venv has no `requirements.txt`, `pyproject.toml` or lockfile, save its packages first: `.venv/bin/pip freeze > requirements.txt`.
- Afterwards, reinstall before working on a project again: `npm i`, `pnpm i`, `uv sync`, `dotnet restore` and so on.

## Customize

Add or change folder names in `_FUCKJUNK_RULES` at the top of `fuckjunk.zsh`.

## Test

```zsh
zsh test/fuckjunk.test.zsh
```
