# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Centreon Plugins: a large collection of Nagios-compatible monitoring plugins, written in Perl on a shared framework. Every check returns an exit code (`0` OK, `1` WARNING, `2` CRITICAL, `3` UNKNOWN), a one-line human-readable output, and perfdata after a `|`. The default branch is `develop`.

Main docs: `doc/en/developer/plugins_global.md` (layout, code style, plugin/mode structure, options), `doc/en/developer/plugins_advanced.md` (framework libraries), `doc/en/developer/plugins-ci.md` (CI pipeline), `tests/README.md` (testing).

## Running a plugin

All plugins run through a single entry point; `--plugin` is the Perl package path under `src/`:

```bash
perl src/centreon_plugins.pl --list-plugin
perl src/centreon_plugins.pl --plugin=os::linux::snmp::plugin --list-mode
perl src/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=cpu --help
perl src/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=cpu --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public
```

Add `--debug --verbose` to see raw HTTP/SNMP exchanges (useful for gathering test data).

## Tests

Two kinds of tests, both under `tests/`, mirroring the `src/` tree:

- **Perl unit tests** (`*.t`, Test2): `yath -L test ./tests` (CI), or one file: `yath test tests/centreon/plugins/mask_secrets.t`.
- **Robot Framework integration tests** (`*.robot`): `robot tests/os/linux/snmp/cpu.robot`. Use `-e notauto` like CI, `-i <tag>` to filter, `-v CENTREON_PLUGINS:/path/to/fatpacked.pl` to test a built plugin instead of the repo source.
  - SNMP tests need snmpsim running from the repo root, serving `.snmpwalk` files under `tests/`; the `--snmp-community` in a test is the walk file's path relative to `tests/` without extension (e.g. `os/linux/snmp/network-interfaces`):
    ```bash
    sudo snmpsim-command-responder --logging-method=null --agent-udpv4-endpoint=127.0.0.1:2024 --process-user=snmp --process-group=snmp --data-dir='./tests' &
    ```
  - HTTP/API tests use Mockoon: a JSON mock next to the `.robot` file, started via `Start Mockoon` / `Stop Mockoon` from `tests/resources/resources.resource`.
  - Generate a robot skeleton for a mode: `./resources/tools/generate_robot_files.sh os::freebsd::snmp::plugin cpu`, then fill in the expected outputs.
  - Shrink/anonymize a user-provided walk: `perl tests/scripts/slim_walk.pl --snmpwalk-path=<file>`. Test data must be anonymized.
- Coverage: prefix any test command with `PERL5OPT=-MDevel::Cover`, then run `cover`.
- Docker images for a full test environment are in `.github/docker/testing/`.

## Pre-commit checks (`.githooks/`)

Enable with `git config core.hooksPath .githooks`. CI enforces the same rules, so follow them even without the hooks. For each staged `.pm`/`.pl`:

- Must compile: `perl -I ./src -I ./tests/connectors/vmware -I ./connectors/vmware/src -c <file>`
- Must contain the header line `Copyright 20XX-Present Centreon`.
- Help (POD) must document each threshold separately (`--warning-foo`, `--critical-foo`), never `--warning-*` / `--critical-*`.
- POD spellcheck: `perl .github/scripts/pod_spell_check.t <file> ./tests/resources/spellcheck/stopwords.txt`. Add legitimate words to `stopwords.txt`, which must stay sorted (`sort -ui`).
- Counter definitions outside `src/centreon/plugins/` must use constants from `centreon::plugins::constants` (`use centreon::plugins::constants qw(:counters);`) instead of literal `type => 0` / `-1 => 1` etc.
- No `md5_hex`; use `sha256_hex` from `Digest::SHA`.
- No tabs for indentation, no CRLF.
- `.robot` files must be formatted with `robocop format`; YAML is linted with `resources/githooks/yamllint_rules.yml`; staged `tests/**/*.t` are run with yath.
- gitleaks runs on commit and push.

## Architecture

- `src/centreon_plugins.pl` → `centreon::plugins::script` loads the `--plugin` package, which picks the `--mode`.
- **plugin.pm** (e.g. `src/os/linux/snmp/plugin.pm`): inherits from a protocol-specific script class (`script_snmp`, `script_custom`, `script_sql`, `script_simple`, `script_wsman`, `script_mqtt`) and maps mode names to mode packages. `script_custom` plugins also declare `custom_modes` (e.g. `api`, `cli`) living in the plugin's `custom/` dir, which wrap the transport (HTTP auth/token caching, SSH/CLI execution) and are shared across modes.
- **mode.pm**: most modes inherit from `centreon::plugins::templates::counter` and declare `set_counters` (metrics, thresholds, perfdata, output) plus `manage_selection` (collect data into `$self->{...}` hashes). Hardware-component checks use `templates::hardware`. Options are declared with `add_options` with declarative validators (`not_empty`, `type => 'port'`, `is_in`, ...) — see section 11 of `plugins_global.md`.
- **Shared framework** in `src/centreon/plugins/`: protocol backends (`snmp.pm`, `http.pm` with `backend/` curl/lwp, `ssh.pm`, `dbi.pm`, `wsman.pm`), `options.pm`, `output.pm`, `perfdata.pm`, `statefile.pm` (cache between runs), `misc.pm`, `passwordmgr/`. Changes here affect every plugin.
- `src/centreon/common/` holds code shared across vendors; `src/snmp_standard/mode/` holds modes based on standard MIBs reused by many SNMP plugins.
- Plugins are organized by domain then vendor/product then protocol: `src/{apps,cloud,database,hardware,network,os,storage,...}/<vendor>/<product>/<protocol>/`.

