import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../models/penalty_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wall of Shame')),
      body: StreamBuilder<List<PenaltyModel>>(
        stream: StorageService().watchAllPenalties(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ERROR: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final penalties = snapshot.data!;
          if (penalties.isEmpty) {
            return const Center(child: Text('No penalties yet.'));
          }
          return ListView.builder(
            itemCount: penalties.length,
            itemBuilder: (context, i) {
              final p = penalties[i];
              return ListTile(
                title: Text('Lost \$${p.lossAmount.toStringAsFixed(2)}'),
                subtitle: Text('${p.createdAt}\n${p.photoUrl}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}