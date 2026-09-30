"""Reusable levels transformations for Sonic 1 resources."""

from __future__ import annotations

import argparse
import base64
import json
import re
import struct
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from s1tools.codecs.enigma import decode_bytes as enigma_decode_bytes
from s1tools.codecs.kosinski import decode as kosinski_decode
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root

gallery_ROOT = get_root()
gallery_OUTPUT = gallery_ROOT / "tmp"
gallery_ZONES = {
    "GHZ": {
        "name": "Green Hill Zone",
        "art": "artnem/8x8 - GHZ (Combined).nem",
        "map": "map16/GHZ.bin",
        "overlays": [
            (844, "nemesis", "artnem/GHZ Edge Wall.nem", None),
            (856, "nemesis", "artnem/GHZ Flower Stalk.nem", None),
            (860, "raw", "artunc/GHZ Flower Large.unc", 16),
            (876, "raw", "artunc/GHZ Flower Small.unc", 12),
            (888, "raw", "artunc/GHZ Waterfall.unc", 8),
            (896, "nemesis", "artnem/GHZ Swinging Platform.nem", None),
            (910, "nemesis", "artnem/GHZ Bridge.nem", None),
            (920, "nemesis", "artnem/GHZ Spiked Log.nem", None),
            (938, "nemesis", "artnem/GHZ Giant Ball.nem", None),
        ],
        "palettes": [("main", "Normal", "palette/Green Hill Zone.bin")],
    },
    "LZ": {
        "name": "Labyrinth Zone",
        "art": "artnem/8x8 - LZ.nem",
        "map": "map16/LZ.bin",
        "palettes": [
            ("dry", "Above water", "palette/Labyrinth Zone.bin"),
            ("water", "Underwater", "palette/Labyrinth Zone Underwater.bin"),
        ],
    },
    "MZ": {
        "name": "Marble Zone",
        "art": "artnem/8x8 - MZ.nem",
        "map": "map16/MZ.bin",
        "overlays": [
            (722, "raw", "artunc/MZ Lava.unc", 16),
            (738, "raw", "artunc/MZ Lava Surface.unc", 8),
            (754, "raw", "artunc/MZ Background Torch.unc", 6),
        ],
        "palettes": [("main", "Normal", "palette/Marble Zone.bin")],
    },
    "SLZ": {
        "name": "Star Light Zone",
        "art": "artnem/8x8 - SLZ.nem",
        "map": "map16/SLZ.bin",
        "overlays": [
            (884, "nemesis", "artnem/SLZ Seesaw.nem", None),
            (928, "nemesis", "artnem/SLZ Fan.nem", None),
        ],
        "palettes": [("main", "Normal", "palette/Star Light Zone.bin")],
    },
    "SYZ": {
        "name": "Spring Yard Zone",
        "art": "artnem/8x8 - SYZ.nem",
        "map": "map16/SYZ.bin",
        "palettes": [("main", "Normal", "palette/Spring Yard Zone.bin")],
    },
    "SBZ": {
        "name": "Scrap Brain Zone",
        "art": "artnem/8x8 - SBZ.nem",
        "map": "map16/SBZ.bin",
        "overlays": [
            (1096, "raw", "artunc/SBZ Background Smoke.unc", 12),
            (1108, "raw", "artunc/SBZ Background Smoke.unc", 12),
        ],
        "palettes": [
            ("act1", "Act 1", "palette/SBZ Act 1.bin"),
            ("act2", "Act 2", "palette/SBZ Act 2.bin"),
            ("act3", "Act 3", "palette/SBZ Act 3.bin"),
            ("act3_water", "Act 3 underwater", "palette/SBZ Act 3 Underwater.bin"),
        ],
    },
}


def gallery_decode_enigma(blob: bytes) -> bytes:
    """Decoded 16x16 block words, packed big-endian (exact EniDec model, base 0)."""
    return enigma_decode_bytes(blob)


def gallery_load_blocks(path: Path) -> bytes:
    """16x16 block words, packed big-endian, as the game reads them.

    The game uses raw map16/*.bin from ROM; a legacy .eni is decompressed
    (EniDec base 0), which yields the same layout.
    """
    blob = path.read_bytes()
    return blob if path.suffix.lower() == ".bin" else gallery_decode_enigma(blob)


def gallery_asm_palette(label: str) -> bytes:
    source = (gallery_ROOT / "_inc/Palette Index.asm").read_text(encoding="utf-8")
    match = re.search(f"^{label}:\\s*(.*?)(?=^\\w+:|\\Z)", source, re.M | re.S)
    if not match:
        raise ValueError(f"Missing palette {label}")
    words = [int(value, 16) for value in re.findall("\\$([0-9A-Fa-f]{4})", match.group(1))]
    if len(words) != 16:
        raise ValueError(f"Expected 16 colours in {label}, got {len(words)}")
    return b"".join(word.to_bytes(2, "big") for word in words)


def gallery_palette_pair(path: Path, normal_sonic: bytes, super_dry: bytes, super_water: bytes):
    level = path.read_bytes()
    if len(level) == 96:
        return (normal_sonic + level, super_dry + level)
    if len(level) == 128:
        return (level, super_water + level[32:])
    raise ValueError(f"Unexpected palette size for {path}: {len(level)}")