## Building a new plugin or mode

Follow this process every time (agreed with the maintainer; `apps::protocols::mtr` is the reference implementation):

1. **Plan first, code after approval.** Propose plugin path, modes, options (with defaults and what each means), counters with nlabels and thresholds, cache handling and tests; wait for the go-ahead.
2. **Use the newest plugins as the model, not old ones.** Mandatory idioms:
   - `use centreon::plugins::constants qw(:counters :values);` — `COUNTER_TYPE_GLOBAL/INSTANCE/MULTIPLE`, `COUNTER_KIND_TEXT`, `COUNTER_MULTIPLE_SUBINSTANCE`, `skipped_code => { NO_VALUE() => 1 }`, `BUFFER_CREATION`, `MSG_JSON_DECODE_ERROR`. Never literal `type => 1` / `-10 => 1`.
   - `use centreon::plugins::misc qw/is_excluded/;` with `--include-*` / `--exclude-*` options: `next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});`. Keep a legacy `--filter-*` option with `{ redirect => 'include_...' }`.
   - `$self->{output}->option_exit(short_msg => '...') unless ...;` instead of `add_option_msg` + `option_exit`.
   - Declarative validators in `add_options` (`not_empty`, `numeric`, `type => 'port'`, `greater_than`, `is_in`, `regexp_match`, `error_message`) instead of hand-written checks in `check_options`.
   - `force_new_perfdata => 1` in the mode constructor (or `modes_options` in `plugin.pm` when reusing `snmp_standard` modes).
   - `//` for defaults, explicit sort in lists (`sort { $a->{name} cmp $b->{name} }`, `sort_attribute`/`sort_method => 'num'` for instances).
   - Status counters: `type => COUNTER_KIND_TEXT`, `output_template` with `%{var}`, `closure_custom_threshold_check => \&catalog_status_threshold_ng`, `warning_default`/`critical_default`.
   - Cache files: `centreon::plugins::statefile`, cache name built with `sha256_hex` (`Digest::SHA`), never `md5_hex`.
   - Local commands: `--command`, `--command-path`, `--command-options`, `--timeout`, `centreon::plugins::misc::check_security_command(...)` before applying defaults, then `centreon::plugins::misc::execute(...)`; log the raw output with `output_add(long_msg => $stdout, debug => 1)`.
3. **Help (POD)**: every option documented, one `=item` per threshold (`--warning-foo`, `--critical-foo`, never `--warning-*`), full sentences with capital letter and final period. Wrap special words (commands, values, macros, options in text) in `C<>`, emphasis in `B<>`.
4. **Spellcheck every `.pm`**: `perl .github/scripts/pod_spell_check.t <file.pm> tests/resources/spellcheck/stopwords.txt` (on the Windows dev machine: `pod-spell-check <file.pm>`). Prefer `C<>` or rewording over adding words to `stopwords.txt`; if a word is added, keep the file sorted (`sort -ui`).
5. **Robot tests** in `tests/<same path as src>/`: fake external commands with a script in `bin/` selected via `--command-path` and fixtures in `data/`; anonymized data; state-dependent cases use `--statefile-dir=/dev/shm/` and run in order. In `Examples` rows, `%{var}` must be written `\\\%{var}`, and regexps should avoid backslashes (`[.]` instead of `\.`). Generate expected outputs from real runs, never by hand. Format with `robocop format` (on Windows it writes CRLF: convert back to LF). Add a Perl unit test (`.t`, Test2::V0, mocked `misc::execute`/statefile) for parsing and comparison logic. On Windows (`core.fileMode=false`) add fake commands with `git add --chmod=+x`, or CI cannot execute them.
6. **Anonymize everything that goes into the repo** (it is public): mock files, fixtures, snmpwalks, robot expected outputs, unit tests and comments must never contain passwords, keys, tokens, real host names or public IP addresses. Use RFC 5737 documentation addresses (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), `*.example` names, and replace data supplied by users before writing any file (`tests/scripts/slim_walk.pl` for snmpwalks). Check with a grep for IPv4 addresses outside these ranges before handing over.
7. **Packaging is done by the maintainer**: do not create or edit `packaging/` unless asked.
8. **Do not commit or push**: the maintainer commits.

## Packaging

Each shipped plugin has a directory in `packaging/centreon-plugin-<Domain>-<Name>/` with `pkg.json` (package name, output script name, and the exact list of `src/` files/dirs to fatpack) plus `rpm.json`/`deb.json` for dependencies. A new plugin needs a new packaging directory; when a plugin starts using another shared file (e.g. a `snmp_standard` mode or a `centreon/plugins/*.pm` backend), add it to `pkg.json` `files`, or the fatpacked plugin will break. CI (`.github/workflows/plugins.yml`) detects changed plugins, fatpacks, packages for each distribution, and runs the robot tests against the packaged plugin.

## Other components

- `rust-plugins/`: Rust `generic-snmp` plugin driven by JSON collections in `rust-plugins/rs-collections/` (validated by `.github/scripts/validate-rs-collections.sh`). Build with `cargo build`; release builds use `--target x86_64-unknown-linux-musl`.
- `connectors/vmware/`: the VMware connector daemon used by the `apps::vmware::connector` plugin.
- `dependencies/`, `nrpe/`, `as400/`, `selinux/`: packaging of supporting components, each with its own workflow.

## PR conventions

Internal PRs need the Jira ticket ID in the branch name/PR (CI checks it for integration branches). The PR checklist requires automated tests for the change, anonymized test data, and that all help messages in touched `.pm` files are full sentences starting with a capital letter and ending with a period.
