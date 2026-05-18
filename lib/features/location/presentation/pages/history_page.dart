import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../storage/location_database.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<LocationDatabase>().recent(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent fixes')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) return const Center(child: Text('No fixes recorded yet.'));
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final r = rows[i];
              final ts = DateTime.fromMillisecondsSinceEpoch(r['ts']! as int);
              return ListTile(
                title: Text('${(r['lat']! as double).toStringAsFixed(6)}, '
                    '${(r['lon']! as double).toStringAsFixed(6)}'),
                subtitle: Text('${ts.toLocal()} - ${r['source']}'),
                trailing: Text('\u00b1${(r['accuracy']! as num).toStringAsFixed(0)} m'),
              );
            },
          );
        },
      ),
    );
  }
}