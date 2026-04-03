import '../models.dart';

class TagDeleteAction {
  final bool removeFromTransactions;
  final String? replacementTagName;

  const TagDeleteAction.removeEverywhere()
      : removeFromTransactions = true,
        replacementTagName = null;

  const TagDeleteAction.replaceWith(this.replacementTagName)
      : removeFromTransactions = false;
}

class TagMutationResult {
  final List<TagDefinition> tags;
  final List<Transaction> transactions;
  final List<BudgetPlan> budgets;

  const TagMutationResult({
    required this.tags,
    required this.transactions,
    required this.budgets,
  });
}

class TagManagementService {
  bool tagExists(List<TagDefinition> tags, String name, {String? ignoreTagId}) {
    final normalized = name.trim().toLowerCase();
    return tags.any((t) => t.id != ignoreTagId && t.name.trim().toLowerCase() == normalized);
  }

  TagMutationResult createTag({
    required List<TagDefinition> tags,
    required TagDefinition tag,
    required List<Transaction> transactions,
    required List<BudgetPlan> budgets,
  }) {
    if (tagExists(tags, tag.name)) {
      throw ArgumentError('Un tag avec ce nom existe déjà.');
    }

    return TagMutationResult(
      tags: [...tags, tag],
      transactions: transactions,
      budgets: budgets,
    );
  }

  TagMutationResult updateTag({
    required List<TagDefinition> tags,
    required TagDefinition updatedTag,
    required List<Transaction> transactions,
    required List<BudgetPlan> budgets,
  }) {
    final index = tags.indexWhere((t) => t.id == updatedTag.id);
    if (index == -1) {
      throw ArgumentError('Tag introuvable.');
    }
    if (tagExists(tags, updatedTag.name, ignoreTagId: updatedTag.id)) {
      throw ArgumentError('Un autre tag avec ce nom existe déjà.');
    }

    final previousName = tags[index].name;
    final nextName = updatedTag.name;

    final patchedTags = [...tags]..[index] = updatedTag;
    final patchedTxs = _renameTagInTransactions(transactions, previousName, nextName);
    final patchedBudgets = _renameTagInBudgets(budgets, previousName, nextName);

    return TagMutationResult(
      tags: patchedTags,
      transactions: patchedTxs,
      budgets: patchedBudgets,
    );
  }

  TagMutationResult deleteTag({
    required List<TagDefinition> tags,
    required String tagId,
    required TagDeleteAction action,
    required List<Transaction> transactions,
    required List<BudgetPlan> budgets,
  }) {
    final existing = tags.where((t) => t.id == tagId).toList();
    if (existing.isEmpty) {
      throw ArgumentError('Tag introuvable.');
    }
    final removedTag = existing.first;

    List<Transaction> patchedTxs;
    List<BudgetPlan> patchedBudgets;
    if (action.replacementTagName != null && action.replacementTagName!.trim().isNotEmpty) {
      patchedTxs = _renameTagInTransactions(
        transactions,
        removedTag.name,
        action.replacementTagName!.trim(),
      );
      patchedBudgets = _renameTagInBudgets(
        budgets,
        removedTag.name,
        action.replacementTagName!.trim(),
      );
    } else if (action.removeFromTransactions) {
      patchedTxs = _removeTagFromTransactions(transactions, removedTag.name);
      patchedBudgets = _removeTagFromBudgets(budgets, removedTag.name);
    } else {
      patchedTxs = transactions;
      patchedBudgets = budgets;
    }

    return TagMutationResult(
      tags: tags.where((t) => t.id != tagId).toList(),
      transactions: patchedTxs,
      budgets: patchedBudgets,
    );
  }

  List<Transaction> assignTagsToTransaction(
    List<Transaction> transactions, {
    required String transactionId,
    required List<String> tagNames,
  }) {
    final normalized = _uniqueTagNames(tagNames);
    return transactions.map((tx) {
      if (tx.id != transactionId) return tx;
      return Transaction(
        id: tx.id,
        amount: tx.amount,
        description: tx.description,
        type: tx.type,
        date: tx.date,
        walletId: tx.walletId,
        fromWalletId: tx.fromWalletId,
        toWalletId: tx.toWalletId,
        categoryId: tx.categoryId,
        tags: normalized,
        isRecurring: tx.isRecurring,
        relatedDebtId: tx.relatedDebtId,
      );
    }).toList();
  }

