"""Dựng video minh hoạ quy trình pha chế từ dữ liệu công thức thật (recipes.json).

Mỗi bước = một đoạn dài đúng durationSeconds (không có thì 10 s), khớp cách app mobile tính
videoStartSeconds/videoEndSeconds (RecipeMapper). Khung hình 1280x720, 1 khung/giây rồi ffmpeg nội suy 24 fps.
Cách chạy: python -I make_videos.py <recipes.json> <out_dir> CODE [CODE...]
"""
import json
import os
import subprocess
import sys
import tempfile
import textwrap

from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720
CANVAS = (255, 253, 247)
SAND = (196, 154, 108)
SAND_DARK = (160, 112, 64)
SAND_LIGHT = (250, 246, 240)
INK = (41, 37, 36)
SECONDARY = (120, 113, 108)
BORDER = (231, 224, 213)
OCEAN = (8, 145, 178)
WARN = (202, 138, 4)
LIQUID = [(214, 184, 150), (196, 154, 108), (176, 132, 90), (150, 110, 72)]
FONT = "C:/Windows/Fonts/segoeui.ttf"
FONT_B = "C:/Windows/Fonts/segoeuib.ttf"


def font(size, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, size)


def wrap(draw, text, fnt, width):
    lines = []
    for para in text.split("\n"):
        words, cur = para.split(), ""
        for w in words:
            t = (cur + " " + w).strip()
            if draw.textlength(t, font=fnt) <= width:
                cur = t
            else:
                lines.append(cur)
                cur = w
        lines.append(cur)
    return lines


def draw_cup(d, x, y, level, color):
    """Ly nhựa đơn giản: hình thang, đổ đầy theo level 0..1."""
    top_w, bot_w, h = 220, 160, 300
    tl, tr = (x - top_w // 2, y), (x + top_w // 2, y)
    bl, br = (x - bot_w // 2, y + h), (x + bot_w // 2, y + h)
    if level > 0:
        ly = y + h - int(h * level)
        frac = (ly - y) / h
        half = (top_w - (top_w - bot_w) * frac) // 2
        d.polygon([(x - half, ly), (x + half, ly), br, bl], fill=color)
    d.line([tl, bl, br, tr], fill=INK, width=6, joint="curve")
    d.line([(tl[0] - 10, y), (tr[0] + 10, y)], fill=INK, width=8)


def frame(recipe, idx, step, remaining, total, step_count):
    img = Image.new("RGB", (W, H), CANVAS)
    d = ImageDraw.Draw(img)
    # Thanh tiêu đề
    d.rectangle([0, 0, W, 86], fill=SAND_LIGHT)
    d.line([0, 86, W, 86], fill=BORDER, width=2)
    d.text((40, 18), recipe["name"], font=font(34, True), fill=INK)
    code = recipe.get("category", "")
    d.text((W - 40 - d.textlength(code, font=font(22)), 30), code, font=font(22), fill=SAND_DARK)
    # Số bước
    cx, cy = 92, 170
    d.ellipse([cx - 46, cy - 46, cx + 46, cy + 46], fill=SAND)
    n = str(idx + 1)
    d.text((cx - d.textlength(n, font=font(44, True)) / 2, cy - 32), n, font=font(44, True), fill="white")
    d.text((160, 128), f"Bước {idx + 1}/{step_count}", font=font(22, True), fill=SAND_DARK)
    d.text((160, 156), step.get("title", ""), font=font(40, True), fill=INK)
    # Mô tả
    y = 240
    for line in wrap(d, step.get("description", ""), font(28), 760)[:6]:
        d.text((60, y), line, font=font(28), fill=INK)
        y += 42
    # Chip thông số
    chips = []
    if step.get("temperatureCelsius") is not None:
        chips.append((f'{step["temperatureCelsius"]:g}°C', OCEAN))
    if step.get("durationSeconds"):
        chips.append((f'{step["durationSeconds"]} giây', OCEAN))
    if step.get("equipment"):
        chips.append((step["equipment"][:40], SAND_DARK))
    x = 60
    y += 14
    for text, col in chips:
        tw = d.textlength(text, font=font(22, True))
        d.rounded_rectangle([x, y, x + tw + 32, y + 44], radius=12, fill=SAND_LIGHT, outline=BORDER, width=2)
        d.text((x + 16, y + 8), text, font=font(22, True), fill=col)
        x += tw + 48
    if step.get("safetyNote"):
        y += 64
        for line in wrap(d, "Lưu ý: " + step["safetyNote"], font(24), 760)[:2]:
            d.text((60, y), line, font=font(24), fill=WARN)
            y += 34
    # Ly minh hoạ, đầy dần theo tiến độ
    level = min(1.0, (idx + (1 - remaining / total)) / step_count)
    draw_cup(d, 1050, 200, level * 0.92, LIQUID[idx % len(LIQUID)])
    # Thanh tiến độ bước + đếm ngược
    d.rounded_rectangle([60, H - 70, W - 60, H - 52], radius=9, fill=BORDER)
    done = int((W - 120) * (1 - remaining / total))
    if done > 0:
        d.rounded_rectangle([60, H - 70, 60 + done, H - 52], radius=9, fill=SAND)
    left = f"Còn {remaining} giây"
    d.text((W - 60 - d.textlength(left, font=font(22, True)), H - 112), left, font=font(22, True), fill=SECONDARY)
    d.text((60, H - 112), "Video mẫu minh hoạ quy trình chuẩn · RecipeHub", font=font(20), fill=SECONDARY)
    return img


def build(recipe, out_path):
    steps = recipe["steps"]
    with tempfile.TemporaryDirectory() as tmp:
        k = 0
        for i, st in enumerate(steps):
            dur = st.get("durationSeconds") or 10
            for s in range(dur):
                frame(recipe, i, st, dur - s, dur, len(steps)).save(os.path.join(tmp, f"f{k:05d}.png"))
                k += 1
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-framerate", "1", "-i", os.path.join(tmp, "f%05d.png"),
             "-vf", "fps=24,format=yuv420p", "-c:v", "libx264", "-preset", "slow", "-crf", "28",
             "-movflags", "+faststart", out_path],
            check=True,
        )
    return k


def main():
    src, out_dir, codes = sys.argv[1], sys.argv[2], sys.argv[3:]
    recipes = {r["code"]: r for r in json.load(open(src, encoding="utf-8"))}
    os.makedirs(out_dir, exist_ok=True)
    for c in codes:
        secs = build(recipes[c], os.path.join(out_dir, f"{c}.mp4"))
        print(c, secs, "s", os.path.getsize(os.path.join(out_dir, f"{c}.mp4")) // 1024, "KB")


if __name__ == "__main__":
    main()
