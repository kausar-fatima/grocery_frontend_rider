import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../logic/delivery/delivery_cubit.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & earnings'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<DeliveryCubit, DeliveryState>(
          builder: (context, state) {
            final completed = state.mine
                .where((o) => o.status == OrderStatus.delivered)
                .toList();
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<DeliveryCubit>().loadMine(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _EarningsCard(
                    earnings: state.todayEarnings,
                    count: state.completedCount,
                  ),
                  const SizedBox(height: 20),
                  const Text('Completed deliveries',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (completed.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No completed deliveries yet.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...completed.map((o) => _HistoryRow(order: o)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final double earnings;
  final int count;
  const _EarningsCard({required this.earnings, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total earnings',
                    style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: 13)),
                const SizedBox(height: 6),
                Text('\$${earnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.local_shipping_rounded,
                  color: AppColors.white, size: 28),
              const SizedBox(height: 6),
              Text('$count trips',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Order order;
  const _HistoryRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  order.createdAt != null
                      ? DateFormat('MMM d, yyyy · HH:mm')
                          .format(order.createdAt!)
                      : 'Delivered',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('+\$${order.earning.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
