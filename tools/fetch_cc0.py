"""โหลดแอสเซต CC0 เข้าโปรเจกต์ และจดที่มา/ลิขสิทธิ์ลง game/assets/CREDITS.csv

รัน: python tools/fetch_cc0.py
- Poly Haven (โมเดล, CC0, API ใช้ได้ทุกจุดประสงค์ แต่ต้องให้เครดิต Poly Haven)
- ambientCG (พื้นผิว, CC0)
- Kenney (เสียง, CC0)
- OpenGameArt (เฉพาะหน้าที่ระบุ CC0 เท่านั้น ถ้าไม่ใช่จะข้าม)
- Quaternius Universal Animation Library (CC0, ผ่าน OpenGameArt)
ไฟล์ที่มีอยู่แล้วจะไม่โหลดซ้ำ
"""
import csv
import datetime
import io
import json
import re
import sys
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "game" / "assets"
CREDITS = ROOT / "CREDITS.csv"
UA = {"User-Agent": "HorrorRitual-asset-fetch/1.0"}
TODAY = datetime.date.today().isoformat()

POLYHAVEN_MODELS = [
    # เฟอร์นิเจอร์ (ห้อง ห้องนอน ห้องเรียน ห้องผู้หญิงแบบ Lady)
    "WoodenTable_01", "WoodenTable_02", "dining_table", "painted_wooden_chair_01", "painted_wooden_chair_02",
    "painted_wooden_table", "painted_wooden_cabinet", "painted_wooden_shelves", "painted_wooden_nightstand",
    "GothicBed_01", "GothicCabinet_01", "vintage_day_bed", "wooden_bookshelf_worn", "steel_frame_shelves_01",
    "Shelf_01", "SchoolDesk_01", "SchoolChair_01", "ornate_mirror_01", "chinese_screen_panels", "metal_stool_01",
    "wooden_display_shelves_01",
    # ครัวและโต๊ะอาหาร
    "pot_enamel_01", "brass_pot_01", "brass_pan_01", "wooden_bowl_02", "wooden_spoon", "carved_wooden_plate",
    "jug_01", "ceramic_pot", "wooden_cutting_board", "russian_food_cans_01", "can_rusted", "electric_stove",
    "wooden_bucket_01", "Barrel_01", "barrel_03", "wooden_crate_01", "wooden_crate_02", "cardboard_box_01",
    "CheeseBox_01",
    # อุตสาหกรรม ไฟ และของ analog
    "modular_industrial_pipes_01", "modular_airduct_rectangular_01", "hanging_industrial_lamp", "industrial_wall_lamp",
    "caged_hanging_light", "mounted_fluorescent_lights", "old_gas_mask", "worn_metal_rack", "metal_trash_can",
    "rollershutter_door", "vintage_oil_lamp", "Lantern_01", "wooden_candlestick", "lightbulb_01", "wall_clock",
    "vintage_grandfather_clock_01", "filmstrip_projector_8mm", "vintage_video_camera",
]

AMBIENTCG = [
    "WoodFloor051", "WoodFloor043", "Planks037A", "Metal063", "Metal053B", "MetalWalkway014", "PaintedMetal004",
    "Concrete034", "Concrete047A", "Tiles139", "Tiles141", "Wallpaper001A", "Wallpaper002A", "Carpet016",
    "Fabric061", "Plaster001", "PaintedPlaster017", "Bricks097", "CorrugatedSteel007A", "Leather037",
    "Grass004",
]

KENNEY = ["impact-sounds", "rpg-audio"]

# ท้องฟ้า (HDRI แบบ puresky = มีแต่ท้องฟ้า ไม่มีพื้น) ขนาด 2k
POLYHAVEN_HDRIS = ["kloofendal_48d_partly_cloudy_puresky"]

