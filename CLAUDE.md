# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Minecraft shaderpack written in GLSL for Iris, targeting Minecraft 1.21.5. It is based on the ShaderLABS Base-330 template. All shader content lives in `shaders/`. The Gradle project exists only to launch a dev client and package the pack; there is no Java source.

## Commands

Gradle needs a Java 21 toolchain.

- `./gradlew runShaderClient`: launch Minecraft with Sodium and Iris, with this pack applied.
- `./gradlew runShaderDebugClient`: same, with debug logging and JDWP on port 5005.
- `./gradlew assemble`: build the release zip into `build/releases/`. `./gradlew zipShaderpack` builds only the zip.

There are no tests and no linter. Shaders are compiled by Iris at load time, so the only way to verify a change is to run the client and check the output in-game or in `run/logs/latest.log`.

## Dev loop

`runShaderClient` first runs `prepareShaderDevClient`, which:

- symlinks `run/shaderpacks/minecraft-shader-template-dev/shaders` to the repo's `shaders/` directory (a junction on Windows), so edits apply on an in-game shader reload without restarting or re-syncing;
- writes `run/config/iris.properties` to enable shaders, select the dev pack, and turn on `enableDebugOptions`.

`run/` is gitignored. `shaders/shaders.properties` and `shaders/block.properties` travel with the symlink. Root-level `pack.mcmeta`, `lang/`, and `LICENSE*` would be copied rather than linked, so they'd need a Gradle re-run to reach the dev pack. None exist yet.

## Shader architecture

A toon and crayon look. Each Iris program is a `.vsh`/`.fsh` pair, and the filename is what binds it to a pipeline stage, so names can't be changed freely.

The pipeline is `shadow` → `gbuffers_*` → `deferred` (passthrough) → `composite`. There is no `final` pass.

- Lighting is forward, not deferred: each lit `gbuffers_*` pass shades itself and writes colour to `colortex0` and its view-space normal to `colortex1`. Translucent passes work the same way, so nothing needs position reconstruction.
- Lit programs are thin wrappers that set `#define`s and include `lib/lit_vertex.glsl` and `lib/lit_fragment.glsl`. Edit those rather than the wrappers. The toon model itself (light bands, sun shadow lookup, hatching, fog) is in `lib/toon.glsl`.
- `composite.fsh` draws the outlines from `depthtex0` and `colortex1`, then applies the crayon grain and paper.
- `lib/crayon.glsl` holds the noise and the boil. Grain is in screen space, normalised to 1080p, and re-seeded `BOIL_FPS` times per second.
- `gbuffers_armor_glint`, `basic`, `beaconbeam`, `clouds`, `skytextured`, `spidereyes`, and `weather` are still the unlit template programs and write only `colortex0`.
- All files use `#version 330 compatibility`. The compatibility profile is required, since the code relies on `ftransform()`, `gl_Color`, `gl_TextureMatrix`, and `gl_MultiTexCoord*`.
- Tunable values are in `lib/settings.glsl`. Iris reads the `const` shadow settings from the source text, so they must stay plain literals. `block.properties` assigns the `mc_Entity` IDs, and `BLOCK_PLANT` must match it.
