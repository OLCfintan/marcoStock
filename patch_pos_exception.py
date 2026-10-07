import sys

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

import_statement = "import '../../application/sales/sales_service.dart';"
if import_statement not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)


catch_block_old = '''    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('Insufficient stock')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)?.errorStr ?? 'Error'),
                ],
              ),
              content: Text(
                errorStr.replaceAll('Exception:', '').trim(),
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e'),
            ),
          );
        }
      }
    }'''

catch_block_new = '''    } on InsufficientStockException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)?.errorStr ?? 'Error'),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)?.insufficientStockFor(e.productName, e.available, e.requested) ??
                  'Insufficient stock for "${e.productName}".\\nAvailable: ${e.available}\\nRequested: ${e.requested}',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e'),
          ),
        );
      }
    }'''

content = content.replace(catch_block_old, catch_block_new)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
