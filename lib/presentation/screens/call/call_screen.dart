import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/call.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/calls/calls_cubit.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _timer;
  int _seconds = 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthCubit>().userId ?? -1;
    return BlocListener<CallsCubit, CallsState>(
      listenWhen: (a, b) => a.active != b.active,
      listener: (context, state) {
        if (state.active == null) {
          if (context.canPop()) context.pop();
          return;
        }
        if (state.active!.status == CallStatus.accepted && _timer == null) {
          _startTimer();
        }
      },
      child: BlocBuilder<CallsCubit, CallsState>(
        builder: (context, state) {
          final call = state.active;
          if (call == null) {
            return const Scaffold(
                backgroundColor: AppColors.primaryDark,
                body: SizedBox.shrink());
          }
          final incoming = call.calleeId == myId;
          final otherName = incoming ? call.callerName : call.calleeName;
          final accepted = call.status == CallStatus.accepted;

          return Scaffold(
            backgroundColor: AppColors.primaryDark,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.white.withValues(alpha: 0.15),
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 48,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(otherName,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      accepted
                          ? _elapsed
                          : incoming
                              ? 'Incoming call…'
                              : 'Calling…',
                      style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 16),
                    ),
                    if (call.orderId != null) ...[
                      const SizedBox(height: 6),
                      Text('Order #${call.orderId}',
                          style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.6),
                              fontSize: 13)),
                    ],
                    const Spacer(),
                    _Controls(
                      call: call,
                      incoming: incoming,
                      accepted: accepted,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final Call call;
  final bool incoming;
  final bool accepted;
  const _Controls({
    required this.call,
    required this.incoming,
    required this.accepted,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallsCubit>();
    if (incoming && !accepted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallButton(
            icon: Icons.call_end_rounded,
            color: AppColors.error,
            label: 'Decline',
            onTap: () => cubit.decline(),
          ),
          _CallButton(
            icon: Icons.call_rounded,
            color: AppColors.success,
            label: 'Accept',
            onTap: () => cubit.answer(),
          ),
        ],
      );
    }
    return Column(
      children: [
        _CallButton(
          icon: Icons.call_end_rounded,
          color: AppColors.error,
          label: 'End call',
          onTap: () => cubit.end(),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.white)),
      ],
    );
  }
}
