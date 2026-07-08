import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/category_avatar.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.categories),
          bottom: TabBar(
            tabs: [Tab(text: l.expense), Tab(text: l.income)],
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton(
            key: const Key('add-category-fab'),
            onPressed: () {
              final isExpense = DefaultTabController.of(ctx).index == 0;
              _showCategoryDialog(
                ctx,
                ref,
                isExpense ? TransactionKind.expense : TransactionKind.income,
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(kind: TransactionKind.expense),
            _CategoryList(kind: TransactionKind.income),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(
      BuildContext context, WidgetRef ref, TransactionKind kind,
      {Category? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? error;
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? l.newCategory : l.editCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l.name),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style:
                          TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel)),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(categoryControllerProvider).save(
                        id: existing?.id,
                        name: nameCtrl.text,
                        kind: kind,
                        iconCodePoint: existing?.iconCodePoint ??
                            Icons.category.codePoint,
                        colorValue:
                            existing?.colorValue ?? Colors.blueGrey.toARGB32(),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                } on DomainException catch (e) {
                  setLocal(() => error = e.message);
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.kind});
  final TransactionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final l = AppLocalizations.of(context);
    return cats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
      data: (list) {
        final filtered = list.where((c) => c.kind == kind).toList();
        return ListView(
          children: filtered
              .map((c) => ListTile(
                    leading: CategoryAvatar(category: c),
                    title: Text(c.name),
                    trailing: c.isDefault
                        ? Chip(label: Text(l.defaultLabel))
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(categoryControllerProvider)
                                    .delete(c.id);
                              } on DomainException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message)));
                                }
                              }
                            },
                          ),
                  ))
              .toList(),
        );
      },
    );
  }
}
