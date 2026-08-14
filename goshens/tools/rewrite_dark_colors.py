from pathlib import Path
import re

root = Path(__file__).resolve().parents[1] / "lib"
skip_names = {"app_colors.dart", "app_theme.dart"}

color_map = {
    "AppColors.primaryDark": "AppColors.ink(context)",
    "AppColors.textPrimary": "AppColors.ink(context)",
    "AppColors.textSecondary": "AppColors.muted(context)",
    "AppColors.textMuted": "AppColors.faint(context)",
}


def strip_const_around(src: str) -> str:
    src = re.sub(r"\bconst (TextStyle\()", r"\1", src)
    src = re.sub(r"\bconst (Icon\()", r"\1", src)
    src = re.sub(r"\bconst (Text\()", r"\1", src)
    return src


changed = []
for path in root.rglob("*.dart"):
    if path.name in skip_names:
        continue
    text = path.read_text(encoding="utf-8")
    original = text
    if not any(key in text for key in color_map):
        continue
    text = strip_const_around(text)
    for old, new in color_map.items():
        text = text.replace(old, new)
    if text != original:
        path.write_text(text, encoding="utf-8")
        changed.append(path.relative_to(root).as_posix())

print(f"updated {len(changed)} files")
for item in changed:
    print(item)
