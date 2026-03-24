import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/app_button.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundOrbs(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: const LinearGradient(
                                      colors: [AppColors.ocean, AppColors.mint],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.ocean.withValues(
                                          alpha: 0.24,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fact_check_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .scale(
                                  begin: const Offset(0.85, 0.85),
                                  curve: Curves.easeOutBack,
                                ),
                            const Gap(28),
                            Text(
                                  'Checklist local con autenticación y SQLite',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.08,
                                      ),
                                )
                                .animate()
                                .fadeIn(delay: 180.ms, duration: 450.ms)
                                .slideY(begin: 0.14, end: 0),
                            const Gap(16),
                            Text(
                                  'Ejemplo práctico para aprender un flujo real de registro, inicio de sesión y CRUD de listas de tareas agrupadas.',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                        height: 1.5,
                                      ),
                                )
                                .animate()
                                .fadeIn(delay: 260.ms, duration: 450.ms)
                                .slideY(begin: 0.18, end: 0),
                            const Gap(28),
                            if (authState.isBusy)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              AppButton(
                                label: 'Iniciar sesión',
                                icon: Icons.login_rounded,
                                onPressed: () => context.go('/login'),
                              ),
                              const Gap(14),
                              AppButton(
                                label: 'Crear cuenta',
                                isSecondary: true,
                                icon: Icons.person_add_alt_1_rounded,
                                onPressed: () => context.go('/register'),
                              ),
                            ],
                            const Gap(24),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.storage_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Text(
                                      'Todo corre localmente: SQLite para persistencia y Riverpod para estado.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 320.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -40,
          child: _Orb(
            size: 220,
            color: AppColors.ocean.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -60,
          child: _Orb(size: 260, color: AppColors.mint.withValues(alpha: 0.18)),
        ),
        Positioned(
          top: 160,
          left: -50,
          child: _Orb(
            size: 140,
            color: AppColors.coral.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(
          begin: 0.96,
          end: 1.04,
          duration: AppConstants.defaultAnimationDuration * 4,
        );
  }
}
