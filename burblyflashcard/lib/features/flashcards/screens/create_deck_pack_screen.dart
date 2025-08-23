import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/core.dart';


class CreateDeckPackScreen extends StatefulWidget {
  final Function(DeckPack) onDeckPackCreated;

  const CreateDeckPackScreen({
    super.key,
    required this.onDeckPackCreated,
  });

  @override
  State<CreateDeckPackScreen> createState() => _CreateDeckPackScreenState();
}

class _CreateDeckPackScreenState extends State<CreateDeckPackScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<String> _colorOptions = [
    'FF9800', // Orange
    'E91E63', // Pink
    '9C27B0', // Purple
    '673AB7', // Deep Purple
    '3F51B5', // Indigo
    '2196F3', // Blue
    '00BCD4', // Cyan
    '009688', // Teal
    '4CAF50', // Green
    '8BC34A', // Light Green
    'CDDC39', // Lime
    'FFEB3B', // Yellow
    'FFC107', // Amber
    'FF5722', // Deep Orange
    '795548', // Brown
    '9E9E9E', // Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createDeckPack() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }

      // Generate a random color for the deck pack
      final random = Random();
      final randomColor = _colorOptions[random.nextInt(_colorOptions.length)];
      
      final deckPack = await _dataService.createDeckPack(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        coverColor: randomColor,
      );

      widget.onDeckPackCreated(deckPack);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck pack "${deckPack.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating deck pack: ${e.toString()}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Deck Pack'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Pack Name',
                hintText: 'Enter deck pack name',
                prefixIcon: Icon(
                  Icons.folder,
                  color: Theme.of(context).primaryColor,
                ),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _nameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a pack name';
                }
                if (value.trim().length < 2) {
                  return 'Pack name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Pack name must be less than 50 characters';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              onChanged: (value) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return isFocused 
                    ? Text('$currentLength/$maxLength', style: TextStyle(color: Theme.of(context).hintColor))
                    : null;
              },
            ),
            const SizedBox(height: 20),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter pack description (optional)',
                prefixIcon: Icon(
                  Icons.description,
                  color: Theme.of(context).primaryColor,
                ),
                suffixIcon: _descriptionController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _descriptionController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return isFocused 
                    ? Text('$currentLength/$maxLength', style: TextStyle(color: Theme.of(context).hintColor))
                    : null;
              },
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createDeckPack,
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
                    : const Text(
                        'Create Deck Pack',
                        style: TextStyle(
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
