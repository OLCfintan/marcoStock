import re

with open('android/app/src/main/AndroidManifest.xml', 'r') as f:
    content = f.read()

permissions = """
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
"""

if "android.permission.READ_EXTERNAL_STORAGE" not in content:
    content = content.replace('<application', permissions + '\n    <application')

with open('android/app/src/main/AndroidManifest.xml', 'w') as f:
    f.write(content)
