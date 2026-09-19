import "package:drift/drift.dart" hide Column;
import "../../infrastructure/database/providers.dart";
import "package:decimal/decimal.dart";
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../application/auth/auth_service.dart';
import '../../application/dashboard/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marko Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(currentUserProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const _MetricsGrid(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Over Time',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final period = ref.watch(salesChartPeriodProvider);
                    return DropdownButton<SalesChartPeriod>(
                      value: period,
                      onChanged: (newPeriod) {
                        if (newPeriod != null) {
                          ref.read(salesChartPeriodProvider.notifier).state = newPeriod;
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: SalesChartPeriod.daily, child: Text('Daily')),
                        DropdownMenuItem(value: SalesChartPeriod.weekly, child: Text('Weekly')),
                        DropdownMenuItem(value: SalesChartPeriod.monthly, child: Text('Monthly')),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SalesChart(),
            const SizedBox(height: 32),
            const _StockPieCharts(),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Top-Selling Products', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                const _TopSellingProductsList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Employee Performance', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                const _EmployeePerformanceList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Top Clients (Debt)', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                const _TopClientsList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Top Suppliers (Debt)', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                const _TopSuppliersList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Top-Selling Products', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      const _TopSellingProductsList(),
                      const SizedBox(height: 32),
                      Text('Employee Performance', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      const _EmployeePerformanceList(),
                      const SizedBox(height: 32),
                      Text('Top Clients (Debt)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      const _TopClientsList(),
                      const SizedBox(height: 32),
                      Text('Top Suppliers (Debt)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      const _TopSuppliersList(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Low Stock Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _LowStockList(),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends ConsumerWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesProvider);
    final debtAsync = ref.watch(outstandingDebtProvider);
    final marginAsync = ref.watch(profitMarginProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
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
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final AsyncValue<dynamic> asyncValue;
  final String prefix;
  final String suffix;
  final bool isDouble;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.asyncValue,
    this.prefix = '',
    this.suffix = '',
    this.isDouble = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  asyncValue.when(
                    data: (value) {
                      String displayValue = value.toString();
                      if (isDouble && value is double) {
                        displayValue = value.toStringAsFixed(1);
                      }
                      return Text(
                        '$prefix$displayValue$suffix',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, stack) => Text(
                      (AppLocalizations.of(context)?.errorStr ?? 'Error: ').trim(),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _SalesChart extends ConsumerWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesChartDataProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 300,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return salesAsync.when(
                data: (sales) {
              final double maxY = sales.isEmpty 
                  ? 100 
                  : (sales.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2).clamp(100.0, double.infinity);
                  
              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sales.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(sales[value.toInt()].label, style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sales.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: Colors.blueAccent,
                          width: sales.isEmpty ? 32 : (constraints.maxWidth / sales.length).clamp(10.0, 100.0) * 0.9,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Failed to load chart data: $err')),
          );
            }
          ),
        ),
      ),
    );
  }
}

class _LowStockList extends ConsumerWidget {
  const _LowStockList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(lowStockAlertsProvider);

    return Card(
      elevation: 2,
      child: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('Stock levels are good!'),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(alert.productName),
                subtitle: Text('Current Stock: ${alert.currentStock} (Min: ${alert.minimumStock})'),
                trailing: TextButton(
                  onPressed: () {
                    // Placeholder for navigation
                  },
                  child: const Text('RESTOCK'),
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('Failed to load stock alerts: $err')),
        ),
      ),
    );
  }
}

class _TopSellingProductsList extends ConsumerWidget {
  const _TopSellingProductsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(topSellingProductsProvider);

    return Card(
      elevation: 2,
      child: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No sales data available')),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(product.productName),
                subtitle: Text('Qty: ${product.totalQuantity}'),
                trailing: Text(
                  '${product.totalRevenue} Dhs',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('Failed to load top products: $err')),
        ),
      ),
    );
  }
}

class _EmployeePerformanceList extends ConsumerWidget {
  const _EmployeePerformanceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(employeePerformanceProvider);

    return Card(
      elevation: 2,
      child: performanceAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No performance data available')),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final emp = employees[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Colors.purple),
                ),
                title: Text(emp.employeeName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      emp.score.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('Failed to load performance data: $err')),
        ),
      ),
    );
  }
}

class _TopClientsList extends ConsumerWidget {
  const _TopClientsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(topClientsProvider);

    return Card(
      elevation: 2,
      child: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No client data available')),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(client.name),
                trailing: Text(
                  '${client.balance} Dhs',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('Failed to load top clients: $err')),
        ),
      ),
    );
  }
}

class _TopSuppliersList extends ConsumerWidget {
  const _TopSuppliersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(topSuppliersProvider);

    return Card(
      elevation: 2,
      child: suppliersAsync.when(
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No supplier data available')),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suppliers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(supplier.name),
                trailing: Text(
                  '${supplier.balance} Dhs',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('Failed to load top suppliers: $err')),
        ),
      ),
    );
  }
}


class _StockPieCharts extends ConsumerWidget {
  const _StockPieCharts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseAsync = ref.watch(baseStockPieProvider);
    final magazinAsync = ref.watch(magazinStockPieProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final children = [
          Expanded(
            flex: isWide ? 1 : 0,
            child: _buildPieCard(context, 'Base Warehouse Stock Value', baseAsync),
          ),
          if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
          Expanded(
            flex: isWide ? 1 : 0,
            child: _buildPieCard(context, 'Magazin Stock Value', magazinAsync),
          ),
        ];
        
        return isWide ? Row(children: children) : Column(children: children);
      }
    );
  }

  Widget _buildPieCard(BuildContext context, String title, AsyncValue<List<StockChartData>> asyncData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: asyncData.when(
                data: (data) {
                  final validData = data.where((d) => d.value > 0).toList();
                  if (validData.isEmpty) return const Center(child: Text('No stock data', style: TextStyle(color: Colors.black)));
                  final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.cyan];
                  return PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: validData.asMap().entries.map((e) {
                        return PieChartSectionData(
                          color: colors[e.key % colors.length],
                          value: e.value.value,
                          title: e.value.label,
                          radius: 80,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
