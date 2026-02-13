import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_state.dart';
import 'package:wow_companion/features/builds/presentation/widgets/create_build_dialog.dart';

class BuildsListPage extends StatelessWidget {
  const BuildsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuildsCubit>()..loadBuilds(),
      child: const _BuildsListView(),
    );
  }
}

class _BuildsListView extends StatelessWidget {
  const _BuildsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Builds')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WowTheme.primaryGold,
        foregroundColor: WowTheme.darkBackground,
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<BuildsCubit, BuildsState>(
        builder: (context, state) {
          if (state is BuildsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: WowTheme.primaryGold),
            );
          }
          if (state is BuildsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: WowTheme.textSecondary),
              ),
            );
          }
          if (state is BuildsLoaded) {
            if (state.builds.isEmpty) return _buildEmpty();
            return _buildList(context, state.builds);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.construction, size: 64, color: WowTheme.textSecondary),
        SizedBox(height: 12),
        Text(
          'No builds yet',
          style: TextStyle(color: WowTheme.textSecondary, fontSize: 16),
        ),
        SizedBox(height: 4),
        Text(
          'Tap + to create your first build',
          style: TextStyle(color: WowTheme.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildList(BuildContext context, List<Build> builds) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: builds.length,
      itemBuilder: (_, i) => _BuildCard(buildData: builds[i]),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BuildsCubit>(),
        child: const CreateBuildDialog(),
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  final Build buildData;
  const _BuildCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: WowTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: WowTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      buildData.name,
                      style: const TextStyle(
                        color: WowTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: WowTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              if (buildData.characterRefDisplay != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: WowTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      buildData.characterRefDisplay!,
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: buildData.progress,
                        backgroundColor: WowTheme.border,
                        color: WowTheme.primaryGold,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${buildData.obtainedSlots}/${buildData.totalSlots}',
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: WowTheme.surfaceDark,
        title: const Text(
          'Delete build',
          style: TextStyle(color: WowTheme.textPrimary),
        ),
        content: Text(
          'Delete "${buildData.name}"?',
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: WowTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<BuildsCubit>().deleteBuild(buildData.id);
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: WowTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }
}
