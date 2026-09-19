import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_metrics = """          children: [
            _MetricCard(
              title: "Today's Sales",
              icon: Icons.point_of_sale,
              color: Colors.green,
              asyncValue: salesAsync,
              prefix: 'Dhs ',
              onTap: () {
                showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Today's Sales"), content: Text("Normal Client Sales details will appear here.")));
              },
            ),
            _MetricCard(
              title: 'Outstanding Client Debt',
              icon: Icons.money_off,
              color: Colors.orange,
              asyncValue: debtAsync,
              prefix: 'Dhs ',
              onTap: () {
                showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Outstanding Debt"), content: Text("Normal Client Debt details will appear here.")));
              },
            ),
            _MetricCard(
              title: 'Profit Margin (Month)',
              icon: Icons.trending_up,
              color: Colors.blue,
              asyncValue: marginAsync,
              suffix: '%',
              isDouble: true,
              onTap: () {
                showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Profit Margin"), content: Text("Detailed margin calculations (excluding special clients) will appear here.")));
              },
            ),
          ],"""

new_metrics = """          children: [
            _MetricCard(
              title: "Today's Sales",
              icon: Icons.point_of_sale,
              color: Colors.green,
              asyncValue: salesAsync,
              prefix: 'Dhs ',
              onTap: () async {
                final db = ref.read(databaseProvider);
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);
                final normalClients = await (db.select(db.clients)..where((t) => t.type.equals('NORMAL'))).get();
                final normalIds = normalClients.map((c) => c.id).toList();
                final invoices = await (db.select(db.invoices)..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Today's Sales Details"),
                    content: SizedBox(
                      width: 400,
                      height: 400,
                      child: ListView.builder(
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final inv = invoices[index];
                          final clientName = normalClients.firstWhere((c) => c.id == inv.clientId).name;
                          return ListTile(
                            title: Text(clientName),
                            subtitle: Text(inv.date.toString()),
                            trailing: Text('${inv.total} Dhs'),
                          );
                        }
                      ),
                    ),
                  )
                );
              },
            ),
            _MetricCard(
              title: 'Outstanding Client Debt',
              icon: Icons.money_off,
              color: Colors.orange,
              asyncValue: debtAsync,
              prefix: 'Dhs ',
              onTap: () async {
                final db = ref.read(databaseProvider);
                final normalClients = await (db.select(db.clients)..where((t) => t.type.equals('NORMAL') & t.isActive.equals(true))).get();
                final debtClients = normalClients.where((c) => c.balance > Decimal.zero).toList();
                debtClients.sort((a, b) => b.balance.compareTo(a.balance));
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Outstanding Debt Details"),
                    content: SizedBox(
                      width: 400,
                      height: 400,
                      child: ListView.builder(
                        itemCount: debtClients.length,
                        itemBuilder: (context, index) {
                          final c = debtClients[index];
                          return ListTile(
                            title: Text(c.name),
                            trailing: Text('${c.balance} Dhs'),
                          );
                        }
                      ),
                    ),
                  )
                );
              },
            ),
            _MetricCard(
              title: 'Profit Margin',
              icon: Icons.trending_up,
              color: Colors.blue,
              asyncValue: marginAsync,
              suffix: '%',
              isDouble: true,
              onTap: () async {
                final db = ref.read(databaseProvider);
                final normalClients = await (db.select(db.clients)..where((t) => t.type.equals('NORMAL'))).get();
                final normalIds = normalClients.map((c) => c.id).toList();
                final invoices = await (db.select(db.invoices)..where((t) => t.isActive.equals(true) & t.clientId.isIn(normalIds))).get();
                final activeInvoiceIds = invoices.map((i) => i.id).toList();
                
                Decimal totalRev = Decimal.zero;
                Decimal totalCost = Decimal.zero;
                
                if (activeInvoiceIds.isNotEmpty) {
                  final lines = await (db.select(db.invoiceLines)..where((t) => t.invoiceId.isIn(activeInvoiceIds))).get();
                  for (final line in lines) {
                    final product = await (db.select(db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
                    if (product == null) continue;
                    final cost = line.quantity * product.purchasePrice;
                    totalRev += line.lineTotal;
                    totalCost += cost;
                  }
                }
                
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Profit Margin Details"),
                    content: SizedBox(
                      width: 400,
                      height: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Revenue (Normal Clients): $totalRev Dhs', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Total Cost (Normal Clients): $totalCost Dhs', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text('Net Profit: ${totalRev - totalCost} Dhs', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  )
                );
              },
            ),
          ],"""

content = content.replace(old_metrics, new_metrics)
with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

