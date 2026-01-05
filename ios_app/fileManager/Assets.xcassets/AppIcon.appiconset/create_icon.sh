#!/bin/bash
# Create a simple app icon using ImageMagick or sips (macOS built-in)
# This creates a 1024x1024 icon with a folder symbol

if command -v convert &> /dev/null; then
    # Using ImageMagick
    convert -size 1024x1024 xc:"#667eea" \
        -fill white -stroke "#4a5568" -strokewidth 20 \
        -draw "rectangle 200,300 800,900" \
        -draw "polygon 220,300 420,300 440,200 240,200" \
        icon_1024.png
elif command -v sips &> /dev/null; then
    # Using sips (macOS built-in) - create a solid color icon
    sips -s format png --setProperty format png \
        -z 1024 1024 \
        /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns \
        --out icon_1024.png 2>/dev/null || \
    python3 << 'PYEOF'
from PIL import Image, ImageDraw
size = 1024
img = Image.new('RGB', (size, size), color='#667eea')
draw = ImageDraw.Draw(img)
# Draw folder
folder_size = 600
folder_x = (size - folder_size) // 2
folder_y = (size - folder_size) // 2 - 50
draw.rectangle([folder_x + 50, folder_y + 100, folder_x + folder_size - 50, folder_y + folder_size], fill='#ffffff', outline='#4a5568', width=8)
draw.polygon([(folder_x + 80, folder_y + 100), (folder_x + 280, folder_y + 100), (folder_x + 300, folder_y + 50), (folder_x + 100, folder_y + 50)], fill='#ffffff', outline='#4a5568', width=8)
img.save('icon_1024.png')
PYEOF
else
    echo "Note: Please add a 1024x1024 PNG icon named 'icon_1024.png' to this directory"
    echo "You can create one using any image editor or online icon generator"
fi
