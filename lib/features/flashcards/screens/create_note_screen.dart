import 'package:flutter/material.dart';
import '../../../core/core.dart';

class CreateNoteScreen extends StatefulWidget {
  final Function(Note) onNoteCreated;
  final Function(Note)? onNoteUpdated;
  final Note? note; // 👈 nullable, if provided we are editing

  const CreateNoteScreen({
    super.key,
    required this.onNoteCreated,
    this.onNoteUpdated,
    this.note,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill if editing
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.note?.tags?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }

      final tags = _tagsController.text.trim().isEmpty
          ? <String>[]
          : _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      if (widget.note == null) {
        // ✅ Create new note
        final note = await _dataService.createNote(
          _titleController.text.trim(),
          _contentController.text.trim(),
          tags: tags,
        );

        widget.onNoteCreated(note);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note "${note.title}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // ✏️ Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: tags,
        );

        await _dataService.updateNote(updatedNote);
        widget.onNoteUpdated?.call(updatedNote);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note "${updatedNote.title}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
Widget build(BuildContext context) {
  final isEditing = widget.note != null;

  return Scaffold(
    appBar: AppBar(
      title: Text(isEditing ? 'Edit Note' : 'Create Note'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title Field (no border, no icon)
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Note Title',
              hintText: 'Enter note title',
              border: InputBorder.none, // 👈 removed box border
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a note title';
              }
              if (value.trim().length < 2) {
                return 'Note title must be at least 2 characters';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const Divider(), // 👈 subtle separation

          // Content Field (no border, no icon)
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'Enter note content',
              border: InputBorder.none, // 👈 removed box border
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textInputAction: TextInputAction.newline,
          ),
          const Divider(),

          // Tags Field (keep label icon ✅)
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Enter tags separated by commas',
              border: InputBorder.none, // 👈 no box, but keep label icon
              prefixIcon: Icon(Icons.label),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEditing ? 'Save Changes' : 'Create Note',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
