import re

filepath = "lib/src/presentation/widgets/human_profile_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_trailing = r"""          trailing: Row\(
            mainAxisSize: MainAxisSize.min,
            children: \[
              if \(ref.watch\(currentUserProvider\)\?.role == 'ADMIN'\)
                IconButton\(icon: const Icon\(Icons.delete, color: Colors.red\), onPressed: \(\) async \{
                   final db = ref.read\(databaseProvider\);
                   await \(db.update\(db.payments\)\.\.where\(\(t\) => t.id.equals\(payment.id\)\)\).write\(const PaymentsCompanion\(isActive: drift.Value\(false\)\)\);
                \}\),
              Text\(payment.status, style: TextStyle\(
                color: payment.status == 'CLEARED' \? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold
              \)\),
            \]
          \),"""

new_trailing = r"""          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(payment.status, style: TextStyle(
                color: payment.status == 'CLEARED' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold
              )),
              if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'delete') {
                       final db = ref.read(databaseProvider);
                       await (db.update(db.payments)..where((t) => t.id.equals(payment.id))).write(const PaymentsCompanion(isActive: drift.Value(false)));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.red))),
                  ],
                ),
            ]
          ),"""

content = re.sub(old_trailing, new_trailing, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Fixed ledger list trailing")
