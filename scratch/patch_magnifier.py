import re

with open('lib/src/presentation/widgets/magnifier_wrapper.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../application/settings/settings_service.dart';")
content = content.replace("class MagnifierWrapper extends StatefulWidget {", "class MagnifierWrapper extends ConsumerStatefulWidget {")
content = content.replace("State<MagnifierWrapper> createState() => _MagnifierWrapperState();", "ConsumerState<MagnifierWrapper> createState() => _MagnifierWrapperState();")
content = content.replace("class _MagnifierWrapperState extends State<MagnifierWrapper> {", "class _MagnifierWrapperState extends ConsumerState<MagnifierWrapper> {")

old_build = """  @override
  Widget build(BuildContext context) {"""
new_build = """  @override
  Widget build(BuildContext context) {
    final zoomFactor = ref.watch(magnifierZoomProvider);"""
content = content.replace(old_build, new_build)

content = content.replace("magnificationScale: 1.25,", "magnificationScale: zoomFactor,")

with open('lib/src/presentation/widgets/magnifier_wrapper.dart', 'w') as f:
    f.write(content)
print('MagnifierWrapper patched.')
