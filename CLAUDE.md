# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A fork of [centreon-plugins](https://github.com/centreon/centreon-plugins): Perl monitoring plugins that follow the Nagios/Monitoring-Plugins contract (exit code `0` OK / `1` WARNING / `2` CRITICAL / `3` UNKNOWN, one human-readable line, perfdata after `|`).

i-Vertix additions on top of upstream:
- `src/ivertix/plugins/` – in-house plugins (namespace `ivertix::plugins::...`, copyright header `i-Vertix`), built on the same framework as upstream.
- `tests/api-simulator/i-vertix/apisim.yaml` – REST API simulator data (see below). It lives **only** on branch `ivertix-custom-plugins`, which is checked out permanently in this worktree (`C:\dev\centreon-plugins-apisim`) and is never PR'd. Feature/plugin work happens on other branches (from `develop`); simulator data is edited and committed here only.

## Commands

All commands run from the repo root with `src/` on the include path.

```bash
# discover plugins / modes / options
perl src/centreon_plugins.pl --list-plugin
perl src/centreon_plugins.pl --plugin=os::linux::snmp::plugin --list-mode
perl src/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --help

# run a mode (add --debug / --verbose to see HTTP/SNMP exchanges and per-instance output)
perl src/centreon_plugins.pl --plugin=<perl::path::plugin> --mode=<mode> --hostname=... [options]

# compile check of a single module (same as the pre-commit hook)
perl -I ./src -c src/path/to/mode/foo.pm

# POD spell check (stopwords list must stay sorted: sort -ui)
perl .github/scripts/pod_spell_check.t src/path/to/file.pm ./tests/resources/spellcheck/stopwords.txt
```

On Windows use the user-local Strawberry Perl, not Git-Bash's perl.

### Robot integration tests (`tests/`, mirrors `src/` layout)

```bash
robot tests/apps/apache/serverstatus/requests.robot      # single suite
robot -i <tag> tests/                                    # by tag; -e notauto to exclude
robot -v CENTREON_PLUGINS:/path/to/fatpacked.pl tests/   # test a fatpacked plugin (uses the connector)
robocop format <file>.robot                              # required formatting
```

- HTTP tests mock the API with a `*.mockoon.json` next to the `.robot` file (`Start Mockoon` in suite setup); SNMP tests use `*.snmpwalk` files served by snmpsim (`--data-dir=./tests`, community = path of the walk relative to `tests/`, e.g. `hardware/server/lenovo/xcc/snmp/system-health-ok`).
- Test cases call keywords from `tests/resources/resources.resource` (`Ctn Run Command And Check Result As Strings` / `As Regexp`) with an `Examples:` table of `extra_options` → `expected_result`.
- Shrink/anonymize a user-provided walk: `perl tests/scripts/slim_walk.pl --snmpwalk-path=<file>`.
- Unit tests are `*.t` files (Perl `Test2::V0`) beside the robot suites; CI runs them with `yath -L test ./tests` (single file: `yath test tests/centreon/plugins/curllogger.t`). Coverage: prefix any test command with `PERL5OPT=-MDevel::Cover`, then run `cover`.

### Pre-commit checks

`.githooks/pre-commit` (enable with `git config core.hooksPath .githooks`; not active by default here) runs `.githooks/pre-commit.d/20_plugins.sh`, which enforces for every staged `.pm`/`.pl`:
- compiles with `perl -I ./src -c`;
- copyright line `Copyright 20..-Present Centreon` (i-Vertix plugins use their own header and will trip this check);
- no help written as `--warning-*` / `--critical-*` – document each threshold option explicitly;
- POD spellcheck passes;
- counter definitions use constants from `centreon::plugins::constants` (no `type => 0`, no `-1/-2/-10 => 1` literals);
- `sha256_hex` (Digest::SHA) instead of `md5_hex`.

## Architecture