gallery_HTML = "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n<title>__ZONE__ — art layout</title>\n<style>\n  :root { --zoom: 5; color-scheme: dark; font-family: Segoe UI, sans-serif; }\n  body { margin: 0; background: #111218; color: #f4f4f5; }\n  header { position: sticky; top: 0; z-index: 5; padding: 14px 18px; background: #191b24ee; border-bottom: 1px solid #343746; backdrop-filter: blur(8px); }\n  h1 { font-size: 20px; margin: 0 0 10px; }\n  h2 { font-size: 17px; margin: 22px 18px 10px; }\n  .controls { display: flex; flex-wrap: wrap; gap: 14px; align-items: center; }\n  label { display: flex; gap: 7px; align-items: center; }\n  input, select { accent-color: #8b7cff; }\n  input[type=search] { width: 150px; padding: 5px 8px; background: #0d0e13; color: white; border: 1px solid #444857; border-radius: 5px; }\n  .hint { color: #b7bac8; font-size: 13px; margin-top: 8px; }\n  .grid { display: grid; grid-template-columns: repeat(8, minmax(0, 1fr)); gap: 8px; padding: 0 18px 18px; }\n  .card { min-width: 0; padding: 7px; border: 1px solid #303341; border-radius: 7px; background: #1a1c25; cursor: pointer; }\n  .card:hover { border-color: #8b7cff; background: #232635; }\n  .card.selected { border-color: #73e6a5; background: #173126; box-shadow: 0 0 0 2px #73e6a533 inset; }\n  .images { display: flex; gap: 5px; justify-content: center; align-items: flex-start; }\n  canvas { width: min(calc(16px * var(--zoom)), calc(50% - 3px)); height: auto; aspect-ratio: 1; image-rendering: pixelated; background: #000; }\n  .label { margin-top: 5px; font: 12px Consolas, monospace; text-align: center; white-space: nowrap; }\n  .meta { color: #989cad; font-size: 10px; text-align: center; }\n  body.mode-normal canvas.super, body.mode-super canvas.normal { display: none; }\n  body.mode-normal canvas.normal, body.mode-super canvas.super { width: min(calc(16px * var(--zoom)), 100%); }\n  .empty { display: none; }\n  #selected { color: #d8d2ff; font-family: Consolas, monospace; }\n  button { padding: 6px 10px; color: #f4f4f5; background: #292c39; border: 1px solid #4a4e60; border-radius: 5px; cursor: pointer; }\n  button:hover { background: #363a4b; border-color: #8b7cff; }\n</style>\n</head>\n<body class=\"mode-both\">\n<header>\n  <h1>__ZONE__ — blocks layout 16×16</h1>\n  <div class=\"controls\">\n    <label>Size <input id=\"zoom\" type=\"range\" min=\"2\" max=\"10\" value=\"5\"></label>\n    <label>Variant <select id=\"scenario\"></select></label>\n    <label>Palette <select id=\"mode\"><option value=\"both\">Normal / Super</option><option value=\"normal\">Normal Sonic</option><option value=\"super\">Super Sonic</option></select></label>\n    <label>Number <input id=\"filter\" type=\"search\" placeholder=\"for example 080\"></label>\n    <button id=\"saveSelection\" type=\"button\">Save JSON</button>\n    <button id=\"copySelection\" type=\"button\">Copy numbers</button>\n    <button id=\"clearSelection\" type=\"button\">Clear</button>\n    <span id=\"selected\">Selected: 0</span>\n  </div>\n  <div class=\"hint\">Click to toggle block selection. Selection persists across reloads. Normal palette on the left; on the right: Super Sonic.</div>\n</header>\n<h2>Blocks using palette Sonic</h2>\n<div id=\"dynamic\" class=\"grid\"></div>\n<h2>All blocks __ZONE__</h2>\n<div id=\"all\" class=\"grid\"></div>\n<script>\nconst DATA = __DATA__;\nconst bytes = b64 => Uint8Array.from(atob(b64), c => c.charCodeAt(0));\nconst art = bytes(DATA.art), packedWords = bytes(DATA.words);\nconst words = new Uint16Array(DATA.blockCount * 4);\nfor (let i=0;i<words.length;i++) words[i]=(packedWords[i*2]<<8)|packedWords[i*2+1];\nconst palettes = Object.fromEntries(Object.entries(DATA.palettes).map(([key,value])=>[key,{label:value.label,normal:bytes(value.normal),super:bytes(value.super)}]));\nconst scenarioSelect=document.querySelector('#scenario');\nfor(const [key,value] of Object.entries(palettes)){const option=document.createElement('option');option.value=key;option.textContent=value.label;scenarioSelect.append(option);}\nconst STORAGE_KEY = DATA.storageKey;\nlet selectedBlocks;\ntry { const restored=JSON.parse(localStorage.getItem(STORAGE_KEY)||'[]'); selectedBlocks=new Set(restored.filter(Number.isInteger).filter(block=>block>=0&&block<DATA.blockCount)); }\ncatch { selectedBlocks=new Set(); }\nfunction rgb(palette,index){const word=(palette[index*2]<<8)|palette[index*2+1];return[(word&14)*17,((word>>4)&14)*17,((word>>8)&14)*17,255];}\nfunction tileHasPixels(tile){for(let i=tile*32;i<tile*32+32;i++)if(art[i])return true;return false;}\nfunction dependsOnSonic(block){for(let p=0;p<4;p++){const w=words[block*4+p];if(((w>>13)&3)===0&&tileHasPixels(w&0x7ff))return true;}return false;}\nfunction render(canvas,block,which){\n  const ctx=canvas.getContext('2d'),image=ctx.createImageData(16,16),palette=palettes[scenarioSelect.value][which];\n  for(let piece=0;piece<4;piece++){\n    const word=words[block*4+piece],tile=word&0x7ff,xf=!!(word&0x800),yf=!!(word&0x1000),pal=(word>>13)&3;\n    for(let y=0;y<8;y++)for(let x=0;x<8;x++){\n      const sx=xf?7-x:x,sy=yf?7-y:y,packed=art[tile*32+sy*4+(sx>>1)],colour=(sx&1)?packed&15:packed>>4;\n      const [r,g,b,a]=rgb(palette,pal*16+colour),dx=(piece&1)*8+x,dy=(piece>>1)*8+y,pos=(dy*16+dx)*4;\n      image.data[pos]=r;image.data[pos+1]=g;image.data[pos+2]=b;image.data[pos+3]=a;\n    }\n  }\n  ctx.putImageData(image,0,0);\n}\nfunction card(block){\n  const node=document.createElement('article');node.className='card';node.dataset.block=block;node.dataset.hex=block.toString(16).toUpperCase().padStart(3,'0');node.dataset.dec=block;\n  node.innerHTML=`<div class=\"images\"><canvas class=\"normal\" width=\"16\" height=\"16\"></canvas><canvas class=\"super\" width=\"16\" height=\"16\"></canvas></div><div class=\"label\">$${node.dataset.hex} / ${block}</div><div class=\"meta\">${dependsOnSonic(block)?'palette 0':''}</div>`;\n  render(node.querySelector('.normal'),block,'normal');render(node.querySelector('.super'),block,'super');\n  node.onclick=()=>{selectedBlocks.has(block)?selectedBlocks.delete(block):selectedBlocks.add(block);updateSelection();};return node;\n}\nfor(let block=0;block<DATA.blockCount;block++){document.querySelector('#all').append(card(block));if(dependsOnSonic(block))document.querySelector('#dynamic').append(card(block));}\nfunction rerender(){document.querySelectorAll('.card').forEach(node=>{const block=Number(node.dataset.block);render(node.querySelector('.normal'),block,'normal');render(node.querySelector('.super'),block,'super');});}\nfunction selectedValues(){return[...selectedBlocks].sort((a,b)=>a-b);}\nfunction selectedHex(){return selectedValues().map(block=>block.toString(16).toUpperCase().padStart(3,'0'));}\nfunction updateSelection(){document.querySelectorAll('.card').forEach(card=>card.classList.toggle('selected',selectedBlocks.has(Number(card.dataset.block))));const values=selectedHex();document.querySelector('#selected').textContent=`Selected: ${values.length}${values.length?' — $'+values.join(', $'):''}`;localStorage.setItem(STORAGE_KEY,JSON.stringify(selectedValues()));}\ndocument.querySelector('#saveSelection').onclick=()=>{const result={zone:DATA.zone,paletteScenario:scenarioSelect.value,paletteScenarioLabel:palettes[scenarioSelect.value].label,format:'16x16 layout block',blocks:selectedValues().map(block=>({hex:'$'+block.toString(16).toUpperCase().padStart(3,'0'),decimal:block}))};const url=URL.createObjectURL(new Blob([JSON.stringify(result,null,2)+'\\n'],{type:'application/json'}));const link=document.createElement('a');link.href=url;link.download=DATA.slug.toLowerCase()+'_selected_blocks.json';link.click();URL.revokeObjectURL(url);};\ndocument.querySelector('#copySelection').onclick=async()=>{try{await navigator.clipboard.writeText(selectedHex().map(value=>'$'+value).join(', '));}catch{}};\ndocument.querySelector('#clearSelection').onclick=()=>{selectedBlocks.clear();updateSelection();};\ndocument.querySelector('#zoom').oninput=e=>document.documentElement.style.setProperty('--zoom',e.target.value);\ndocument.querySelector('#mode').onchange=e=>document.body.className='mode-'+e.target.value;\ndocument.querySelector('#scenario').onchange=rerender;\ndocument.querySelector('#filter').oninput=e=>{const q=e.target.value.trim().replace(/^\\$/,'').toUpperCase();document.querySelectorAll('.card').forEach(c=>c.classList.toggle('empty',q&&!c.dataset.hex.includes(q)&&!c.dataset.dec.includes(q)));};\nupdateSelection();\n</script>\n</body>\n</html>\n"


