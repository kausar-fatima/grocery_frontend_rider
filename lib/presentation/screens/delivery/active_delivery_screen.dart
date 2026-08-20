import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../logic/calls/calls_cubit.dart';
import '../../../logic/delivery/delivery_cubit.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/delivery_map.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final int orderId;
  const ActiveDeliveryScreen({super.key, required this.orderId});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<DeliveryCubit>();
      cubit.refreshActive(widget.orderId);
      if (cubit.state.active?.status == OrderStatus.onTheWay &&
          !cubit.state.sharing) {
        cubit.startSharing(widget.orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DeliveryCubit, DeliveryState>(
        builder: (context, state) {
          final order = state.active;
          if (order == null || order.id != widget.orderId) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              Positioned.fill(
                child: DeliveryMap(
                  store: order.hasStoreLocation
                      ? LatLng(order.storeLat!, order.storeLng!)
                      : null,
                  destination: order.hasDestLocation
                      ? LatLng(order.destLat!, order.destLng!)
                      : null,
                  rider: order.hasRiderLocation
                      ? LatLng(order.riderLat!, order.riderLng!)
                      : null,
                  route: state.route,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      if (state.sharing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.gps_fixed_rounded,
                                  color: AppColors.primary, size: 16),
                              SizedBox(width: 6),
                              Text('Sharing location',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _DeliveryPanel(order: order, sharing: state.sharing),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeliveryPanel extends StatelessWidget {
  final Order order;
  final bool sharing;
  const _DeliveryPanel({required this.order, required this.sharing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17)),
                      Text(order.status.label,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Text('\$${order.earning.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customer?.name ?? 'Customer',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(order.address ?? 'No address',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  _CircleAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => context.push(
                        '${AppRoutes.chat}/${order.id}?name=${Uri.encodeComponent(order.customer?.name ?? 'Customer')}'),
                  ),
                  const SizedBox(width: 8),
                  _CircleAction(
                    icon: Icons.call_rounded,
                    filled: true,
                    onTap: () {
                      final customerId = order.customer?.id;
                      if (customerId != null) {
                        context.read<CallsCubit>().initiate(
                            calleeId: customerId, orderId: order.id);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(order: order),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Order order;
  const _ActionButton({required this.order});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeliveryCubit>();
    switch (order.status) {
      case OrderStatus.pickedUp:
        return _button(
          'Start delivery',
          Icons.navigation_rounded,
          () {
            cubit.advanceStatus(order.id, OrderStatus.onTheWay);
            cubit.startSharing(order.id);
          },
        );
      case OrderStatus.onTheWay:
        return _button(
          'Mark as delivered',
          Icons.check_circle_outline_rounded,
          () async {
            final ok =
                await cubit.advanceStatus(order.id, OrderStatus.delivered);
            if (ok && context.mounted) {
              await cubit.loadMine();
              if (context.mounted) context.pop();
            }
          },
        );
      case OrderStatus.delivered:
        return _banner('Delivered — great job! 🎉');
      default:
        return _banner('Waiting to pick up from the store.');
    }
  }

  Widget _button(String label, IconData icon, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _banner(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
      );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _CircleAction(
      {required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.white,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: Icon(icon,
            size: 20,
            color: filled ? AppColors.white : AppColors.textPrimary),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
