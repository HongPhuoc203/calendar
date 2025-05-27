// screens/events/add_event_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
// import '../../models/event_model.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddEventScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _expenseController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedDateTime = widget.selectedDate!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Event Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _expenseController,
                decoration: InputDecoration(labelText: 'Expense Amount'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text('Date & Time'),
                subtitle: Text(_selectedDateTime.toString()),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      await eventProvider.addEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        dateTime: _selectedDateTime,
        location: _locationController.text,
        cost: double.tryParse(_expenseController.text) ?? 0.0,
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _expenseController.dispose();
    super.dispose();
  }
}