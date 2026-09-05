import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../models/penalty_model.dart';
import '../../widgets/crypto888_ui.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C8.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              C8Header(
                title: 'Wall of Shame',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 18),
              const Text(
                'Latest Penalties',
                style: TextStyle(
                  color: Color.fromARGB(255, 24, 14, 14),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Losses shared by traders after completing their penalty photo.',
                style: TextStyle(color: C8.muted, height: 1.4),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: StreamBuilder<List<PenaltyModel>>(
                  stream: StorageService().watchAllPenalties(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: C8Status(text: 'Unable to load leaderboard.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: C8.lime),
                      );
                    }
                    final penalties = snapshot.data!;
                    if (penalties.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              color: C8.muted,
                              size: 44,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No penalties yet.',
                              style: TextStyle(color: C8.muted),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: penalties.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = penalties[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: C8.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: C8.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: C8.red.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.sentiment_dissatisfied_rounded,
                                  color: C8.red,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lost \$${p.lossAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.createdAt}',
                                      style: const TextStyle(
                                        color: C8.muted,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: C8.muted,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
