from PIL import Image, ImageDraw

def create_rounded_image(image_path, output_path, radius_ratio=0.225):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    
    mask = Image.new('L', (w, h), 0)
    draw = ImageDraw.Draw(mask)
    r = int(w * radius_ratio)
    draw.rounded_rectangle((0, 0, w, h), radius=r, fill=255)
    
    result = Image.new('RGBA', (w, h), (0,0,0,0))
    result.paste(img, (0, 0), mask)
    
    result.save(output_path)
    print(f"Saved {output_path}")

create_rounded_image('assets/icons/app_icon.png', 'assets/icons/splash_icon_transparent.png')
