#!/usr/bin/env zsh
# Run: zsh test/fuckjunk.test.zsh

source ${0:A:h:h}/fuckjunk.zsh

integer failures=0
sandbox=$(mktemp -d)
trap 'rm -rf $sandbox' EXIT

fail() { print -r -- "FAIL: $1"; (( failures++ )); }
assert_deleted() { [[ ! -e $sandbox/$1 ]] || fail "expected deleted: $1"; }
assert_kept() { [[ -e $sandbox/$1 ]] || fail "expected kept: $1"; }

touch_file() { mkdir -p $sandbox/${1:h} && touch $sandbox/$1; }

git_in() { git -C $sandbox/$1 -c user.name=test -c user.email=test@test -c commit.gpgsign=false "${@:2}"; }

build_fixture() {
  rm -rf $sandbox/*(N)
  touch_file web/node_modules/pkg/index.js
  touch_file web/.angular/cache/entry
  touch_file "my app/.next/cache/entry"
  touch_file py/.venv/pyvenv.cfg
  touch_file py/__pycache__/module.pyc
  touch_file src/venv/__init__.py
  touch_file dotnet/App.csproj
  touch_file dotnet/bin/Debug/App.dll
  touch_file dotnet/obj/project.assets.json
  touch_file tools/bin/run.sh
  touch_file plain/build/output.js

  touch_file repo/dist/bundle.js
  touch_file repo/build/generate.js
  touch_file repo/pkg/dist/shipped.js
  touch_file repo/vendor/node_modules/lib.js
  print "dist/" > $sandbox/repo/.gitignore
  git_in repo init -q
  git_in repo add .gitignore build vendor
  git_in repo add -f pkg/dist/shipped.js
  git_in repo commit -qm fixture
}

assert_junk_deleted() {
  assert_deleted web/node_modules
  assert_deleted web/.angular
  assert_deleted "my app/.next"
  assert_deleted py/.venv
  assert_deleted py/__pycache__
  assert_deleted dotnet/bin
  assert_deleted dotnet/obj
  assert_deleted repo/dist
}

assert_non_junk_kept() {
  assert_kept src/venv/__init__.py
  assert_kept dotnet/App.csproj
  assert_kept tools/bin/run.sh
  assert_kept plain/build/output.js
  assert_kept repo/build/generate.js
  assert_kept repo/pkg/dist/shipped.js
  assert_kept repo/vendor/node_modules/lib.js
}

test_dry_run_deletes_nothing() {
  build_fixture
  fuckjunk -n $sandbox > /dev/null
  assert_kept web/node_modules
  assert_kept dotnet/bin
  assert_kept repo/dist
}

test_deletes_only_junk() {
  build_fixture
  fuckjunk -y $sandbox > /dev/null
  assert_junk_deleted
  assert_non_junk_kept
}

test_reports_nothing_to_clean() {
  build_fixture
  fuckjunk -y $sandbox > /dev/null
  [[ $(fuckjunk -y $sandbox) == "Nothing to clean." ]] || fail "second run should find nothing"
}

test_rejects_missing_directory() {
  fuckjunk -n $sandbox/missing 2> /dev/null && fail "missing directory should fail"
}

for test_case in ${(ok)functions[(I)test_*]}; do
  integer before=$failures
  $test_case
  (( failures == before )) && print -r -- "ok    $test_case" || print -r -- "FAILED $test_case"
done

(( failures == 0 ))
