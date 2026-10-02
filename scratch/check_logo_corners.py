from PIL import Image

img = Image.open('assets/images/logo.jpeg')
pixels = img.load()
width, height = img.size
print(f"Top-Left corner color: {pixels[0, 0]}")
print(f"Top-Right corner color: {pixels[width-1, 0]}")
print(f"Bottom-Left corner color: {pixels[0, height-1]}")
print(f"Bottom-Right corner color: {pixels[width-1, height-1]}")
