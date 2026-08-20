import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../logic/delivery/delivery_cubit.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/error_view.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My deliveries'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.read<DeliveryCubit>().loadMine(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<DeliveryCubit, DeliveryState>(
          builder: (context, state) {
            if (state.mineStatus == LoadStatus.loading ||
                state.mineStatus == LoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.mineStatus == LoadStatus.error) {
              return ErrorView(
                message: state.error ?? 'Could not load deliveries.',
                onRetry: () => context.read<DeliveryCubit>().loadMine(),
              );
            }
            final active = state.mine
                .where((o) =>
                    o.status == OrderStatus.pickedUp ||
                    o.status == OrderStatus.onTheWay)
                .toList();
            if (active.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('📦', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 12),
                      Text('No active deliveries',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('Accept an order from the Available tab to start.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<DeliveryCubit>().loadMine(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: active.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _DeliveryCard(order: active[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Order order;
  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<DeliveryCubit>().setActive(order);
        context.push('${AppRoutes.delivery}/${order.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.two_wheeler_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(order.status.label,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  if ((order.address ?? '').isNotEmpty)
                    Text(order.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
