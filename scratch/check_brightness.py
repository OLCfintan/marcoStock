from PIL import Image
import numpy as np

img = Image.open('assets/images/pdf_logo.jpeg').convert('L')
arr = np.array(img)
print(f"pdf_logo average brightness (0-255): {arr.mean()}")

img2 = Image.open('assets/images/logo.jpeg').convert('L')
arr2 = np.array(img2)
print(f"logo average brightness (0-255): {arr2.mean()}")
