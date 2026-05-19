from PIL import Image
transparent_img = Image.new('RGBA', (1, 1), (0, 0, 0, 0))
transparent_img.save(r'c:\photo\build\app\share\gimp\2.0\images\wilber.png', 'PNG')
transparent_img.save(r'c:\photo\build\app\share\gimp\2.0\images\gimp-logo.png', 'PNG')
print("Transparent PNGs created")