OGA_PAGES = [
    "https://opengameart.org/content/universal-animation-library",
    "https://opengameart.org/content/paranoid-truth",
    "https://opengameart.org/content/abandoned-passages-horror-ambience-loop",
    "https://opengameart.org/content/dark-ambience-loop",
    "https://opengameart.org/content/searching",
    "https://opengameart.org/node/119234",
    "https://opengameart.org/node/5740",
    "https://opengameart.org/node/10684",
]


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def save(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def credit(rows: list, name: str, kind: str, source: str, url: str, author: str, license_: str, path: Path) -> None:
    rows.append({"name": name, "type": kind, "source": source, "url": url, "author": author,
                 "license": license_, "path": path.relative_to(ROOT.parent).as_posix(), "downloaded": TODAY})


def fetch_polyhaven(rows: list) -> None:
    for asset_id in POLYHAVEN_MODELS:
      try:
        folder = ROOT / "models" / "polyhaven" / asset_id
        info = json.loads(get(f"https://api.polyhaven.com/info/{asset_id}"))
        files = json.loads(get(f"https://api.polyhaven.com/files/{asset_id}"))
        gltf = files["gltf"]["1k"]["gltf"]
        main = folder / Path(urllib.parse.urlparse(gltf["url"]).path).name
        if not main.exists():
            save(main, get(gltf["url"]))
            for rel, inc in gltf.get("include", {}).items():
                save(folder / rel, get(inc["url"]))
        authors = ", ".join(info.get("authors", {}).keys())
        credit(rows, info.get("name", asset_id), "model", "Poly Haven", f"https://polyhaven.com/a/{asset_id}",
               authors, "CC0", main)
        print("polyhaven", asset_id)
      except Exception as e:
        print("ERROR polyhaven", asset_id, e, file=sys.stderr)


def fetch_hdris(rows: list) -> None:
    for asset_id in POLYHAVEN_HDRIS:
        folder = ROOT / "skies" / "polyhaven"
        info = json.loads(get(f"https://api.polyhaven.com/info/{asset_id}"))
        files = json.loads(get(f"https://api.polyhaven.com/files/{asset_id}"))
        hdr = files["hdri"]["2k"]["hdr"]
        target = folder / f"{asset_id}_2k.hdr"
        if not target.exists():
            save(target, get(hdr["url"]))
        authors = ", ".join(info.get("authors", {}).keys())
        credit(rows, info.get("name", asset_id), "sky", "Poly Haven", f"https://polyhaven.com/a/{asset_id}", authors, "CC0", target)
        print("hdri", asset_id)


def fetch_ambientcg(rows: list) -> None:
    for asset_id in AMBIENTCG:
        folder = ROOT / "textures" / "ambientcg" / asset_id
        if not folder.exists():
            data = get(f"https://ambientcg.com/get?file={asset_id}_1K-JPG.zip")
            with zipfile.ZipFile(io.BytesIO(data)) as z:
                for n in z.namelist():
                    if n.lower().endswith((".jpg", ".png")) and "preview" not in n.lower():
                        save(folder / Path(n).name, z.read(n))
        credit(rows, asset_id, "texture", "ambientCG", f"https://ambientcg.com/view?id={asset_id}",
               "ambientCG (Lennart Demes)", "CC0", folder)
        print("ambientcg", asset_id)


def fetch_kenney(rows: list) -> None:
    for pack in KENNEY:
        folder = ROOT / "audio" / "kenney" / pack
        page = get(f"https://kenney.nl/assets/{pack}").decode("utf-8", "ignore")
        m = re.search(r'https://kenney\.nl/media/pages/assets/[^"]+\.zip', page)
        if not m:
            print("kenney: no zip link for", pack)
            continue
        if not folder.exists():
            with zipfile.ZipFile(io.BytesIO(get(m.group(0)))) as z:
                for n in z.namelist():
                    if n.lower().endswith((".ogg", ".wav", ".txt")):
                        save(folder / Path(n).name, z.read(n))
        credit(rows, pack, "audio", "Kenney", f"https://kenney.nl/assets/{pack}", "Kenney", "CC0", folder)
        print("kenney", pack)


def fetch_oga(rows: list) -> None:
    for page_url in OGA_PAGES:
        html = get(page_url).decode("utf-8", "ignore")
        title_m = re.search(r"<title>(.*?)\s*\|", html)
        title = title_m.group(1).strip() if title_m else page_url
        lic_block = html[html.find("License(s)"):html.find("License(s)") + 600] if "License(s)" in html else ""
        if "cc0" not in lic_block.lower() and "CC0" not in lic_block:
            print("OGA skip (not CC0):", title)
            continue
        author_m = re.search(r'Author:.*?<a href="/users/[^"]+">([^<]+)</a>', html, re.S)
        author = author_m.group(1) if author_m else "unknown"
        links = sorted(set(re.findall(r'https://opengameart\.org/sites/default/files/[^"\']+', html)))
        links = [l for l in links if l.lower().endswith((".zip", ".ogg", ".wav", ".mp3", ".flac", ".glb", ".gltf"))]
        safe = re.sub(r"[^A-Za-z0-9_-]+", "_", title)[:60]
        kind = "animation" if "animation" in title.lower() else "audio"
        folder = ROOT / ("models" if kind == "animation" else "audio") / "opengameart" / safe
        for link in links:
            fname = urllib.parse.unquote(Path(urllib.parse.urlparse(link).path).name)
            target = folder / fname
            if not target.exists():
                data = get(link)
                if fname.lower().endswith(".zip"):
                    with zipfile.ZipFile(io.BytesIO(data)) as z:
                        z.extractall(folder)
                    target.write_text("extracted")
                else:
                    save(target, data)
        credit(rows, title, kind, "OpenGameArt", page_url, author, "CC0", folder)
        print("oga", title, len(links), "files")


def main() -> None:
    rows: list = []
    for step in (fetch_polyhaven, fetch_hdris, fetch_ambientcg, fetch_kenney, fetch_oga):
        try:
            step(rows)
        except Exception as e:  # โหลดไม่ได้ไม่ให้พังทั้งหมด แต่บอกให้รู้
            print("ERROR in", step.__name__, e, file=sys.stderr)
    CREDITS.parent.mkdir(parents=True, exist_ok=True)
    with CREDITS.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["name", "type", "source", "url", "author", "license", "path", "downloaded"])
        w.writeheader()
        w.writerows(rows)
    print("CREDITS rows:", len(rows))


if __name__ == "__main__":
    main()
