import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxiuuse/adminmodel/profilemodel.dart';
import 'package:taxiuuse/adminservice/provider.dart';

class AddEditUserScreen extends StatefulWidget {
  final profilemodel? user;
  final bool isEdit;

  const AddEditUserScreen({
    Key? key,
    this.user,
    required this.isEdit,
  }) : super(key: key);

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _role;
  late TextEditingController _priceController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;
  late TextEditingController _ratingController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _role = TextEditingController(
      text: widget.isEdit ? (widget.user?.role ?? 'driver') : 'driver',
    );
    _priceController = TextEditingController(
        text: widget.user?.price.toString() ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _experienceController =
        TextEditingController(text: widget.user?.experience ?? '');
    _ratingController =
        TextEditingController(text: widget.user?.rating.toString() ?? '');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userData = {
          'name': _nameController.text.trim(),
          'price': int.parse(_priceController.text.trim()),
          'role': _role.text.trim(),
          'phone': _phoneController.text.trim(),
          'experience': _experienceController.text.trim(),
          'rating': double.parse(_ratingController.text.trim()),
        };

        final success = widget.isEdit && widget.user != null
            ? await userProvider.updateUser(
                widget.user!.id,
                userData,
              )
            : await userProvider.addUser(
                userData,
              );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEdit
                    ? 'Driver updated successfully'
                    : 'Driver added successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _ratingController.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Driver' : 'Add New Driver'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              
              // Name Field
              TextFormField(
                controller: _role,
                
                decoration: InputDecoration(
                  labelText: 'Role',
                
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter role';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter valid phone number (10 digits)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),




              // Experience Field
              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: 'Experience (years)',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter experience';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price per km',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Rating Field
              TextFormField(
                controller: _ratingController,
                decoration: InputDecoration(
                  labelText: 'Rating (0-5)',
                  prefixIcon: const Icon(Icons.star),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rating';
                  }
                  final rating = double.tryParse(value);
                  if (rating == null) {
                    return 'Please enter valid number';
                  }
                  if (rating < 0 || rating > 5) {
                    return 'Rating must be between 0 and 5';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    widget.isEdit ? 'Update Driver' : 'Save Driver',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
