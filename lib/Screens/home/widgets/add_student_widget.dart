import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:student_database/db/functions/db_functions.dart';
import 'package:student_database/db/model/data_model.dart';

class AddStudentWidget extends StatefulWidget {
  const AddStudentWidget({super.key});

  @override
  State<AddStudentWidget> createState() => _AddStudentWidgetState();
}

class _AddStudentWidgetState extends State<AddStudentWidget> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _placeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker picker = ImagePicker();
  Uint8List? _imageData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, right: 50),
      child: Form(
        autovalidateMode: AutovalidateMode.always,
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.max, children: [
          const SizedBox(height: 20),
          imageProfile(),
          _imageData == null
              ? const Text(
                  'Select your image',
                  style: TextStyle(color: Colors.red),
                )
              : const SizedBox(),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Full name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter full name';
              } else if (value.contains(RegExp(r'\d'))) {
                return 'Name must be in letters';
              } else {
                return null;
              }
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Age',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your age';
              } else if (int.tryParse(value) == null || int.parse(value) > 99) {
                return 'Enter a valid age';
              } else {
                return null;
              }
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _placeController,
            decoration: const InputDecoration(
              hintText: 'Place',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your place';
              } else {
                return null;
              }
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Phone number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter Phone number';
                } else if (value.length < 10) {
                  return 'Enter a valid phone number';
                } else {
                  return null;
                }
              }),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_imageData == null) {
                  // Show a warning if no image is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an image'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  onAddStudentButtonClicked();
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text('Successfully added'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Back'),
                          )
                        ],
                      );
                    },
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Student'),
          ),
        ]),
      ),
    );
  }

  Widget imageProfile() {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.blueGrey,
              image: _imageData != null
                  ? DecorationImage(
                      fit: BoxFit.cover,
                      image: MemoryImage(_imageData!),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (builder) => bottomsheet(),
                );
              },
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomsheet() {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: <Widget>[
          const Text(
            'Choose your photo',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton.icon(
                onPressed: () {
                  pickImage(ImageSource.gallery);
                },
                icon: const Icon(Icons.image),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final image = await picker.pickImage(
        source: source); // Use the picker to pick an image
    if (image != null) {
      final bytes = await image.readAsBytes(); // Read the image as bytes
      setState(() {
        _imageData = bytes; // Store the bytes in the state
      });
    }
    Navigator.of(context).pop(); // Close the bottom sheet
  }

  Future<void> onAddStudentButtonClicked() async {
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final place = _placeController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty ||
        age.isEmpty ||
        place.isEmpty ||
        phone.isEmpty ||
        _imageData == null) {
      // Validation for empty fields and image
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields and select an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final student = StudentModel(
      name: name,
      age: age,
      place: place,
      phone: phone,
      imagePath: base64.encode(_imageData!), // Encode the image bytes to base64
    );

    await DBFunctions.instance.addStudent(student);

    // Clear the form fields and image data after submission
    _nameController.clear();
    _ageController.clear();
    _placeController.clear();
    _phoneController.clear();
    setState(() {
      _imageData = null;
    });

    // Show a success message
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Successfully added'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
