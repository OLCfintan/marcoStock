import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

old_pie_code = """                  return PieChart(
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
                  );"""

new_pie_code = """                  return Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: validData.asMap().entries.map((e) {
                              return PieChartSectionData(
                                color: colors[e.key % colors.length],
                                value: e.value.value,
                                showTitle: false, // Hide titles inside slices
                                radius: 80,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: validData.asMap().entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: colors[e.key % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${e.value.label} (${e.value.value.toInt()})',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );"""

content = content.replace(old_pie_code, new_pie_code)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

