"""Compose 9:16 Google Play screenshots around real Flutter UI captures."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "store_assets" / "screenshots"
RAW = SCREENSHOTS / "raw"
FONT_BOLD = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_REGULAR = r"C:\Windows\Fonts\segoeui.ttf"

ITEMS = [
    ("01_home.png", "01_home_1080x1920.png", (8, 55, 51), (15, 118, 110), "Полный контроль\nваших финансов"),
    ("02_add_expense.png", "02_add_expense_1080x1920.png", (7, 64, 59), (32, 139, 125), "Учет расходов\nв пару касаний"),
    ("03_budget.png", "03_budget_1080x1920.png", (26, 50, 55), (20, 112, 102), "Устанавливайте лимиты\nи экономьте"),
    ("04_analytics.png", "04_analytics_1080x1920.png", (5, 57, 67), (15, 118, 110), "Наглядная статистика\nи графики"),
    ("05_privacy.png", "05_privacy_1080x1920.png", (15, 48, 45), (24, 105, 94), "100% оффлайн\nи конфиденциально"),
]


def gradient(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = 1080, 1920
    image = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        ratio = y / (height - 1)
        color = tuple(round(top[i] * (1 - ratio) + bottom[i] * ratio) for i in range(3))
        draw.line((0, y, width, y), fill=color)
    return image


def add_background_shapes(image: Image.Image, index: int) -> None:
    shapes = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shapes)
    shift = index * 30
    draw.ellipse((-250 + shift, 120, 410 + shift, 780), fill=(101, 200, 190, 22))
    draw.ellipse((760 - shift, -130, 1250 - shift, 360), fill=(255, 178, 87, 22))
    draw.ellipse((690, 1320, 1320, 1950), fill=(255, 255, 255, 12))
    shapes = shapes.filter(ImageFilter.GaussianBlur(12))
    image.paste(Image.alpha_composite(image.convert("RGBA"), shapes).convert("RGB"))


def center_multiline(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> None:
    box = draw.multiline_textbbox((0, 0), text, font=font, align="center", spacing=6)
    width = box[2] - box[0]
    draw.multiline_text(
        ((1080 - width) / 2, 84),
        text,
        font=font,
        fill=(255, 248, 231),
        align="center",
        spacing=6,
    )


def compose(index: int, raw_name: str, output_name: str, top, bottom, caption: str) -> Path:
    canvas = gradient(top, bottom)
    add_background_shapes(canvas, index)
    draw = ImageDraw.Draw(canvas)
    center_multiline(draw, caption, ImageFont.truetype(FONT_BOLD, 68))

    brand_font = ImageFont.truetype(FONT_REGULAR, 26)
    brand = "FINANCE TRACKER"
    brand_box = draw.textbbox((0, 0), brand, font=brand_font)
    draw.text(((1080 - (brand_box[2] - brand_box[0])) / 2, 302), brand, font=brand_font, fill=(190, 231, 224))

    screenshot = Image.open(RAW / raw_name).convert("RGB")
    screenshot = screenshot.resize((700, 1556), Image.Resampling.LANCZOS)
    mask = Image.new("L", screenshot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 699, 1555), radius=42, fill=255)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((153, 302, 927, 1914), radius=64, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    frame = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        (165, 314, 915, 1910),
        radius=58,
        fill=(15, 24, 25, 255),
        outline=(207, 235, 229, 90),
        width=2,
    )
    canvas = Image.alpha_composite(canvas, frame)
    canvas.paste(screenshot, (190, 338), mask)

    output = SCREENSHOTS / output_name
    canvas.convert("RGB").save(output, optimize=True)
    return output


def create_contact_sheet(outputs: list[Path]) -> None:
    sheet = Image.new("RGB", (5 * 216, 404), "white")
    for index, output in enumerate(outputs):
        preview = Image.open(output).convert("RGB").resize((216, 384), Image.Resampling.LANCZOS)
        sheet.paste(preview, (index * 216, 0))
    sheet.save(SCREENSHOTS / "contact_sheet.jpg", quality=92, optimize=True)


def validate(outputs: list[Path]) -> None:
    for output in outputs:
        with Image.open(output) as image:
            if image.size != (1080, 1920) or image.mode != "RGB":
                raise ValueError(f"Unexpected screenshot properties: {output}: {image.size}, {image.mode}")


def main() -> None:
    outputs = [compose(index, *item) for index, item in enumerate(ITEMS)]
    validate(outputs)
    create_contact_sheet(outputs)
    print("Prepared five Google Play screenshots.")


if __name__ == "__main__":
    main()
