import re

filepath = "lib/src/application/backup/backup_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Fix SELECTs
content = content.replace("SELECT id, imagePath FROM products WHERE imagePath IS NOT NULL AND imagePath != '';", "SELECT id, image_path FROM products WHERE image_path IS NOT NULL AND image_path != '';")
content = content.replace("SELECT id, name, imagePath FROM clients WHERE imagePath IS NOT NULL AND imagePath != '';", "SELECT id, name, image_path FROM clients WHERE image_path IS NOT NULL AND image_path != '';")
content = content.replace("SELECT id, name, imagePath FROM suppliers WHERE imagePath IS NOT NULL AND imagePath != '';", "SELECT id, name, image_path FROM suppliers WHERE image_path IS NOT NULL AND image_path != '';")

# Fix Map reads
content = content.replace("row['imagePath']", "row['image_path']")

# Fix UPDATEs
content = content.replace("UPDATE products SET imagePath = ? WHERE id = ?", "UPDATE products SET image_path = ? WHERE id = ?")
content = content.replace("UPDATE clients SET imagePath = ? WHERE id = ?", "UPDATE clients SET image_path = ? WHERE id = ?")
content = content.replace("UPDATE suppliers SET imagePath = ? WHERE id = ?", "UPDATE suppliers SET image_path = ? WHERE id = ?")

with open(filepath, 'w') as f:
    f.write(content)
print("Updated SQL statements")
