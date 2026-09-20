import re

with open('android/app/src/main/AndroidManifest.xml', 'r') as f:
    content = f.read()

content = content.replace('<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>\n', '')
content = content.replace('<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>\n', '')
content = content.replace('<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>\n', '')
# there might be spaces
content = re.sub(r'\s*<uses-permission android:name="android\.permission\.(READ|WRITE|MANAGE)_EXTERNAL_STORAGE"\s*/>', '', content)

with open('android/app/src/main/AndroidManifest.xml', 'w') as f:
    f.write(content)
