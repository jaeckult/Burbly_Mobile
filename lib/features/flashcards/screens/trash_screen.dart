import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/models/trash_item.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final DataService _dataService = DataService();
  List<TrashItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }
      final items = await _dataService.getTrashItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restore(TrashItem item) async {
    await _dataService.restoreTrashItem(item);
    await _load();
    if (mounted) {
      SnackbarUtils.showSuccessSnackbar(context, 'Restored ${item.itemType}');
    }
  }

  Future<void> _deleteForever(TrashItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forever?'),
        content: const Text('This item will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await _dataService.deleteTrashItemForever(item.id);
      await _load();
      if (mounted) {
        SnackbarUtils.showWarningSnackbar(context, 'Deleted forever');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Trash is empty'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_iconFor(item.itemType)),
                          title: Text(_titleFor(item)),
                          subtitle: Text('Deleted ${_formatDate(item.deletedAt)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                onPressed: () => _restore(item),
                                tooltip: 'Restore',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _deleteForever(item),
                                tooltip: 'Delete forever',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Items will be deleted after 30 days',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'deck':
        return Icons.folder;
      case 'flashcard':
        return Icons.style;
      case 'note':
        return Icons.note;
      default:
        return Icons.delete_outline;
    }
  }

  String _titleFor(TrashItem item) {
    switch (item.itemType) {
      case 'deck':
        return (item.payload['name'] as String?) ?? 'Deck';
      case 'flashcard':
        final q = (item.payload['question'] as String?) ?? 'Flashcard';
        return q.length > 40 ? '${q.substring(0, 40)}…' : q;
      case 'note':
        return (item.payload['title'] as String?) ?? 'Note';
      default:
        return item.itemType;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
