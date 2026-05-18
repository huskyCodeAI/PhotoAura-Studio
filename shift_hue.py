import sys
from PIL import Image

def shift_hue(image_path, output_path):
    print(f"Loading {image_path}...")
    img = Image.open(image_path).convert("RGBA")
    r, g, b, a = img.split()
    
    # Convert RGB to HSV for easy selective color shifting
    hsv = img.convert("HSV")
    h, s, v = hsv.split()
    
    h_data = bytearray(h.tobytes())
    s_data = bytearray(s.tobytes())
    v_data = bytearray(v.tobytes())
    
    # In PIL, HSV values are scaled 0-255.
    # Hue values:
    # 0-35 (out of 255) is roughly Red/Orange/Yellow (0 - 50 degrees).
    # 230-255 is Red/Pink (325 - 360 degrees).
    # We want to map these orange/amber hues to Neon Magenta / Violet (280-310 degrees, which is 198-220 in PIL).
    
    changed_pixels = 0
    for i in range(len(h_data)):
        hue = h_data[i]
        sat = s_data[i]
        val = v_data[i]
        
        # Target orange, amber, and yellow pixels
        # Also ensure they have decent saturation/value to avoid shifting neutral grays/shadows
        if (hue <= 38 or hue >= 240) and sat > 40:
            # Shift to gorgeous neon magenta/purple
            # Orange is ~20 (28 degrees). Magenta is ~210 (296 degrees).
            # We can map it dynamically:
            if hue <= 38:
                # Map hue from [0, 38] to [200, 222]
                new_hue = 200 + int((hue / 38.0) * 22)
            else:
                # Map hue from [240, 255] to [222, 235]
                new_hue = 222 + int(((hue - 240) / 15.0) * 13)
                
            h_data[i] = new_hue % 256
            # Boost saturation slightly for a beautiful neon glow
            s_data[i] = min(255, int(sat * 1.15))
            changed_pixels += 1
            
    print(f"Shifted {changed_pixels} pixels to purple/magenta.")
    
    # Reconstruct the image
    h.frombytes(bytes(h_data))
    s.frombytes(bytes(s_data))
    v.frombytes(bytes(v_data))
    
    new_hsv = Image.merge("HSV", (h, s, v))
    new_rgb = new_hsv.convert("RGB")
    
    # Merge back original alpha channel
    final_img = Image.merge("RGBA", (new_rgb.split()[0], new_rgb.split()[1], new_rgb.split()[2], a))
    final_img.save(output_path, "PNG")
    print(f"Saved successfully to {output_path}")

if __name__ == "__main__":
    splash_src = r"C:\Users\win11nuevox\AppData\Local\Temp\photoaura_splash_v2.png" # We will copy the file to a simplified temp path or use the exact absolute path
    splash_src = r"C:\Users\win11nuevox\.gemini\antigravity\brain\2f47937c-1898-43e9-90bf-9f996171902d\photoaura_splash_v2_1779135451577.png"
    logo_src = r"C:\Users\win11nuevox\.gemini\antigravity\brain\2f47937c-1898-43e9-90bf-9f996171902d\photoaura_logo_1779135284792.png"
    
    splash_out = r"C:\Users\win11nuevox\.gemini\antigravity\brain\2f47937c-1898-43e9-90bf-9f996171902d\photoaura_splash_violet_final.png"
    logo_out = r"C:\Users\win11nuevox\.gemini\antigravity\brain\2f47937c-1898-43e9-90bf-9f996171902d\photoaura_logo_violet_final.png"
    
    shift_hue(splash_src, splash_out)
    shift_hue(logo_src, logo_out)
    print("Done!")
