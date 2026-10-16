import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_twin_ribbon_icon(size=1024, is_round=False):
    # Render at 2x resolution for ultra-sharp supersampling anti-aliasing
    scale = 2
    canvas_size = size * scale
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    
    # 1. Base Gradient Canvas (Royal Amethyst Violet to Hot Strawberry Rose)
    # Colors:
    # C1 (top-left): #6D28D9 (109, 40, 217)
    # C2 (top-right): #BE185D (190, 24, 93)
    # C3 (bottom-left): #7C3AED (124, 58, 237)
    # C4 (bottom-right): #F43F5E (244, 63, 94)
    # Accent: #FB7185 (251, 113, 133)
    
    grad = Image.new("RGBA", (canvas_size, canvas_size))
    for y in range(canvas_size):
        v = y / canvas_size
        for x in range(canvas_size):
            u = x / canvas_size
            
            # Diagonal gradient with radial flare
            t = (u * 0.6 + v * 0.7)
            t = max(0.0, min(1.0, t))
            
            # Distance from top-left center
            dx = (x - canvas_size * 0.3) / canvas_size
            dy = (y - canvas_size * 0.25) / canvas_size
            dist = math.sqrt(dx * dx + dy * dy)
            flare = max(0.0, 1.0 - dist * 1.3) * 0.25
            
            r = int((109 * (1 - t) + 244 * t) + flare * 255)
            g = int((40 * (1 - t) + 63 * t) + flare * 200)
            b = int((217 * (1 - t) + 94 * t) + flare * 240)
            
            r = min(255, max(0, r))
            g = min(255, max(0, g))
            b = min(255, max(0, b))
            grad.putpixel((x, y), (r, g, b, 255))
            
    # Mask for Squircle or Round
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    draw_mask = ImageDraw.Draw(mask)
    margin = int(24 * scale)
    bbox = [margin, margin, canvas_size - margin, canvas_size - margin]
    
    if is_round:
        draw_mask.ellipse(bbox, fill=255)
    else:
        corner_r = int(220 * scale)
        draw_mask.rounded_rectangle(bbox, radius=corner_r, fill=255)
        
    # Apply background mask
    bg = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bg.paste(grad, (0, 0), mask)
    
    # Inner border highlight ring
    border_draw = ImageDraw.Draw(bg)
    border_color = (255, 255, 255, 65)
    if is_round:
        border_draw.ellipse(bbox, outline=border_color, width=int(5 * scale))
    else:
        border_draw.rounded_rectangle(bbox, radius=int(220 * scale), outline=border_color, width=int(5 * scale))
        
    # 2. Draw Twin Ribbon Heart & Moon Emblem
    # We will draw smooth, thick flowing ribbons that intertwine
    emblem = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    emblem_draw = ImageDraw.Draw(emblem)
    
    cx = canvas_size / 2.0
    cy = canvas_size / 2.0 + (10 * scale)
    s = canvas_size * 0.36
    
    # Ribbon 1: Left Crescent Ribbon (Moon & Left Heart Lobe)
    # Flowing from bottom (cx, cy + s) -> curving up-left -> forming top lobe -> looping into crescent
    pts_left = []
    steps = 120
    for i in range(steps + 1):
        t = i / steps
        # Parametric cubic curve
        # P0: bottom center
        # P1: left control
        # P2: top-left lobe
        # P3: center dip
        p0 = (cx, cy + s * 0.95)
        p1 = (cx - s * 1.3, cy + s * 0.45)
        p2 = (cx - s * 1.25, cy - s * 1.05)
        p3 = (cx - s * 0.05, cy - s * 0.45)
        
        omt = 1 - t
        x = omt**3 * p0[0] + 3 * omt**2 * t * p1[0] + 3 * omt * t**2 * p2[0] + t**3 * p3[0]
        y = omt**3 * p0[1] + 3 * omt**2 * t * p1[1] + 3 * omt * t**2 * p2[1] + t**3 * p3[1]
        
        # Ribbon width varies gracefully
        w = (math.sin(t * math.pi) * 0.65 + 0.35) * (42 * scale)
        pts_left.append((x, y, w))
        
    # Ribbon 2: Right Embracing Ribbon (Cradling Partner Ribbon)
    pts_right = []
    for i in range(steps + 1):
        t = i / steps
        p0 = (cx, cy + s * 0.95)
        p1 = (cx + s * 1.3, cy + s * 0.35)
        p2 = (cx + s * 1.2, cy - s * 1.05)
        p3 = (cx, cy - s * 0.35)
        
        omt = 1 - t
        x = omt**3 * p0[0] + 3 * omt**2 * t * p1[0] + 3 * omt * t**2 * p2[0] + t**3 * p3[0]
        y = omt**3 * p0[1] + 3 * omt**2 * t * p1[1] + 3 * omt * t**2 * p2[1] + t**3 * p3[1]
        
        w = (math.sin(t * math.pi) * 0.65 + 0.35) * (38 * scale)
        pts_right.append((x, y, w))

    # Inner Crescent Moon inside the heart
    pts_moon = []
    moon_steps = 80
    for i in range(moon_steps + 1):
        t = i / moon_steps
        p0 = (cx - s * 0.35, cy + s * 0.5)
        p1 = (cx - s * 0.85, cy + s * 0.05)
        p2 = (cx - s * 0.65, cy - s * 0.65)
        p3 = (cx - s * 0.08, cy - s * 0.25)
        
        omt = 1 - t
        x = omt**3 * p0[0] + 3 * omt**2 * t * p1[0] + 3 * omt * t**2 * p2[0] + t**3 * p3[0]
        y = omt**3 * p0[1] + 3 * omt**2 * t * p1[1] + 3 * omt * t**2 * p2[1] + t**3 * p3[1]
        w = (math.sin(t * math.pi) * 0.75 + 0.25) * (26 * scale)
        pts_moon.append((x, y, w))

    # Draw ribbons onto separate alpha layers with shadows for beautiful 3D layering
    def draw_ribbon(draw_ctx, pts, color_start, color_end, alpha_mult=1.0):
        n = len(pts)
        for i in range(n - 1):
            t = i / n
            r = int(color_start[0] * (1 - t) + color_end[0] * t)
            g = int(color_start[1] * (1 - t) + color_end[1] * t)
            b = int(color_start[2] * (1 - t) + color_end[2] * t)
            a = int(255 * alpha_mult)
            col = (r, g, b, a)
            
            x1, y1, w1 = pts[i]
            x2, y2, w2 = pts[i + 1]
            draw_ctx.line([(x1, y1), (x2, y2)], fill=col, width=int((w1 + w2) / 2))
            draw_ctx.ellipse([x1 - w1/2, y1 - w1/2, x1 + w1/2, y1 + w1/2], fill=col)

    # 2a. Soft drop shadow behind emblem
    shadow_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    draw_ribbon(shadow_draw, pts_left, (0, 0, 0), (0, 0, 0), alpha_mult=0.45)
    draw_ribbon(shadow_draw, pts_right, (0, 0, 0), (0, 0, 0), alpha_mult=0.45)
    draw_ribbon(shadow_draw, pts_moon, (0, 0, 0), (0, 0, 0), alpha_mult=0.35)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=int(18 * scale)))
    
    # 2b. Ribbon 2 (Partner Right Ribbon - Rose to Coral Gold)
    r2_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    r2_draw = ImageDraw.Draw(r2_layer)
    draw_ribbon(r2_draw, pts_right, (255, 235, 240), (255, 175, 189), alpha_mult=0.92)
    
    # 2c. Ribbon 1 (Left Heart & Moon Ribbon - Pure Radiant White Pearl with Lavender Sheen)
    r1_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    r1_draw = ImageDraw.Draw(r1_layer)
    draw_ribbon(r1_draw, pts_left, (255, 255, 255), (255, 240, 248), alpha_mult=0.98)
    draw_ribbon(r1_draw, pts_moon, (255, 255, 255), (254, 215, 226), alpha_mult=0.95)
    
    # 2d. Center Vitality Spark / Glowing Pearl
    pearl_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    pearl_draw = ImageDraw.Draw(pearl_layer)
    px = cx + (s * 0.08)
    py = cy - (s * 0.05)
    pr = 22 * scale
    
    # Glow around pearl
    for r_i in range(int(pr * 2.8), int(pr * 0.8), -1):
        alpha = int(90 * (1.0 - (r_i - pr * 0.8) / (pr * 2.0)))
        pearl_draw.ellipse([px - r_i, py - r_i, px + r_i, py + r_i], fill=(255, 245, 220, alpha))
        
    pearl_draw.ellipse([px - pr, py - pr, px + pr, py + pr], fill=(255, 255, 255, 255))
    
    # Combine layers
    bg.alpha_composite(shadow_layer, (0, int(10 * scale)))
    bg.alpha_composite(r2_layer)
    bg.alpha_composite(r1_layer)
    bg.alpha_composite(pearl_layer)
    
    # Downsample with high-quality Lanczos resampling
    final_icon = bg.resize((size, size), Image.Resampling.LANCZOS)
    return final_icon

