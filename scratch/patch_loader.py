import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_fallback = """    if (widget.size < 60) {
      // For small inline loaders, fallback to simple rotating logo
      return Center(
        child: RotationTransition(
          turns: _controller,
          child: ClipOval(
            clipBehavior: Clip.antiAliasWithSaveLayer, 
            child: Image.asset('assets/images/logo.jpeg', width: widget.size, height: widget.size, fit: BoxFit.cover, filterQuality: FilterQuality.high)
          ),
        ),
      );
    }

    // For large/fullscreen loaders, show the premium puzzle crystal background
    return ClipRRect("""

new_fallback = """    // Always show the premium puzzle crystal background, regardless of size
    return ClipRRect("""

content = content.replace(old_fallback, new_fallback)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
print("LogoLoader patched")
