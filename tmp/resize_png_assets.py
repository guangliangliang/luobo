from __future__ import annotations

import shutil
from datetime import datetime
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "新建游戏项目"
ASSETS = PROJECT / "assets"
BACKUP = ROOT / "tmp" / ("png_backup_" + datetime.now().strftime("%Y%m%d_%H%M%S"))


def rel(path: Path) -> str:
    return path.relative_to(PROJECT).as_posix()


def resize_to(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    if img.size == size:
        return img.copy()
    return img.resize(size, Image.Resampling.LANCZOS)


def resize_max(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    w, h = img.size
    scale = min(max_w / w, max_h / h, 1.0)
    size = (max(1, round(w * scale)), max(1, round(h * scale)))
    return resize_to(img, size)


def target_image(path: Path, img: Image.Image) -> Image.Image | None:
    r = rel(path)
    name = path.name

    if r == "assets/ui/menu/loading_icon_sheet.png":
        return img.crop((0, 0, min(512, img.width), min(128, img.height)))

    if r == "assets/ui/menu/menu_bg_village.png":
        return resize_to(img, (1280, 720))

    if r == "assets/ui/menu/logo_village_defense.png":
        return resize_to(img, (768, 512))

    if r.startswith("assets/ui/buttons/button_menu_"):
        return resize_to(img, (768, 512))

    if r.startswith("assets/maps/background/"):
        return resize_to(img, (1280, 720))

    if r == "assets/maps/build_spots/build_spot_base.png":
        return resize_to(img, (1024, 576))

    if r.startswith("assets/maps/village/"):
        return resize_max(img, 768, 768)

    if r.startswith("assets/monsters/"):
        if name.endswith("_sheet.png"):
            return resize_to(img, (1024, 576))
        if name.endswith("_icon.png"):
            return resize_max(img, 256, 256)

    if r.startswith("assets/towers/"):
        return resize_max(img, 512, 512)

    if r.startswith("assets/effects/projectiles/"):
        return resize_to(img, (1024, 576))

    if r.startswith("assets/effects/") and name.endswith("_sheet.png"):
        return resize_to(img, (1024, 576))

    if r.startswith("assets/ui/icons/"):
        return resize_max(img, 512, 512)

    if r.startswith("assets/ui/level_select/"):
        return resize_max(img, 512, 512)

    return None


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if img.mode not in ("RGBA", "RGB", "LA", "L", "P"):
        img = img.convert("RGBA")
    img.save(path, format="PNG", optimize=True, compress_level=9)


def main() -> None:
    changed = []
    skipped = []
    BACKUP.mkdir(parents=True, exist_ok=True)

    for path in sorted(ASSETS.rglob("*.png")):
        with Image.open(path) as source:
            img = source.convert("RGBA")
            new_img = target_image(path, img)
            if new_img is None:
                skipped.append(path)
                continue

            before_size = path.stat().st_size
            before_dim = img.size
            backup_path = BACKUP / path.relative_to(PROJECT)
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, backup_path)
            save_png(new_img, path)
            after_size = path.stat().st_size
            changed.append((rel(path), before_dim, new_img.size, before_size, after_size))

    print(f"backup={BACKUP}")
    print(f"changed={len(changed)} skipped={len(skipped)}")
    before_total = sum(item[3] for item in changed)
    after_total = sum(item[4] for item in changed)
    print(f"changed_png_mb_before={before_total / 1024 / 1024:.2f}")
    print(f"changed_png_mb_after={after_total / 1024 / 1024:.2f}")
    print("top_changes:")
    for r, before_dim, after_dim, before_size, after_size in sorted(
        changed, key=lambda item: item[3] - item[4], reverse=True
    )[:40]:
        saved = (before_size - after_size) / 1024 / 1024
        print(f"{saved:6.2f} MB  {before_dim[0]}x{before_dim[1]} -> {after_dim[0]}x{after_dim[1]}  {r}")


if __name__ == "__main__":
    main()