Execution chain: `src/centreon_plugins.pl` → `centreon::plugins::script` (parses `--plugin`, loads it, handles `--list-plugin`, `--help`, `--dyn-mode`) → the plugin's `plugin.pm` → the selected mode.

- **`plugin.pm`** inherits a script base that defines the transport: `script_custom` (HTTP/REST/CLI via a *custom mode*), `script_snmp`, `script_sql`, `script_simple`, `script_wsman`. It only maps mode names → mode packages (`$self->{modes}`) and, for `script_custom`, custom modes → packages (`$self->{custom_modes}->{api}`, selected with `--custommode`).
- **Custom mode** (`.../custom/api.pm`, `.../custom/cli.pm`): owns connection options (`--hostname`, `--port`, `--proto`, credentials, `--timeout`), auth/token caching (via `centreon::plugins::statefile`), and request helpers built on `centreon::plugins::http` (backends `lwp`/`curl` under `centreon/plugins/backend/`). Modes call it through `$options{custom}`.
- **Modes** almost always extend `centreon::plugins::templates::counter`:
  - `set_counters` declares `maps_counters_type` (global / per-instance / group / multiple – use the `COUNTER_TYPE_*` constants) and `maps_counters` (each counter: `nlabel` for the metric name, `key_values`, `output_template`, `perfdatas`, or `type => COUNTER_KIND_TEXT` with `closure_custom_threshold_check` for status checks via `--warning-status`/`--critical-status` expressions).
  - `manage_selection` fetches data and fills `$self->{<counter group name>}`; the template handles thresholds (`--warning-<label>` / `--critical-<label>`), perfdata, short/long output and `--filter-counters`.
  - `list-*` modes plus `disco_format`/`disco_show` implement Centreon service discovery.
- **Shared code**: `src/centreon/plugins/` (framework: `misc.pm` helpers such as `is_excluded`, `output.pm`, `perfdata.pm`, `values.pm`, `constants.pm`, `statefile.pm`), `src/centreon/common/` (code shared by several vendors/protocols), `src/snmp_standard/mode/` (generic SNMP modes like interfaces, storage, cpu reused by many SNMP plugins).
- **Packaging**: each shipped plugin has `packaging/centreon-plugin-<Name>/{pkg.json,rpm.json,deb.json}`; `pkg.json` lists the source paths that `.github/scripts/fatpack-plugins.pl` bundles into a single standalone `.pl`. A new plugin needs this directory and must list every shared module it uses.

Developer docs: `doc/en/developer/plugins_global.md` (layout, style, output/perfdata rules, discovery), `tutorial-api.md`, `tutorial-snmp.md`, `tutorial-service_discovery.md`.

## API simulator (`tests/api-simulator/i-vertix/apisim.yaml`)

One YAML file of apisimulator *simlets* separated by `---`. Each simlet has a `simlet:` name, a top-level `request:` matcher (method + path) and `responses:` with `when: request:` conditions (`uriPath`, `uri contains`, `uriQueryParameter`, `header`, `body contains`) and a `from: stub` response.

- Simlets are matched **in file order**; a simlet whose top-level `request` is too broad swallows requests meant for later simlets. Keep top-level matchers specific (e.g. `where: uriPath contains: /sadelvoip/api/v1/`) and put a final `- from: stub` / `status: 404` fallback inside a simlet that matches by prefix.
- Paths are namespaced per product (`/azure/...`, `/aws/...`, `/velocloud/...`, `/zic/...`, `/zvm/...`, `/sadelvoip/...`), and fake credentials are fixed values (e.g. `Bearer token-123`, `client-id-ivertix`, `apikey: 1234`).
- Plugins are pointed at it with `--hostname=i-vertix-simulation-vm --port=6090 --proto=http` plus the product path prefix where the plugin allows a base URL/path option.
- A local (unversioned) `.git/hooks/pre-push` refuses to push `tests/api-simulator/` to any branch other than `ivertix-custom-plugins`; never bypass it to publish simulator data elsewhere.
