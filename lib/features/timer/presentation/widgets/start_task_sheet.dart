import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checkyourtime/core/constants/category_colors.dart';
import '../../../tasks/tasks_providers.dart';
import '../../application/timer_controller.dart';

/// Bottom sheet: wybór kategorii lub utworzenie nowej. Po wyborze start odliczania.
void showStartTaskSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onTaskSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => _StartTaskSheetContent(
        scrollController: scrollController,
        onTaskSelected: onTaskSelected ?? () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

class _StartTaskSheetContent extends ConsumerWidget {
  const _StartTaskSheetContent({
    required this.scrollController,
    required this.onTaskSelected,
  });

  final ScrollController scrollController;
  final VoidCallback onTaskSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final timerNotifier = ref.read(timerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Wybierz kategorię lub dodaj nową',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final category in categories)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: CategoryColors.parse(category.colorHex),
                        child: Text(
                          category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(category.name),
                      onTap: () async {
                        await timerNotifier.startWithCategory(category.id);
                        if (!context.mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          onTaskSelected();
                        });
                      },
                    ),
                  const Divider(height: 24),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    title: const Text('Nowa kategoria'),
                    subtitle: const Text('np. Matematyka, Siłownia – dodaj i zacznij odliczanie'),
                    onTap: () => _showNewCategoryForm(context, ref, timerNotifier),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Błąd: $err', style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNewCategoryForm(
    BuildContext mainSheetContext,
    WidgetRef ref,
    TimerController timerNotifier,
  ) {
    final nameController = TextEditingController();
    showModalBottomSheet<void>(
      context: mainSheetContext,
      isScrollControlled: true,
      builder: (formContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(formContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nowa kategoria',
                  style: Theme.of(formContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa (np. Matematyka, Siłownia)',
                    hintText: 'Wpisz nazwę',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => _submitNewCategory(
                    formContext,
                    mainSheetContext,
                    value.trim(),
                    timerNotifier,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _submitNewCategory(
                    formContext,
                    mainSheetContext,
                    nameController.text.trim(),
                    timerNotifier,
                  ),
                  child: const Text('Dodaj i start'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(formContext).pop(),
                  child: const Text('Anuluj'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => nameController.dispose());
  }

  Future<void> _submitNewCategory(
    BuildContext formContext,
    BuildContext mainSheetContext,
    String name,
    TimerController timerNotifier,
  ) async {
    if (name.isEmpty) return;
    final categoryId = await timerNotifier.createCategory(name);
    if (categoryId.isEmpty || !formContext.mounted) return;
    Navigator.of(formContext).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await timerNotifier.startWithCategory(categoryId);
      if (!mainSheetContext.mounted) return;
      Navigator.of(mainSheetContext).pop();
    });
  }
}