def gallery_build(
    zone: str, config: dict, normal_sonic: bytes, super_dry: bytes, super_water: bytes
):
    base_art = nemesis_decode((gallery_ROOT / config["art"]).read_bytes())
    words = gallery_load_blocks(gallery_ROOT / config["map"])
    if len(words) % 8:
        raise ValueError(f"{zone} map16 is not a whole number of blocks")
    block_count = len(words) // 8
    references = [int.from_bytes(words[i : i + 2], "big") & 2047 for i in range(0, len(words), 2)]
    tile_count = max(len(base_art) // 32, max(references) + 1)
    art = bytearray(tile_count * 32)
    art[: len(base_art)] = base_art
    for destination, compression, relative_path, tile_limit in config.get("overlays", []):
        blob = (gallery_ROOT / relative_path).read_bytes()
        overlay = nemesis_decode(blob) if compression == "nemesis" else blob
        if len(overlay) % 32:
            raise ValueError(f"Overlay is not tile-aligned: {relative_path}")
        if tile_limit is not None:
            overlay = overlay[: tile_limit * 32]
        end = destination * 32 + len(overlay)
        if end > len(art):
            art.extend(bytes(end - len(art)))
            tile_count = len(art) // 32
        art[destination * 32 : end] = overlay
    palettes = {}
    for key, label, relative_path in config["palettes"]:
        normal, super_palette = gallery_palette_pair(
            gallery_ROOT / relative_path, normal_sonic, super_dry, super_water
        )
        palettes[key] = {
            "label": label,
            "normal": base64.b64encode(normal).decode(),
            "super": base64.b64encode(super_palette).decode(),
        }
    payload = {
        "zone": config["name"],
        "slug": zone,
        "storageKey": f"{zone.lower()}-layout-gallery-selection-v1",
        "art": base64.b64encode(bytes(art)).decode(),
        "words": base64.b64encode(words).decode(),
        "palettes": palettes,
        "blockCount": block_count,
    }
    page = gallery_HTML.replace("__ZONE__", config["name"]).replace(
        "__DATA__", json.dumps(payload, separators=(",", ":"), ensure_ascii=False)
    )
    target = gallery_OUTPUT / f"{zone}_layout_gallery.html"
    target.write_text(page, encoding="utf-8")
    return (target, block_count, tile_count)


def gallery_write_index(results):
    links = "\n".join(
        (
            f'''<li><a href="{path.name}">{gallery_ZONES[zone]["name"]}</a> — {blocks} blocks, {tiles} tiles</li>'''
            for zone, path, blocks, tiles in results
        )
    )
    page = f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Galleries layout</title><style>color-scheme:dark;body{{font:18px Segoe UI,sans-serif;max-width:900px;margin:40px auto;padding:0 24px;background:#111218;color:#f4f4f5}}a{{color:#a99cff}}li{{margin:14px 0}}</style></head><body><h1>Level block galleries</h1><ul>{links}</ul></body></html>'
    (gallery_OUTPUT / "level_layout_galleries.html").write_text(page, encoding="utf-8")


def gallery_main():
    parser = argparse.ArgumentParser()
    parser.add_argument("zones", nargs="*", choices=gallery_ZONES, default=list(gallery_ZONES))
    args = parser.parse_args()
    gallery_OUTPUT.mkdir(exist_ok=True)
    normal_sonic = (gallery_ROOT / "palette/Sonic.bin").read_bytes()
    if len(normal_sonic) != 32:
        raise ValueError("Sonic palette must contain one line")
    super_dry = gallery_asm_palette("Pal_SuperSonic")
    super_water = gallery_asm_palette("Pal_SuperSonicWater")
    results = []
    for zone in args.zones:
        path, blocks, tiles = gallery_build(
            zone, gallery_ZONES[zone], normal_sonic, super_dry, super_water
        )
        results.append((zone, path, blocks, tiles))
        print(f"{zone}: {blocks} blocks, {tiles} tiles -> {path.relative_to(gallery_ROOT)}")
    gallery_write_index(results)


blocks_REVISIONS = (0, 1)


@dataclass
class blocks_Consumer:
    name: str
    blocks: str
    chunks: str | None
    art: tuple[tuple[str, int], ...] = ()
    note: str = ""
    revisions: tuple[int, ...] = blocks_REVISIONS

    @property
    def label(self) -> str:
        if self.revisions == blocks_REVISIONS:
            return self.name
        return f"{self.name} [" + "/".join(f"REV{r:02d}" for r in self.revisions) + "]"


def blocks_revision_condition(condition: str, revision: int) -> bool:
    """Evaluate a simple 'if Revision...' condition (=, <>, <, >, &, |) for one revision."""
    expression = condition.replace("<>", "!=").replace("=", "==").replace("!==", "!=")
    expression = (
        expression.replace("<==", "<=")
        .replace(">==", ">=")
        .replace("&", " and ")
        .replace("|", " or ")
    )
    if not re.fullmatch("[\\sRevision0-9!=<>()andor]+", expression):
        raise ValueError(f"Unsupported condition: if {condition}")
    return bool(eval(expression, {"__builtins__": {}}, {"Revision": revision}))


def blocks_binclude_labels(text: str) -> dict[str, dict[int, str]]:
    """Label -> {revision: path}; handles 'label: binclude' and a label followed by
    'if Revision...' / 'else' / 'endif' branches containing the binclude."""
    labels: dict[str, dict[int, str]] = {}
    lines = text.splitlines()
    for index, line in enumerate(lines):
        m = re.match('^(\\w+):\\s*(?:binclude\\s+\\"([^\\"]+)\\")?\\s*(?:;.*)?$', line)
        if not m:
            continue
        label, path = (m.group(1), m.group(2))
        if path:
            labels[label] = {r: path for r in blocks_REVISIONS}
            continue
        found: dict[int, str] = {}
        active = {r: True for r in blocks_REVISIONS}
        taken = {r: False for r in blocks_REVISIONS}
        depth = 0
        for follow in lines[index + 1 :]:
            stripped = follow.split(";")[0].strip()
            if re.match("^\\w+:", follow) or (depth == 0 and (not stripped) and found):
                break
            conditional = re.match("^(if|elseif)\\s+(.+)$", stripped)
            if conditional and set(re.findall("[A-Za-z_]\\w*", conditional.group(2))) != {
                "Revision"
            }:
                found = {}
                break
            if conditional and conditional.group(1) == "if":
                depth += 1
                for r in blocks_REVISIONS:
                    taken[r] = blocks_revision_condition(conditional.group(2), r)
                    active[r] = taken[r]
            elif conditional:
                for r in blocks_REVISIONS:
                    active[r] = not taken[r] and blocks_revision_condition(conditional.group(2), r)
                    taken[r] = taken[r] or active[r]
            elif stripped == "else":
                for r in blocks_REVISIONS:
                    active[r] = not taken[r]
            elif stripped == "endif":
                depth -= 1
                active = {r: True for r in blocks_REVISIONS}
                if depth == 0:
                    break
            elif m2 := re.match('^binclude\\s+\\"([^\\"]+)\\"', stripped):
                for r in blocks_REVISIONS:
                    if active[r]:
                        found.setdefault(r, m2.group(1))
            elif stripped and stripped != "even" and (depth == 0):
                break
        if found:
            labels[label] = found
    return labels


chunks_LOOP_CHUNK_ID, chunks_LOOP_REPLACEMENT_ID = (40, 81)
chunks_ZONE_ENDING, chunks_ACT_TITLE = (6, 3)


objects_ROOT = get_root()
objects_SONIC = objects_ROOT / "sonic.asm"
objects_POINTERS = objects_ROOT / "_inc/Object Pointers.asm"
objects_OUT = objects_ROOT / "tmp/object_snapshot"
objects_ZONES = ["GHZ", "LZ", "MZ", "SLZ", "SYZ", "SBZ", "Ending"]
objects_SPECIAL_ACT_NAMES = {("LZ", 4): "SBZ3", ("SBZ", 3): "FZ"}
objects_S3K_RESPAWN_ENTRIES = 768
objects_S3K_MAX_RINGS = 512
objects_RING_TERMINATOR = bytes.fromhex("FFFFFFFF")
objects_RING_POS = [
    (16, 0),
    (24, 0),
    (32, 0),
    (0, 16),
    (0, 24),
    (0, 32),
    (16, 16),
    (24, 24),
    (32, 32),
    (-16, 16),
    (-24, 24),
    (-32, 32),
    (16, 8),
    (24, 16),
    (-16, 8),
    (-24, 16),
]
objects_failures: list[str] = []
objects_warnings: list[str] = []


def objects_fail(message: str) -> None:
    objects_failures.append(message)
    print(f"  FAIL {message}")


def objects_warn(message: str) -> None:
    objects_warnings.append(message)
    print(f"  WARN {message}")


def objects_object_names() -> dict[int, str]:
    names = {}
    for m in re.finditer(
        "^id_(\\w+):\\s+objptr\\s+(\\w+)\\s*;\\s*([0-9A-Fa-f]{2})",
        objects_POINTERS.read_text(encoding="utf-8"),
        re.M,
    ):
        names[int(m.group(3), 16)] = (
            m.group(2) if m.group(2) != "NullObject" else f"NullObject({m.group(1)})"
        )
    return names


def objects_index_rows(sonic: str, label: str, stop: str) -> list[tuple[str, str]]:
    body = re.search(f"^{label}:(.*?)^{stop}", sonic, re.M | re.S).group(1)
    return re.findall("dc\\.w\\s+(\\w+)-ObjPos_Index,\\s*(\\w+)-ObjPos_Index", body)


def objects_decode_objpos(blob: bytes) -> list[dict]:
    if len(blob) % 6:
        raise ValueError(f"objpos length {len(blob)} is not a multiple of 6")
    entries = []
    for i in range(0, len(blob), 6):
        x = int.from_bytes(blob[i : i + 2], "big")
        if x == 65535:
            if i != len(blob) - 6 or blob[i + 2 : i + 6] != bytes(4):
                raise ValueError("objpos terminator is not the final zero-filled record")
            return entries
        yraw = int.from_bytes(blob[i + 2 : i + 4], "big")
        entries.append(
            {
                "x": x,
                "y": yraw & 4095,
                "xflip": yraw >> 14 & 1,
                "yflip": yraw >> 15 & 1,
                "ybits12_13": yraw >> 12 & 3,
                "id": blob[i + 4] & 127,
                "remember": blob[i + 4] >> 7,
                "subtype": blob[i + 5],
            }
        )
    raise ValueError("objpos terminator missing")


def objects_decode_ring_layout(blob: bytes, name: str) -> list[tuple[int, int]]:
    if len(blob) % 4 or blob[-4:] != objects_RING_TERMINATOR:
        raise ValueError(f"{name}: invalid S3K ring sentinel or stride")
    rings = [
        (int.from_bytes(blob[i : i + 2], "big"), int.from_bytes(blob[i + 2 : i + 4], "big"))
        for i in range(0, len(blob) - 4, 4)
    ]
    if any((x == 65535 or y >= 4096 for x, y in rings)):
        raise ValueError(f"{name}: invalid ring coordinate")
    if rings != sorted(rings):
        raise ValueError(f"{name}: rings not sorted by X/Y")
    return rings


def objects_decode_platforms(blob: bytes) -> list[dict]:
    count = int.from_bytes(blob[0:2], "big") + 1
    return [
        {
            "x": int.from_bytes(blob[2 + i * 6 : 4 + i * 6], "big"),
            "y": int.from_bytes(blob[4 + i * 6 : 6 + i * 6], "big"),
            "subtype": int.from_bytes(blob[6 + i * 6 : 8 + i * 6], "big"),
        }
        for i in range(count)
    ]


def objects_expand_rings(entry: dict) -> list[tuple[int, int]]:
    """Positions of the rings Ring_Main spawns for one ring group object."""
    count = min((entry["subtype"] & 7) + 1, 7)
    dx, dy = objects_RING_POS[entry["subtype"] >> 4]
    return [(entry["x"] + dx * n, entry["y"] + dy * n) for n in range(count)]


def objects_act_name(zone: str, act: int) -> str:
    return objects_SPECIAL_ACT_NAMES.get((zone, act), f"{zone}{act}")


def objects_audit_act(
    name: str, path: str, entries: list[dict], names: dict[int, str], ids: dict[str, int]
) -> dict:
    print(f"\n== {name}: {path} ==")
    remember = sum(e["remember"] for e in entries)
    rings = [e for e in entries if e["id"] == ids.get("Rings")]
    expanded = [p for e in rings for p in objects_expand_rings(e)]
    ring_path = objects_ROOT / "objpos/Rings" / Path(path).name
    if ring_path.exists():
        if rings:
            objects_fail(f"{name}: object ring groups and separate ring file coexist")
        expanded = objects_decode_ring_layout(ring_path.read_bytes(), str(ring_path))
    print(
        f"  {len(entries)} objects, {remember} with remember flag, {len(rings)} ring groups -> {len(expanded)} rings"
    )
    if len(entries) > objects_S3K_RESPAWN_ENTRIES:
        objects_fail(
            f"{name}: {len(entries)} objects exceed the S3K respawn table (${objects_S3K_RESPAWN_ENTRIES:X})"
        )
    if len(expanded) > objects_S3K_MAX_RINGS:
        objects_warn(
            f"{name}: {len(expanded)} rings exceed the S3K Rings Manager's {objects_S3K_MAX_RINGS} states"
        )
    unsorted = [i for i in range(1, len(entries)) if entries[i]["x"] < entries[i - 1]["x"]]
    if unsorted:
        objects_fail(f"{name}: objects not sorted by X at entries {unsorted[:10]}")
    ring_order = sorted(expanded)
    if expanded and [p[0] for p in expanded] != [p[0] for p in ring_order]:
        print(
            "  info: expanded rings are not in X order as stored (a ring layout must be sorted on conversion)"
        )
    for e in entries:
        label = names.get(e["id"])
        where = f"({e['x']:04X},{e['y']:03X}) id ${e['id']:02X} sub ${e['subtype']:02X}"
        if label is None:
            objects_fail(f"{name}: unknown object ID at {where}")
        elif label.startswith("NullObject"):
            objects_warn(f"{name}: NullObject at {where}")
        if e["ybits12_13"]:
            objects_fail(f"{name}: Y bits 12-13 set at {where}")
        if e["x"] == 0 and e["y"] == 0:
            if e["id"] != ids.get("Pylon"):
                objects_warn(
                    f"{name}: object at (0,0): {label} {where} (may need a Y-window exemption)"
                )
    giant = [e for e in entries if e["id"] == ids.get("GiantRing")]
    for e in giant:
        print(
            f"  giant ring ({e['x']:04X},{e['y']:03X}) subtype ${e['subtype']:02X} remember={e['remember']}"
        )
        if e["subtype"] > 2:
            objects_warn(f"{name}: giant ring subtype ${e['subtype']:02X} is not 0/1/2")
    free = [e["subtype"] for e in giant if e["subtype"]]
    if len(free) != len(set(free)):
        objects_warn(
            f"{name}: duplicate free giant ring subtypes {free} (they share a v_midring_flags bit)"
        )
    for key in ("Lamppost", "Splats"):
        for e in entries:
            if e["id"] == ids.get(key):
                print(
                    f"  {key} ({e['x']:04X},{e['y']:03X}) subtype ${e['subtype']:02X} remember={e['remember']}"
                )
    return {
        "path": path,
        "objects": entries,
        "rings_expanded": expanded,
        "counts": {
            "objects": len(entries),
            "remember": remember,
            "ring_groups": len(rings),
            "rings": len(expanded),
            "giant_rings": len(giant),
        },
    }


def objects_compare(old: dict, new: dict) -> int:
    differences = 0
    for key in sorted(set(old) | set(new)):
        a, b = (old.get(key), new.get(key))
        if a is None or b is None:
            print(f"  DIFF {key}: {('missing in old' if a is None else 'missing in new')}")
            differences += 1
            continue
        if a.get("platforms") != b.get("platforms"):
            print(f"  DIFF {key}: platforms differ")
            differences += 1
        if "objects" in a and "objects" in b:

            def preserved_counts(item: dict) -> tuple[int, int, int, int]:
                remaining = [e for e in item["objects"] if e["id"] != 37]
                return (
                    len(remaining),
                    sum(e["remember"] for e in remaining),
                    item["counts"]["giant_rings"],
                    item["counts"]["rings"],
                )

            if preserved_counts(a) != preserved_counts(b):
                print(f"  DIFF {key}: non-ring counts differ")
                differences += 1
        elif a.get("counts") != b.get("counts"):
            print(f"  DIFF {key}: counts differ")
            differences += 1
        if sorted(map(tuple, a.get("rings_expanded", []))) != sorted(
            map(tuple, b.get("rings_expanded", []))
        ):
            print(f"  DIFF {key}: expanded ring positions differ")
            differences += 1
        old_objects = [e for e in a.get("objects", []) if e["id"] != 37]
        new_objects = [e for e in b.get("objects", []) if e["id"] != 37]

        def canonical(records):
            return sorted(json.dumps(item, sort_keys=True) for item in records)

        if canonical(old_objects) != canonical(new_objects):
            print(f"  DIFF {key}: object placements differ")
            differences += 1
    print(f"Compare: {differences} difference(s)")
    return 1 if differences else 0


def objects_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--write", action="store_true", help="write tmp/object_snapshot/objects.json"
    )
    parser.add_argument("--compare", type=Path, help="compare with a saved objects.json")
    args = parser.parse_args(argv)
    sonic = objects_SONIC.read_text(encoding="utf-8")
    labels = blocks_binclude_labels(sonic)
    names = objects_object_names()
    ids = {name: number for number, name in names.items()}
    rows = objects_index_rows(sonic, "ObjPos_Index", "ObjPosLZPlatform_Index:")
    if len(rows) != len(objects_ZONES) * 4:
        objects_fail(f"ObjPos_Index has {len(rows)} rows (expected {len(objects_ZONES) * 4})")
    snapshot: dict[str, dict] = {}
    for revision in blocks_REVISIONS:
        audited: dict[str, str] = {}
        for row, (primary, secondary) in enumerate(rows):
            zone, act = (objects_ZONES[row // 4], row % 4 + 1)
            name = objects_act_name(zone, act)
            key = f"{name} [REV{revision:02d}]"
            path = labels.get(primary, {}).get(revision)
            if path is None:
                objects_fail(f"{key}: no binclude for {primary}")
                continue
            if secondary != "ObjPos_Null":
                objects_warn(f"{key}: secondary list {secondary} is not ObjPos_Null (not audited)")
            if path in audited:
                print(f"\n== {key}: same list as {audited[path]} ==")
                snapshot[key] = snapshot[audited[path]]
                continue
            audited[path] = key
            other = f"{name} [REV{1 - revision:02d}]"
            if other in snapshot and snapshot[other]["path"] == path:
                snapshot[key] = snapshot[other]
                continue
            snapshot[key] = objects_audit_act(
                key, path, objects_decode_objpos((objects_ROOT / path).read_bytes()), names, ids
            )
    print("\n== Conveyor platform lists ==")
    for label, stop in (
        ("ObjPosLZPlatform_Index", "ObjPosSBZPlatform_Index:"),
        ("ObjPosSBZPlatform_Index", "\\s+dc\\.b\\s+\\$FF"),
    ):
        for pair in objects_index_rows(sonic, label, stop):
            for platform_label in pair:
                path = labels[platform_label][blocks_REVISIONS[-1]]
                key = f"platforms {Path(path).stem}"
                if key not in snapshot:
                    platforms = objects_decode_platforms((objects_ROOT / path).read_bytes())
                    snapshot[key] = {
                        "path": path,
                        "platforms": platforms,
                        "counts": {"platforms": len(platforms)},
                    }
                    print(f"  {path}: {len(platforms)} platforms")
    print("\n== Summary ==")
    acts = [v for k, v in snapshot.items() if "objects" in v]
    unique = {id(v): v for v in acts}.values()
    print(
        f"  {len(unique)} distinct act layouts; max objects {max(v['counts']['objects'] for v in unique)}, max remember flags {max(v['counts']['remember'] for v in unique)}, max rings {max(v['counts']['rings'] for v in unique)} (S3K limit {objects_S3K_MAX_RINGS})"
    )
    result = 1 if objects_failures else 0
    if args.compare:
        print(f"\n== Compare with {args.compare} ==")
        result |= objects_compare(json.loads(args.compare.read_text(encoding="utf-8")), snapshot)
    if args.write:
        objects_OUT.mkdir(parents=True, exist_ok=True)
        (objects_OUT / "objects.json").write_text(
            json.dumps(snapshot, indent=1, sort_keys=True) + "\n", encoding="utf-8"
        )
        print(f"\nWrote {objects_OUT.relative_to(objects_ROOT).as_posix()}/objects.json")
    print(f"Result: {len(objects_failures)} failure(s), {len(objects_warnings)} warning(s)")
    return result


rings_ROOT = get_root()
rings_OBJPOS = rings_ROOT / "objpos"
rings_OBJECT_TERMINATOR = bytes.fromhex("FFFF00000000")
rings_RING_TERMINATOR = bytes.fromhex("FFFFFFFF")
rings_RING_ID = 37


def rings_split(blob: bytes, name: str) -> tuple[bytes, bytes, int, int]:
    entries = objects_decode_objpos(blob)
    records = [blob[i : i + 6] for i in range(0, len(blob) - 6, 6)]
    if len(entries) != len(records) or blob[-6:] != rings_OBJECT_TERMINATOR:
        raise ValueError(f"{name}: unexpected object record layout")
    object_records: list[bytes] = []
    rings: list[tuple[int, int]] = []
    groups = 0
    for entry, record in zip(entries, records, strict=False):
        if entry["id"] == rings_RING_ID:
            groups += 1
            rings.extend(objects_expand_rings(entry))
        else:
            object_records.append(record)
    if any((not 0 <= x < 65535 or not 0 <= y < 4096 for x, y in rings)):
        raise ValueError(f"{name}: expanded ring outside representable S3K range")
    rings.sort()
    if len(rings) > 512:
        raise ValueError(f"{name}: {len(rings)} rings exceed 512 states")
    objects_out = b"".join(object_records) + rings_OBJECT_TERMINATOR
    rings_out = b"".join((struct.pack(">HH", x, y) for x, y in rings)) + rings_RING_TERMINATOR
    if len(object_records) + groups != len(records):
        raise AssertionError(f"{name}: lost an object")
    if [r for r in records if r[4] & 127 != rings_RING_ID] != object_records:
        raise AssertionError(f"{name}: non-ring record changed")
    return (objects_out, rings_out, groups, len(rings))


def rings_main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--output-dir", type=Path, help="write a preview outside objpos")
    mode.add_argument("--apply", action="store_true", help="write objpos and objpos/Rings")
    parser.add_argument("--input-dir", type=Path, help="source object lists before ring separation")
    args = parser.parse_args()
    if args.output_dir and args.output_dir.exists() and any(args.output_dir.iterdir()):
        raise ValueError("Output directory must be empty")
    sources = sorted((args.input_dir or rings_OBJPOS).glob("*.bin"))
    if not sources:
        raise SystemExit("no objpos/*.bin files found")
    plans = [(source, *rings_split(source.read_bytes(), source.name)) for source in sources]
    object_dir = rings_OBJPOS if args.apply else args.output_dir / "objects"
    ring_dir = rings_OBJPOS / "Rings" if args.apply else args.output_dir / "rings"
    if args.apply and ring_dir.exists():
        raise SystemExit("objpos/Rings already exists; refusing a second conversion")
    object_dir.mkdir(parents=True, exist_ok=True)
    ring_dir.mkdir(parents=True, exist_ok=True)
    total_groups = total_rings = 0
    for source, objects, rings, groups, count in plans:
        (object_dir / source.name).write_bytes(objects)
        (ring_dir / source.name).write_bytes(rings)
        total_groups += groups
        total_rings += count
        print(f"{source.name}: {groups} groups -> {count} rings")
    print(f"{len(plans)} layouts; {total_groups} groups -> {total_rings} rings")
    return 0


giant_ROOT = get_root()
giant_OBJECTS = giant_ROOT / "objpos"
giant_TERMINATOR = b"\xff\xff\x00\x00\x00\x00"


def giant_ring_types(path: Path) -> Counter[int]:
    data = path.read_bytes()
    if len(data) % 6 or not data.endswith(giant_TERMINATOR):
        raise ValueError(f"Invalid object layout: {path}")
    records = [data[i : i + 6] for i in range(0, len(data) - 6, 6)]
    xs = [int.from_bytes(r[:2], "big") for r in records]
    if xs != sorted(xs):
        raise ValueError(f"Object layout must be sorted by X: {path}")
    result = Counter(r[5] for r in records if r[4] & 127 == 75)
    if result.keys() - {0, 1, 2}:
        raise ValueError(f"Unknown giant-ring subtype: {path}: {dict(result)}")
    return result


def giant_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--original-counts",
        action="store_true",
        help="also enforce the original automatic placement counts, before manual edits",
    )
    args = parser.parse_args()
    layouts = 0
    for zone in ("ghz", "lz", "mz", "slz", "syz", "sbz"):
        for act in (1, 2, 3):
            paths = sorted(giant_OBJECTS.glob(f"{zone}{act}*.bin"))
            if not paths:
                raise ValueError(f"No object layouts for {zone.upper()}{act}")
            expected = Counter({1: 1, 2: 1} if act == 3 else {0: 1, 1: 1})
            if zone == "syz" and act == 2:
                expected[0] = 2
            for path in paths:
                actual = giant_ring_types(path)
                if args.original_counts and actual != expected:
                    raise ValueError(f"{path.name}: {dict(actual)}, expected {dict(expected)}")
                print(f"{path.name}: {dict(actual)}")
                layouts += 1
    final = giant_ring_types(giant_OBJECTS / "fz.bin")
    if final:
        raise ValueError(f"Final Zone must have no giant rings: {dict(final)}")
    print(f"Giant-ring data valid in {layouts} act layouts; Final Zone has none")


def validate_maps(kind: str, argv: list[str]) -> int:
    """Validate runtime map resources or decode supplied source mappings."""
    from s1tools.sonlvl import sync_resources, sync_sync

    parser = argparse.ArgumentParser(description=validate_maps.__doc__)
    parser.add_argument(
        "--convert", type=Path, help="source mapping directory; writes require --output-dir"
    )
    parser.add_argument(
        "--output-dir", type=Path, help="empty destination for decoded source files"
    )
    args = parser.parse_args(argv)
    if args.convert:
        if not args.output_dir:
            parser.error("--convert requires --output-dir")
        suffix, decode = (
            (".eni", enigma_decode_bytes) if kind == "blocks" else (".kos", kosinski_decode)
        )
        inputs = sorted(args.convert.glob("*" + suffix))
        if not inputs:
            parser.error(f"No {suffix} source files")
        if args.output_dir.exists() and any(args.output_dir.iterdir()):
            parser.error("Output directory must be empty")
        outputs = {p.with_suffix(".bin").name: decode(p.read_bytes()) for p in inputs}
        args.output_dir.mkdir(parents=True, exist_ok=True)
        for name, data in outputs.items():
            (args.output_dir / name).write_bytes(data)
        print(f"Decoded {len(outputs)} mapping files")
        return 0
    if args.output_dir:
        parser.error("--output-dir requires --convert")
    root = get_root()
    count, differences = sync_sync(root)
    if differences:
        raise ValueError("SonLVL resource references differ: " + ", ".join(differences))
    seen = set()
    for revision in (0, 1):
        rows = sync_resources(root, revision)
        rows["Title"] = {"blocks": "../../map16/Title.bin", "chunks": "../../map256/Title.bin"}
        for name, resource in rows.items():
            paths = {k: root / resource[k].removeprefix("../../") for k in ("blocks", "chunks")}
            key = (paths["blocks"], paths["chunks"])
            if key in seen:
                continue
            seen.add(key)
            blocks = paths["blocks"].read_bytes()
            chunks = paths["chunks"].read_bytes()
            if not blocks or len(blocks) % 8 or len(blocks) > 0x400 * 8:
                raise ValueError(f"Invalid block length: {paths['blocks']}")
            if not chunks or len(chunks) % 512 or len(chunks) > 0x80 * 512:
                raise ValueError(f"Invalid chunk length: {paths['chunks']}")
            entries = [
                int.from_bytes(chunks[i : i + 2], "big") & 0x3FF for i in range(0, len(chunks), 2)
            ]
            if max(entries) >= len(blocks) // 8:
                raise ValueError(f"Chunk references missing block: {name}")
            print(f"{name}: {len(blocks) // 8} blocks, {len(chunks) // 512} chunks")
    print(f"Validated {len(seen)} mapping pairs and {count} editor sections")
    return 0


def blocks_main(argv: list[str]) -> int:
    return validate_maps("blocks", argv)


def chunks_main(argv: list[str]) -> int:
    return validate_maps("chunks", argv)
