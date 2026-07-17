# vyges-iic-osic-tools

A Vyges-controlled, versioned **composition** of a complete open-source analog /
mixed-signal EDA environment: **IIC-OSIC-TOOLS** (byte-identical) **plus the Vyges
CLI + Loom sign-off engines on the default `PATH`**.

Unlike `vyges-openroad` / `vyges-klayout` — single tools we *rebuild from source* —
this is a **composition layer**: IIC-OSIC-TOOLS already ships a mature,
multi-arch analog toolchain (xschem, ngspice/Xyce, magic, netgen, KLayout, CACE) and
all three open PDKs (sky130, gf180mcu, **ihp-sg13cmos5l**), so we **derive from a
pinned upstream image digest** and add Loom — we do not rebuild the toolbox.

- **Compose, never fork or vendor.** This repo holds only the *recipe*: a pinned
  upstream digest + a pinned Vyges release. No upstream image, tools, or PDK in-tree.
- **The OSS baseline is untouched.** Everything from IIC-OSIC-TOOLS is byte-identical
  and **fully self-sufficient** — you can do complete DRC/LVS/sim/characterization
  sign-off with the upstream OSS tools alone, never invoking a Vyges component.
- **The Vyges CLI is on the default `PATH`.** This is a Vyges container, so `vyges`
  and its Loom engines are ready to use out of the box (being on `PATH` doesn't force
  their use — the OSS flow is unchanged; an agent or user can drive `vyges` directly).
- **Offline after build.** The Vyges engines are std-only Rust binaries fetched at
  build time; at runtime there are **no cloud pings** (updates are manual).

- **Image:** `ghcr.io/vyges-tools/vyges-iic-osic-tools`

## Use it

```sh
# OSS analog flow — identical to IIC-OSIC-TOOLS:
docker run --rm -it ghcr.io/vyges-tools/vyges-iic-osic-tools:latest \
  bash -lc 'klayout -v && magic --version && ngspice -v | head -1'

# Vyges CLI + Loom engines are already on PATH (env-free PDK resolution):
docker run --rm -it ghcr.io/vyges-tools/vyges-iic-osic-tools:latest \
  bash -lc 'vyges-lvs --version && vyges-extract gen-rc --pdk ihp_sg13cmos5l'
```

Or consume via the Vyges CLI `tools.json`:

```jsonc
{ "tools": { "analog-eda": { "container": {
    "runtime": "docker",
    "image": "ghcr.io/vyges-tools/vyges-iic-osic-tools:iic2026.07-loom0.1.15",
    "mounts": ["${PDK_ROOT}:${PDK_ROOT}:ro"]
} } } }
```

## Naming & selecting a build

The identity is the **pair** of pinned parents — the upstream IIC-OSIC-TOOLS release
and the Vyges Loom release — both visible in the tag.

| Tag | Meaning |
|---|---|
| `:sha-<digest12>` | immutable — one composition (upstream digest × loom version) |
| `:iic2026.07-loom0.1.15` | a pinned release (frozen), alias to a `sha-<…>` |
| `:latest` | moves to the newest pinned release |

`index.json` is the lookup table (upstream digest × loom version → image):

```sh
scripts/which.sh latest
scripts/which.sh iic2026.07-loom0.1.15
```

## How it's built

Single-stage, derive-and-install (see `Dockerfile.compose`):

1. `FROM` the **pinned IIC-OSIC-TOOLS digest** (`upstream.yaml`).
2. Install the **`vyges` CLI** (cargo-dist shell installer from `vyges-tools/cli`).
3. `vyges install loom` — fetch the **Loom suite** (foundation + engines: drc, lvs,
   extract, char, sta-si, …) from public `vyges-tools/*` releases into `~/.vyges/bin`.
4. Put `~/.vyges/bin` on the **default `PATH`** and wire the PDK env-free (symlink
   the base PDK under `~/.vyges/pdk-store`, root the descriptor at `$HOME`).
5. **Smoke-gate the build:** KLayout runs, the Vyges engines run on the default
   `PATH`, and `--pdk ihp_sg13cmos5l` resolves with no `PDK_ROOT` set.

Workflows: `release.yml` (build + push a pinned composition → `ghcr` + `index.json`),
`sync.yml` (watch IIC-OSIC-TOOLS + `vyges-tools/cli` releases → PR a pin bump).

## Bump a pin / cut a release

Edit **`upstream.yaml`** (`iic_osic_tools.digest` and/or `vyges.cli_version`) — the
source of truth — then run the `release` workflow with a `version`
(e.g. `iic2026.07-loom0.1.15`).

## Licensing

Repository tooling (Dockerfile, scripts, workflows) is **Apache-2.0** (`LICENSE`).
The composed artifact contains:

- **IIC-OSIC-TOOLS + its tools + PDKs** — each under its own upstream license
  (IIC-OSIC-TOOLS recipe is Apache-2.0; bundled tools/PDKs keep their own terms).
- **The Vyges layer** — the `vyges-loom` core is Apache-2.0; the `vyges` CLI is
  closed-source (binary-only); **per-foundry calibration/plugins are distributed
  separately under their own terms** (some non-open). The image `NOTICE` +
  `manifest.json` record the exact upstream digest + Vyges versions and each
  component's license. **The OSS sign-off path is fully self-sufficient and never
  depends on a non-open Vyges component**, even though `vyges` is on the default `PATH`.
