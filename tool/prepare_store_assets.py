"""Prepare deterministic Google Play assets from the approved source artwork."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
STORE = ROOT / "store_assets"
SOURCE = ASSETS / "source"

TEAL = (12, 74, 67)
TEAL_DARK = (6, 43, 41)
MINT = (101, 200, 190)
CREAM = (255, 248, 231)
AMBER = (255, 178, 87)


def fit_foreground(source: Image.Image, canvas_size: int = 1024) -> Image.Image:
    source = source.convert("RGBA")
    alpha = source.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("The icon foreground is fully transparent")
    symbol = source.crop(bbox)
    # Keep all meaningful pixels inside Android's central adaptive-icon safe area.
    max_side = 610
    symbol.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - symbol.width) // 2
    y = (canvas_size - symbol.height) // 2
    canvas.alpha_composite(symbol, (x, y))
    return canvas


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        ratio = y / max(height - 1, 1)
        color = tuple(round(top[i] * (1 - ratio) + bottom[i] * ratio) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image


def create_icons(raw_path: Path) -> None:
    normalized = fit_foreground(Image.open(raw_path))
    normalized.save(ASSETS / "app_icon_foreground.png", optimize=True)

    alpha = normalized.getchannel("A")
    mono = Image.new("RGBA", normalized.size, (255, 255, 255, 0))
    mono.putalpha(alpha)
    mono.save(ASSETS / "app_icon_monochrome.png", optimize=True)

    base = vertical_gradient((1024, 1024), (16, 102, 91), TEAL_DARK).convert("RGBA")
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((115, 65, 909, 859), fill=(*MINT, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(85))
    base.alpha_composite(glow)

    # Legacy launcher icons use a slightly larger mark than adaptive icons.
    bbox = alpha.getbbox()
    assert bbox is not None
    mark = normalized.crop(bbox)
    mark.thumbnail((690, 690), Image.Resampling.LANCZOS)
    base.alpha_composite(mark, ((1024 - mark.width) // 2, (1024 - mark.height) // 2))
    base.save(ASSETS / "app_icon.png", optimize=True)

    play_icon = base.resize((512, 512), Image.Resampling.LANCZOS)
    play_icon.save(STORE / "app_icon_512.png", optimize=True)


def create_feature_graphic(background_path: Path) -> None:
    source = Image.open(background_path).convert("RGB")
    feature = ImageOps.fit(source, (1024, 500), method=Image.Resampling.LANCZOS)
    overlay = Image.new("RGBA", feature.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle((260, 82, 764, 418), radius=48, fill=(4, 34, 32, 128))
    feature = Image.alpha_composite(feature.convert("RGBA"), overlay)

    draw = ImageDraw.Draw(feature)
    title_font = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 64)
    subtitle_font = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 30)
    title = "Finance Tracker"
    subtitle = "Финансы под контролем"

    title_box = draw.textbbox((0, 0), title, font=title_font)
    subtitle_box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    draw.text(((1024 - (title_box[2] - title_box[0])) / 2, 183), title, font=title_font, fill=CREAM)
    draw.text(((1024 - (subtitle_box[2] - subtitle_box[0])) / 2, 273), subtitle, font=subtitle_font, fill=(219, 242, 237))
    feature.convert("RGB").save(STORE / "feature_graphic_1024x500.png", optimize=True)


def validate() -> None:
    checks = [
        (ASSETS / "app_icon.png", (1024, 1024), {"RGBA"}),
        (ASSETS / "app_icon_foreground.png", (1024, 1024), {"RGBA"}),
        (ASSETS / "app_icon_monochrome.png", (1024, 1024), {"RGBA"}),
        (STORE / "app_icon_512.png", (512, 512), {"RGBA"}),
        (STORE / "feature_graphic_1024x500.png", (1024, 500), {"RGB"}),
    ]
    for path, expected_size, expected_modes in checks:
        with Image.open(path) as image:
            if image.size != expected_size or image.mode not in expected_modes:
                raise ValueError(f"Unexpected asset properties: {path}: {image.size}, {image.mode}")
        if path.name == "app_icon_512.png" and path.stat().st_size > 1024 * 1024:
            raise ValueError("Google Play icon exceeds 1024 KB")


def main() -> None:
    SOURCE.mkdir(parents=True, exist_ok=True)
    STORE.mkdir(parents=True, exist_ok=True)
    raw_icon = SOURCE / "app_icon_foreground_raw.png"
    raw_feature = STORE / "feature_graphic_background.png"
    if not raw_icon.exists():
        current = ASSETS / "app_icon_foreground.png"
        raw_icon.write_bytes(current.read_bytes())
    create_icons(raw_icon)
    create_feature_graphic(raw_feature)
    validate()
    print("Prepared Google Play icon and feature graphic.")


if __name__ == "__main__":
    main()
