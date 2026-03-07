from PIL import Image, ImageFilter, ImageEnhance, ImageDraw
import os

# Create icons dir if not exists
os.makedirs('assets/icons', exist_ok=True)

# Load original
img = Image.open('assets/icons/app_icon.png').convert("RGBA")
w, h = img.size

# --- 1. Extract Logo ---
# The original icon is #7B61FF (purple) with white logo.
# We will create a mask of the white parts.
logo_mask = Image.new('L', (w, h), 0)
pixels = img.load()
mask_pixels = logo_mask.load()
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        # Check if pixel is close to white
        if r > 200 and g > 200 and b > 200:
            # We use an approximation for anti-aliasing based on lightness
            lightness = int((r + g + b) / 3)
            # Map lightness 200-255 to alpha 0-255
            alpha = max(0, min(255, int((lightness - 150) * 255 / 105)))
            mask_pixels[x, y] = alpha

# 2. Create Dark Icon
dark_bg = Image.new("RGBA", (w, h), (18, 18, 18, 255))
logo_colored = Image.new("RGBA", (w, h), (255, 255, 255, 255))
dark_icon = Image.composite(logo_colored, dark_bg, logo_mask)
dark_icon.save('assets/icons/app_icon_dark.png')

# 3. Create iOS Liquid Glass Icon
# Background: Deep rich purple
glass_bg = Image.new("RGBA", (w, h), (90, 45, 210, 255)) # slightly darker purple
# Add a gradient or some noise for glass
draw = ImageDraw.Draw(glass_bg)
for y in range(h):
    factor = 1.0 - (y / h) * 0.4
    r, g, b = int(123 * factor), int(97 * factor), int(255 * factor)
    draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

# Add inner glow / glass reflection
glass_overlay = Image.new("RGBA", (w, h), (255, 255, 255, 0))
over_draw = ImageDraw.Draw(glass_overlay)
over_draw.ellipse([-w*0.5, -h*0.5, w*1.5, h*0.8], fill=(255, 255, 255, 40))
glass_bg = Image.alpha_composite(glass_bg, glass_overlay)

# Add liquid glass bevel (simple)
bevel = Image.new("RGBA", (w, h), (0,0,0,0))
b_draw = ImageDraw.Draw(bevel)
b_draw.rectangle([0, 0, w, h], outline=(255, 255, 255, 80), width=int(w*0.02))
b_draw.rectangle([int(w*0.01), int(h*0.01), w-int(w*0.01), h-int(h*0.01)], outline=(0, 0, 0, 80), width=int(w*0.01))
glass_bg = Image.alpha_composite(glass_bg, bevel.filter(ImageFilter.GaussianBlur(int(w*0.02))))

# Composite logo with a slight drop shadow inside the glass
shadow = Image.new("RGBA", (w, h), (0,0,0,0))
shadow.paste(Image.new("RGBA", (w, h), (0,0,0, 150)), (0, 0), logo_mask)
shadow = shadow.filter(ImageFilter.GaussianBlur(int(w*0.015)))
# Shift shadow slightly
shadow_shifted = Image.new("RGBA", (w, h), (0,0,0,0))
shadow_shifted.paste(shadow, (0, int(h*0.01)))

glass_bg = Image.alpha_composite(glass_bg, shadow_shifted)
glass_bg = Image.composite(logo_colored, glass_bg, logo_mask)

glass_bg.save('assets/icons/app_icon_ios_glass.png')

print("Icons generated successfully!")