def generate_all():
    print("Generating master 1024x1024 app icon (Konsep B: Twin Ribbon Heart & Moon)...")
    icon_1024 = create_twin_ribbon_icon(1024, is_round=False)
    icon_1024_round = create_twin_ribbon_icon(1024, is_round=True)
    
    os.makedirs("assets/images", exist_ok=True)
    icon_1024.save("assets/images/app_icon.png")
    icon_1024_round.save("assets/images/app_icon_round.png")
    print("Saved assets/images/app_icon.png")
    
    # Android Mipmaps
    mipmap_targets = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]
    
    base_res_dir = "android/app/src/main/res"
    for folder, px in mipmap_targets:
        out_dir = os.path.join(base_res_dir, folder)
        os.makedirs(out_dir, exist_ok=True)
        
        # Standard squircle launcher icon
        icon_squircle = icon_1024.resize((px, px), Image.Resampling.LANCZOS)
        squircle_path = os.path.join(out_dir, "ic_launcher.png")
        icon_squircle.save(squircle_path)
        
        # Round launcher icon
        icon_round = icon_1024_round.resize((px, px), Image.Resampling.LANCZOS)
        round_path = os.path.join(out_dir, "ic_launcher_round.png")
        icon_round.save(round_path)
        
        print(f"Generated {folder} ({px}x{px}): ic_launcher.png & ic_launcher_round.png")
        
    print("All app icons successfully generated!")

if __name__ == "__main__":
    generate_all()
