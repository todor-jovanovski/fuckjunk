# fuckjunk - delete regenerable dependency, build and cache directories.
# Source this file from ~/.zshrc, then run: fuckjunk [-n] [-y] [dir]

# Directory name -> rule that decides whether a directory with that name is junk.
#   always   pure dependency or cache directory
#   venv     Python virtual environment (must contain pyvenv.cfg)
#   dotnet   .NET output (must sit next to a .NET project file)
#   ignored  generic name (must be git-ignored)
typeset -gA _FUCKJUNK_RULES=(
  node_modules  always
  .angular      always
  .next         always
  .nuxt         always
  .turbo        always
  .svelte-kit   always
  .parcel-cache always
  .vite         always
  .expo         always
  __pycache__   always
  .pytest_cache always
  .mypy_cache   always
  .ruff_cache   always
  .tox          always
  .gradle       always
  .cxx          always
  .dart_tool    always
  .venv         venv
  venv          venv
  bin           dotnet
  obj           dotnet
  dist          ignored
  build         ignored
  out           ignored
  target        ignored
  coverage      ignored
  Pods          ignored
)

_fuckjunk_beside_dotnet_project() {
  emulate -L zsh
  local -a projects=($1/*.(csproj|fsproj|vbproj|sqlproj)(N))
  (( $#projects ))
}

_fuckjunk_has_tracked_files() {
  [[ -n $(git -C $1 ls-files 2>/dev/null | head -c1) ]]
}

_fuckjunk_matches_rule() {
  emulate -L zsh
  local dir=$1
  case ${_FUCKJUNK_RULES[${dir:t}]} in
    always)  return 0 ;;
    venv)    [[ -f $dir/pyvenv.cfg ]] ;;
    dotnet)  _fuckjunk_beside_dotnet_project ${dir:h} ;;
    ignored) git -C ${dir:h} check-ignore -q -- ${dir:t} 2>/dev/null ;;
    *)       return 1 ;;
  esac
}

_fuckjunk_is_junk() {
  _fuckjunk_matches_rule $1 && ! _fuckjunk_has_tracked_files $1
}

_fuckjunk_report() {
  du -sk -- "$@" 2>/dev/null | sort -rn | awk '
    { size = $1; sub(/^[0-9]+\t/, ""); total += size; printf "%9.1f MB  %s\n", size / 1024, $0 }
    END { printf "\nTotal: %.2f GB in %d dirs\n", total / 1048576, NR }'
}

fuckjunk() {
  emulate -L zsh
  local usage="usage: fuckjunk [-n] [-y] [dir]   -n dry run, -y skip confirmation"
  local dry_run=0 assume_yes=0 opt OPTIND
  while getopts "nyh" opt; do
    case $opt in
      n) dry_run=1 ;;
      y) assume_yes=1 ;;
      h) print -r -- $usage; return 0 ;;
      *) print -ru2 -- $usage; return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  local root=${1:-.}
  [[ -d $root ]] || { print -u2 "fuckjunk: not a directory: $root"; return 1; }

  local -a name_tests junk
  local name dir
  for name in ${(k)_FUCKJUNK_RULES}; do name_tests+=(-o -name $name); done
  name_tests=(${name_tests[2,-1]})

  while IFS= read -r -d '' dir; do
    _fuckjunk_is_junk $dir && junk+=($dir)
  done < <(find $root -name .git -prune -o -type d \( $name_tests \) -prune -print0 2>/dev/null)

  (( $#junk )) || { print "Nothing to clean."; return 0; }
  _fuckjunk_report $junk
  (( dry_run )) && return 0

  if (( ! assume_yes )); then
    read -q "?Delete all of the above? [y/N] " || { print; return 1; }
    print
  fi
  # Finder can recreate .DS_Store mid-delete, so retry once before reporting errors.
  rm -rf -- $junk 2>/dev/null || rm -rf -- $junk || return 1
  print "Done."
}
