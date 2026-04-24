import os
from PIL import Image, ImageDraw

os.makedirs('assets', exist_ok=True)
img = Image.new('RGB', (1024, 1024), color='#8DBCA6')
d = ImageDraw.Draw(img)

# Center circle
border = 100
d.ellipse([(border, border), (1024-border, 1024-border)], fill='white')

# Abstract person doing stretch / lotus
# Head
d.ellipse([(450, 250), (574, 374)], fill='#8DBCA6')

# Body / arms
d.polygon([(350, 450), (674, 450), (512, 600)], fill='#8DBCA6')

# Legs/lower base
d.ellipse([(350, 620), (674, 720)], fill='#8DBCA6')

img.save('assets/app_icon.png')
print("Successfully generated assets/app_icon.png")
