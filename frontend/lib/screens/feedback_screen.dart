import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'feedback';
  String _selectedCategory = 'other';
  String _selectedPriority = 'medium';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _rating = 0;
  bool _loading = false;
  List<dynamic> _myFeedbacks = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadMyFeedbacks();
  }

  void _loadMyFeedbacks() async {
    final feedbacks = await ApiService.getMyFeedback();
    setState(() {
      _myFeedbacks = feedbacks;
    });
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final success = await ApiService.createFeedback({
      'type': _selectedType,
      'category': _selectedCategory,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'priority': _selectedPriority,
      if (_rating > 0) 'rating': _rating,
    });

    setState(() => _loading = false);

    if (success) {
      _titleController.clear();
      _descriptionController.clear();
      _rating = 0;
      _loadMyFeedbacks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback submitted successfully!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit feedback"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feedback & Support"),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.add : Icons.history),
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
      body: _showHistory
          ? _buildHistoryView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type Selection
                    const Text(
                      "Type",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'feedback', label: Text('Feedback')),
                        ButtonSegment(value: 'suggestion', label: Text('Suggestion')),
                        ButtonSegment(value: 'complaint', label: Text('Complaint')),
                        ButtonSegment(value: 'issue', label: Text('Issue')),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _selectedType = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Category
                    const Text(
                      "Category",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'food', child: Text('Food')),
                        DropdownMenuItem(value: 'service', child: Text('Service')),
                        DropdownMenuItem(value: 'app', child: Text('App')),
                        DropdownMenuItem(value: 'payment', child: Text('Payment')),
                        DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? "Please enter a title" : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) => value?.isEmpty ?? true
                          ? "Please enter a description"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Rating (for feedback)
                    if (_selectedType == 'feedback') ...[
                      const Text(
                        "Rating",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                            onPressed: () => setState(() => _rating = index + 1),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Priority (for issues/complaints)
                    if (_selectedType == 'issue' || _selectedType == 'complaint') ...[
                      const Text(
                        "Priority",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'low', label: Text('Low')),
                          ButtonSegment(value: 'medium', label: Text('Medium')),
                          ButtonSegment(value: 'high', label: Text('High')),
                          ButtonSegment(value: 'urgent', label: Text('Urgent')),
                        ],
                        selected: {_selectedPriority},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _selectedPriority = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitFeedback,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text("Submit Feedback"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHistoryView() {
    if (_myFeedbacks.isEmpty) {
      return const Center(
        child: Text("No feedback submitted yet"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myFeedbacks.length,
      itemBuilder: (context, index) {
        final feedback = _myFeedbacks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    feedback['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(feedback['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      feedback['status']?.toUpperCase() ?? 'OPEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(feedback['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              if (feedback['adminResponse'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Admin Response:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(feedback['adminResponse']),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'in-progress':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}


