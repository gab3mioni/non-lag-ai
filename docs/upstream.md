# Upstream sources

This repository vendors content from the following Hearts of Iron IV Workshop
items for private use:

| Component | Workshop ID | Steam manifest | Upstream update |
| --- | ---: | ---: | --- |
| Sheep's Mod | `3265939166` | `8430687326046549837` | 2026-02-13 07:16:50 UTC |
| BetterNavyAI (SheepCompatable) | `3669987814` | `8032472863672882538` | 2026-02-21 17:47:59 UTC |

The repository baseline matches the Sheep's Mod manifest above after line-ending
normalization, excluding its Workshop metadata (`descriptor.mod`,
`mod_version_log.txt`, and `thumbnail.png`).

The BetterNavyAI integration imports its 86 functional files, normalizing line
endings and non-semantic trailing whitespace. Its
`descriptor.mod` and `Thumbnail.png` are intentionally excluded so this project
keeps its own identity. `common/defines/bna_defines.lua` is imported as
`common/defines/zz_bna_defines.lua` so BetterNavyAI overrides are evaluated
after `common/defines/lsm_defines.lua` in ASCII filename order.
