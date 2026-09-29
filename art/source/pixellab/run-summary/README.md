# PixelLab — post-run summary

Source assets generated on 2026-09-29 for the post-run summary. These files are
production inputs, not loaded directly by Godot. Run `python tools/build_run_summary_assets.py`
to rebuild normalized runtime files under `assets/ui/run_summary/`.

The UI sheet returned text inside two proposed buttons despite a text-free brief.
The builder intentionally discards those regions. Godot renders all labels,
numbers, grades, obituary copy and actions as live controls.

The exact generation prompts, transparency flags, gallery asset ids and seeds
are retained in `metadata.json`. Runtime labels may reinterpret an illustration
only as decoration; gameplay values always come from the live simulation.

| File | PixelLab id | Seed |
| --- | --- | --- |
| `run_summary_ui_sheet.png` | `0eafd554-6d12-46ec-9f0e-73545fc82921` | 1941 |
| `loot_scrap.png` | `39582c06-8900-4e03-90c9-47b43e39f177` | 1941 |
| `loot_fragment.png` | `28b98010-de10-4f3f-b117-345fa30040bd` | 1942 |
| `loot_blueprint.png` | `2bb8ac30-2458-4e6a-962f-f0177c786237` | 1943 |
| `loot_relic.png` | `66c9f63f-9629-4721-9850-629e56751c38` | 1944 |
