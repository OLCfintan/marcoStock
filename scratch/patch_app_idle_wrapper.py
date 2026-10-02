import re

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'r') as f:
    content = f.read()

old_unlock = """                correctPassword: 'admin', // Ideally fetch from currentUser, but hardcoded 'admin' for demo or we can fetch it"""
new_unlock = """                correctPassword: ref.watch(currentUserProvider)?.passwordHash ?? 'admin',"""

content = content.replace(old_unlock, new_unlock)

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'w') as f:
    f.write(content)
print('AppIdleWrapper patched.')
