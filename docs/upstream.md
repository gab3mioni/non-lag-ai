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

The BetterNavyAI integration imports 85 of its functional files, normalizing line
endings and non-semantic trailing whitespace. Its `descriptor.mod`,
`Thumbnail.png`, and `common/national_focus/usa.txt` are intentionally excluded
so this project keeps its own identity and does not override national focus trees.
The Sheep's Mod national focus trees are excluded for the same compatibility
reason. `common/defines/bna_defines.lua` is imported as
`common/defines/zz_bna_defines.lua` so BetterNavyAI overrides are evaluated
after `common/defines/lsm_defines.lua` in ASCII filename order.
