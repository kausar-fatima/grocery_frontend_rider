import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../logic/delivery/delivery_cubit.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/error_view.dart';
import '../../widgets/notification_bell.dart';

class AvailableOrdersScreen extends StatelessWidget {
  const AvailableOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available deliveries'),
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBell(),
          IconButton(
            onPressed: () => context.read<DeliveryCubit>().loadAvailable(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<DeliveryCubit, DeliveryState>(
          builder: (context, state) {
            if (state.availableStatus == LoadStatus.loading ||
                state.availableStatus == LoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.availableStatus == LoadStatus.error) {
              return ErrorView(
                message: state.error ?? 'Could not load deliveries.',
                onRetry: () => context.read<DeliveryCubit>().loadAvailable(),
              );
            }
            if (state.available.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🛵', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 12),
                      Text('No deliveries available',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('New orders marked ready by stores will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<DeliveryCubit>().loadAvailable(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: state.available.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _AvailableCard(order: state.available[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  final Order order;
  const _AvailableCard({required this.order});

  Future<void> _accept(BuildContext context) async {
    final cubit = context.read<DeliveryCubit>();
    final accepted = await cubit.accept(order.id);
    if (accepted != null && context.mounted) {
      context.push('${AppRoutes.delivery}/${order.id}');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(cubit.state.error ?? 'Could not accept order.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
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
                    Text('${order.itemCount} items · ${order.customer?.name ?? 'Customer'}',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Earn',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  Text('\$${order.earning.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 16)),
                ],
              ),
            ],
          ),
          if ((order.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order.address!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(46)),
              onPressed: () => _accept(context),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Accept delivery'),
            ),
          ),
        ],
      ),
    );
  }
}