  List<Transaction> _renameTagInTransactions(
    List<Transaction> transactions,
    String previousName,
    String nextName,
  ) {
    final prev = previousName.trim().toLowerCase();
    return transactions.map((tx) {
      if (!tx.tags.any((t) => t.trim().toLowerCase() == prev)) return tx;
      final updatedTags = tx.tags
          .map((t) => t.trim().toLowerCase() == prev ? nextName : t)
          .toList();
      return Transaction(
        id: tx.id,
        amount: tx.amount,
        description: tx.description,
        type: tx.type,
        date: tx.date,
        walletId: tx.walletId,
        fromWalletId: tx.fromWalletId,
        toWalletId: tx.toWalletId,
        categoryId: tx.categoryId,
        tags: _uniqueTagNames(updatedTags),
        isRecurring: tx.isRecurring,
        relatedDebtId: tx.relatedDebtId,
      );
    }).toList();
  }

  List<Transaction> _removeTagFromTransactions(List<Transaction> transactions, String tagName) {
    final normalized = tagName.trim().toLowerCase();
    return transactions.map((tx) {
      if (!tx.tags.any((t) => t.trim().toLowerCase() == normalized)) return tx;
      final updatedTags = tx.tags.where((t) => t.trim().toLowerCase() != normalized).toList();
      return Transaction(
        id: tx.id,
        amount: tx.amount,
        description: tx.description,
        type: tx.type,
        date: tx.date,
        walletId: tx.walletId,
        fromWalletId: tx.fromWalletId,
        toWalletId: tx.toWalletId,
        categoryId: tx.categoryId,
        tags: updatedTags,
        isRecurring: tx.isRecurring,
        relatedDebtId: tx.relatedDebtId,
      );
    }).toList();
  }

  List<BudgetPlan> _renameTagInBudgets(
    List<BudgetPlan> budgets,
    String previousName,
    String nextName,
  ) {
    final prev = previousName.trim().toLowerCase();
    return budgets.map((budget) {
      final includes = budget.tags
          .map((tag) => tag.trim().toLowerCase() == prev ? nextName : tag)
          .toList();
      final excludes = budget.excludedTags
          .map((tag) => tag.trim().toLowerCase() == prev ? nextName : tag)
          .toList();
      return BudgetPlan(
        id: budget.id,
        name: budget.name,
        periodType: budget.periodType,
        startDate: budget.startDate,
        endDate: budget.endDate,
        walletIds: budget.walletIds,
        categoryIds: budget.categoryIds,
        includeAllCategories: budget.includeAllCategories,
        tags: _uniqueTagNames(includes),
        excludedTags: _uniqueTagNames(excludes),
        includedTagTypes: budget.includedTagTypes,
        excludedTagTypes: budget.excludedTagTypes,
        amount: budget.amount,
        enableAlerts: budget.enableAlerts,
        enableProgressiveAdjustment: budget.enableProgressiveAdjustment,
        dependencyBudgetId: budget.dependencyBudgetId,
        dependencyPercentLimit: budget.dependencyPercentLimit,
        repeatFrequency: budget.repeatFrequency,
        repeatAdjustmentPercent: budget.repeatAdjustmentPercent,
        createdAt: budget.createdAt,
      );
    }).toList();
  }

  List<BudgetPlan> _removeTagFromBudgets(List<BudgetPlan> budgets, String tagName) {
    final normalized = tagName.trim().toLowerCase();
    return budgets.map((budget) {
      final includes =
          budget.tags.where((t) => t.trim().toLowerCase() != normalized).toList();
      final excludes = budget.excludedTags
          .where((t) => t.trim().toLowerCase() != normalized)
          .toList();
      return BudgetPlan(
        id: budget.id,
        name: budget.name,
        periodType: budget.periodType,
        startDate: budget.startDate,
        endDate: budget.endDate,
        walletIds: budget.walletIds,
        categoryIds: budget.categoryIds,
        includeAllCategories: budget.includeAllCategories,
        tags: includes,
        excludedTags: excludes,
        includedTagTypes: budget.includedTagTypes,
        excludedTagTypes: budget.excludedTagTypes,
        amount: budget.amount,
        enableAlerts: budget.enableAlerts,
        enableProgressiveAdjustment: budget.enableProgressiveAdjustment,
        dependencyBudgetId: budget.dependencyBudgetId,
        dependencyPercentLimit: budget.dependencyPercentLimit,
        repeatFrequency: budget.repeatFrequency,
        repeatAdjustmentPercent: budget.repeatAdjustmentPercent,
        createdAt: budget.createdAt,
      );
    }).toList();
  }

  List<String> _uniqueTagNames(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in tags) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) continue;
      final key = cleaned.toLowerCase();
      if (seen.add(key)) result.add(cleaned);
    }
    return result;
  }
}
