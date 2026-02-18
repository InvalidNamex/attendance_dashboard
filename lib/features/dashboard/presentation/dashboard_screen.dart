import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const AppLoadingIndicator();
        }

        if (state is DashboardError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<DashboardBloc>().add(const LoadDashboard());
            },
          );
        }

        if (state is DashboardLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(const LoadDashboard());
            },
            child: _DashboardContent(state: state, l10n: l10n),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardLoaded state;
  final AppLocalizations l10n;

  const _DashboardContent({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crossAxisCount = Responsive.gridCrossAxisCount(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats cards grid
        GridView.count(
          crossAxisCount: crossAxisCount.clamp(1, 3),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _StatCard(
              title: l10n.totalUsers,
              value: '${state.totalUsers}',
              icon: Icons.people,
              color: AppColors.info,
            ),
            _StatCard(
              title: l10n.todayCheckIns,
              value: '${state.todayCheckIns}',
              icon: Icons.login,
              color: AppColors.checkIn,
            ),
            _StatCard(
              title: l10n.todayCheckOuts,
              value: '${state.todayCheckOuts}',
              icon: Icons.logout,
              color: AppColors.checkOut,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Transactions
        Text(
          l10n.recentTransactions,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (state.recentTransactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l10n.noData)),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.transactionId)),
                  DataColumn(label: Text(l10n.userId)),
                  DataColumn(label: Text(l10n.timestamp)),
                  DataColumn(label: Text(l10n.stampType)),
                ],
                rows: state.recentTransactions.map((t) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${t.id}')),
                      DataCell(Text('${t.userID}')),
                      DataCell(Text(AppDateUtils.formatDateTime(t.timestamp))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: t.isCheckIn
                                ? AppColors.checkIn.withValues(alpha: 0.15)
                                : AppColors.checkOut.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t.isCheckIn ? l10n.checkIn : l10n.checkOut,
                            style: TextStyle(
                              color: t.isCheckIn
                                  ? AppColors.checkIn
                                  : AppColors.checkOut,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
