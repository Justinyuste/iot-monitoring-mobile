import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/api_service.dart';

void main() {
  runApp(const IoTMonitoringApp());
}

class IoTMonitoringApp extends StatelessWidget {
  const IoTMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Monitoring',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? timer;

  double? temperature;
  double? humidity;

  String deviceStatus = 'Checking...';
  String lastRecorded = '-';
  String errorMessage = '';

  List<dynamic> telemetryHistory = [];

  @override
  void initState() {
    super.initState();

    fetchData();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => fetchData(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final results = await Future.wait([
        ApiService.getTelemetry(),
        ApiService.getDeviceStatus(),
      ]);

      final telemetry = results[0] as List<dynamic>;
      final status = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        deviceStatus = status['status'] ?? 'OFFLINE';
        errorMessage = '';

        // Urutkan data dari terlama ke terbaru
        telemetryHistory = List<dynamic>.from(telemetry)
          ..sort((a, b) => a['id'].compareTo(b['id']));

        if (telemetryHistory.isNotEmpty) {
          final latest = telemetryHistory.last;

          temperature = double.tryParse(
            latest['temperature'].toString(),
          );

          humidity = double.tryParse(
            latest['humidity'].toString(),
          );

          lastRecorded = latest['recorded_at']?.toString() ?? '-';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deviceStatus = 'OFFLINE';
        errorMessage = 'Gagal menghubungkan ke server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = deviceStatus == 'ONLINE';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'IoT Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: fetchData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Monitoring suhu dan kelembapan secara real-time',
              style: TextStyle(color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 24),

            // Device Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: isOnline ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ESP32 Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    deviceStatus,
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sensor Cards
            Row(
              children: [
                Expanded(
                  child: sensorCard(
                    title: 'Temperature',
                    value: temperature?.toStringAsFixed(1) ?? '--',
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: sensorCard(
                    title: 'Humidity',
                    value: humidity?.toStringAsFixed(1) ?? '--',
                    unit: '%',
                    icon: Icons.water_drop,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoring History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Chart Legend
                  Row(
                    children: [
                      _chartLegend(
                        color: Colors.red,
                        label: 'Temperature',
                      ),
                      const SizedBox(width: 20),
                      _chartLegend(
                        color: Colors.blue,
                        label: 'Humidity',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 220,
                    child: telemetryHistory.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada data grafik',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 100,
                              gridData: const FlGridData(
                                show: true,
                              ),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              titlesData: const FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                // Temperature
                                LineChartBarData(
                                  spots: telemetryHistory
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => FlSpot(
                                          entry.key.toDouble(),
                                          double.tryParse(
                                                entry.value['temperature']
                                                    .toString(),
                                              ) ??
                                              0,
                                        ),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  color: Colors.red,
                                  barWidth: 2.5,
                                  dotData: const FlDotData(
                                    show: false,
                                  ),
                                ),

                                // Humidity
                                LineChartBarData(
                                  spots: telemetryHistory
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => FlSpot(
                                          entry.key.toDouble(),
                                          double.tryParse(
                                                entry.value['humidity']
                                                    .toString(),
                                              ) ??
                                              0,
                                        ),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2.5,
                                  dotData: const FlDotData(
                                    show: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Latest Telemetry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperature: ${temperature?.toStringAsFixed(1) ?? '--'} °C',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Humidity: ${humidity?.toStringAsFixed(1) ?? '--'} %',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recorded At: $lastRecorded',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _chartLegend({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget sensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
