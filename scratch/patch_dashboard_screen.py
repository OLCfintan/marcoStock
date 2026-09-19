import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()


# 1. Update _MetricCard definition to include onTap
metric_card_old = """class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final AsyncValue<dynamic> asyncValue;
  final String prefix;
  final String suffix;
  final bool isDouble;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.asyncValue,
    this.prefix = '',
    this.suffix = '',
    this.isDouble = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding("""

metric_card_new = """class _MetricCard extends StatelessWidget {
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
        child: Padding("""

content = content.replace(metric_card_old, metric_card_new)

# 2. Add onTap to the MetricsGrid
metrics_grid_old = """          children: [
            _MetricCard(
              title: "Today's Sales",
              icon: Icons.point_of_sale,
              color: Colors.green,
              asyncValue: salesAsync,
              prefix: 'Dhs ',
            ),
            _MetricCard(
              title: 'Outstanding Client Debt',
              icon: Icons.money_off,
              color: Colors.orange,
              asyncValue: debtAsync,
              prefix: 'Dhs ',
            ),
            _MetricCard(
              title: 'Profit Margin (Month)',
              icon: Icons.trending_up,
              color: Colors.blue,
              asyncValue: marginAsync,
              suffix: '%',
              isDouble: true,
            ),
          ],"""

metrics_grid_new = """          children: [
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

content = content.replace(metrics_grid_old, metrics_grid_new)

# 3. Inject StockPieCharts widget
pie_chart_code = """
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
                  if (data.isEmpty) return const Center(child: Text('No stock data'));
                  final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.cyan];
                  return PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: data.asMap().entries.map((e) {
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
"""

content = content + "\n" + pie_chart_code


# 4. Insert _StockPieCharts into DashboardScreen body
insert_point = """            const _SalesChart(),
            const SizedBox(height: 32),
            LayoutBuilder("""

insert_code = """            const _SalesChart(),
            const SizedBox(height: 32),
            const _StockPieCharts(),
            const SizedBox(height: 32),
            LayoutBuilder("""

content = content.replace(insert_point, insert_code)


with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

