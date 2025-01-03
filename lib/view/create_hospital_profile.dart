
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../main.dart';
import 'package:image/image.dart' as img;

import 'landing_page.dart'; // Import the image package



class ClinicProfileCreation extends StatefulWidget {
  final String clinicId;

  ClinicProfileCreation({required this.clinicId});

  @override
  _ClinicProfileCreationState createState() => _ClinicProfileCreationState();
}

class _ClinicProfileCreationState extends State<ClinicProfileCreation> with SingleTickerProviderStateMixin {
  final List<String> _locations = ["Perinthalmanna", "Manjeri", "Malappuram","Kozhikode","Mannarkkad","Melattur"];
  String? _selectedLocation;
  int _selectedDayIndex = 0;
  bool _isSubmitting = false;


  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profileImageBytes;
  TabController? _tabController;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();


  final List<DaySchedule> _weeklySchedule = [
    DaySchedule(day: 'Mon'),
    DaySchedule(day: 'Tue'),
    DaySchedule(day: 'Wed'),
    DaySchedule(day: 'Thu'),
    DaySchedule(day: 'Fri'),
    DaySchedule(day: 'Sat'),
    DaySchedule(day: 'Sun'),
  ];

  bool _isImageUploaded = false;

  String? _profileImageUrl;
  File? _medicalLicense;
  File? _otherDocument;
  final TextEditingController _treatmentController = TextEditingController();
  List<String> treatments = [];
  List<TextEditingController> treatmentControllers = [];

  bool _isLoading = false;
  bool _isImageTooLarge = false; // Flag to check if the image is above 1MB
  bool _isCompressing = false; // Flag to track if compression is happening


  @override
  void initState() {
    super.initState();
    _fetchClinicData();
    _tabController = TabController(length: 2, vsync: this);

    // Ensure _selectedLocation is valid or set it to null
    if (_selectedLocation != null && !_locations.contains(_selectedLocation)) {
      _selectedLocation = null;
    }
  }

  @override
  void dispose() {
    _treatmentController.dispose();
    for (var controller in treatmentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchClinicData() async {
    // Set the loading state to true at the beginning
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the currently authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the clinic data from Firestore using the user's UID
      DocumentSnapshot clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(user.uid)
          .get();

      // Check if the document exists in Firestore
      if (!clinicDoc.exists) {
        print("Document does not exist in Firestore.");
        return;
      }

      // Cast the document data to a Map
      Map<String, dynamic> data = clinicDoc.data() as Map<String, dynamic>;

      // Update the form fields and state with the fetched data
      setState(() {
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _contactEmailController.text = data['contact']?['email'] ?? '';
        _phoneController.text = data['contact']?['phone'] ?? '';
        _selectedLocation = data['location'] ?? '';

        // Validate if the selected location exists in the predefined list
        if (_selectedLocation != null && !_locations.contains(_selectedLocation)) {
          _selectedLocation = null;
        }

        // Load profile image URL if available
        _profileImageUrl = data['profilePhoto'];

        // Load available treatments
        List<dynamic>? fetchedTreatments = data['availableTreatments'];
        if (fetchedTreatments != null) {
          treatments = List<String>.from(fetchedTreatments);
          treatmentControllers = treatments
              .map((treatment) => TextEditingController(text: treatment))
              .toList();
        }

        // Parse and update the weekly schedule data
        List<dynamic>? schedule = data['operatingHours'];
        if (schedule != null) {
          for (var i = 0; i < _weeklySchedule.length; i++) {
            // Find matching day data in the schedule
            var dayData = schedule.firstWhere(
                  (element) => element['day'] == _weeklySchedule[i].day,
              orElse: () => null,
            );

            // If day data exists, update start and end times
            if (dayData != null) {
              _weeklySchedule[i].startTime = double.tryParse(dayData['startTime']);
              _weeklySchedule[i].endTime = double.tryParse(dayData['endTime']);
            }
          }
        }
      });
    } catch (e) {
      print("Error fetching clinic data: $e");
      // Show a snackbar if there's an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load clinic data. Please try again.'),
        ),
      );
    } finally {
      // Set the loading state to false when the process is complete
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getNextClinicId() async {
    final firestore = FirebaseFirestore.instance;
    DocumentReference docRef = firestore.collection('id_counters').doc('clinic_id_counter');

    try {
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        String initialClinicId = 'QV001';
        await docRef.set({'lastClinicId': initialClinicId});
        return initialClinicId;
      }

      String lastClinicId = doc['lastClinicId'];
      int numericPart = int.parse(lastClinicId.substring(2));
      numericPart++;
      String newClinicId = 'QV' + numericPart.toString().padLeft(3, '0');
      await docRef.update({'lastClinicId': newClinicId});
      return newClinicId;
    } catch (e) {
      throw Exception('Error generating clinic ID: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _contactEmailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedLocation == null ||
        (_profileImageBytes == null && _profileImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields including Clinic Logo')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;  // Start showing the loading animation
    });

    try {

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Generate the new clinic ID using _getNextClinicId()
      String clinicId = await _getNextClinicId();

      String? logoUrl = _profileImageUrl;  // Use the existing profile image if available

      // Upload new logo if available
      if (_profileImageBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('clinic_logos/${user!.uid}_logo.png');
        await storageRef.putData(_profileImageBytes!);
        logoUrl = await storageRef.getDownloadURL();
      }

      List<Map<String, dynamic>> scheduleData = _weeklySchedule.map((daySchedule) {
        return {
          'day': daySchedule.day,
          'startTime': daySchedule.startTime?? 0.0,
          'endTime': daySchedule.endTime?? 0.0,
          'open24Hours': daySchedule.open24Hours,
          'closed': daySchedule.closed,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('clinics').doc(clinicId).set({
        'clinicId': clinicId,
        'name': _nameController.text.trim(),
        'email': _contactEmailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'location': _selectedLocation,
        'operatingHours': scheduleData,
        'approvalStatus': 'pending',
        'user_id': user!.uid,
        'admins':[user!.email],
        'doctors':[],
        'staffs':[],
        'patient_counter':0,
        'booking_counter':0,
        'paidAmount_counter':0,
        if (logoUrl != null) 'profilePhoto': logoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Created successfully')),
      );

      // Navigate to the landing page after successful form submission
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LandingPage()),  // Replace with your landing page
      );

    } catch (e) {
      print('Error during form submission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Create profile. Please try again. $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;  // Stop showing the loading animation
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();

      // Check if the image is larger than 1MB
      if (imageBytes.lengthInBytes > 1000000) {
        setState(() {
          _isImageTooLarge = true;  // Set error flag
          _isImageUploaded = false; // Reset uploaded state
        });
        return;  // Stop further execution if image is too large
      }

      // Show the Lottie loading dialog while compressing the image
      setState(() {
        _isLoading = true;  // Start loading while compressing
      });

      // Compress the image (if within size limit)
      Uint8List? compressedImage = await compressImage(imageBytes);
      if (compressedImage != null) {
        setState(() {
          _profileImageBytes = compressedImage;
          _isImageUploaded = true;  // Mark the image as uploaded
          _isImageTooLarge = false; // Clear any previous size error
        });
      } else {
        setState(() {
          _isImageTooLarge = true; // Set error if compression fails
        });
      }

      setState(() {
        _isLoading = false;  // Stop loading after compression
      });
    }
  }


  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent dismissing the dialog
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,  // Transparent background
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/loading.json', width: 150, height: 150),  // Replace with your Lottie file
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> compressImage(Uint8List imageBytes, {bool isPng = false}) async {
    try {
      print('Original Image Size: ${imageBytes.lengthInBytes} bytes');

      // Decode the image from bytes
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode the image.');
        return null;
      }

      // Resize the image to a larger size (e.g., 400x400) for better quality
      img.Image resizedImage = img.copyResize(image, width: 400);  // Adjust size for better quality at 20KB

      int quality = 70; // Start with 70% quality
      Uint8List compressedImageBytes;

      if (isPng) {
        // PNG doesn't support adjustable quality, so just encode it as PNG
        compressedImageBytes = Uint8List.fromList(img.encodePng(resizedImage));

        print('Compressed PNG Image Size: ${compressedImageBytes.lengthInBytes} bytes');

        if (compressedImageBytes.lengthInBytes <= 20000) {
          return compressedImageBytes;
        } else {
          print("Unable to compress PNG image below 20KB.");
          return null;
        }

      } else {
        // JPEG compression, start with quality 70%
        compressedImageBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));

        print('Compressed JPEG Image Size (initial quality 70): ${compressedImageBytes.lengthInBytes} bytes');

        // Adjust the quality to keep the image between 19KB and 20KB
        while (compressedImageBytes.lengthInBytes < 19000 || compressedImageBytes.lengthInBytes > 20000) {
          if (compressedImageBytes.lengthInBytes < 19000 && quality < 95) {
            quality += 5; // Increase quality if it's too small
          } else if (compressedImageBytes.lengthInBytes > 20000 && quality > 0) {
            quality -= 5; // Decrease quality if it's too large
          }

          compressedImageBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
          print('Compressed JPEG Image Size (quality $quality): ${compressedImageBytes.lengthInBytes} bytes');

          // Stop once the size is between 19KB and 20KB
          if (compressedImageBytes.lengthInBytes >= 19000 && compressedImageBytes.lengthInBytes <= 20000) {
            print('Final Compressed JPEG Image Size: ${compressedImageBytes.lengthInBytes} bytes');
            return compressedImageBytes;
          }
        }

        return compressedImageBytes;
      }
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Main content, displayed only when not loading
          if (!_isSubmitting)
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Edit Profile",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  SizedBox(height: 16),
                                  _buildProfileImage(),
                                  SizedBox(height: 16),
                                  _buildPersonalInfo(),
                                  SizedBox(height: 16),
                                  _buildContactInfo(),
                                  SizedBox(height: 16),
                                  _buildScheduleInfo(),
                                  // SizedBox(height: 16),
                                  // _buildDocumentUpload(),
                                  SizedBox(height: 16),
                                  _buildActionButtons(),
                                  SizedBox(height: 30),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isSubmitting)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/loading2.json', width: 150, height: 150),
                  SizedBox(height: 16),  // Add space between Lottie and text
                  Text(
                    'Clinic creation in progress...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )

        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Display the uploaded logo or default placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _profileImageBytes != null
                  ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                  : (_profileImageUrl != null
                  ? Image.network(_profileImageUrl!, fit: BoxFit.cover)
                  : Image.asset('assets/profile.png', fit: BoxFit.cover)),
            ),
            SizedBox(width: 20),
            // Button to allow the user to upload a new logo
            InkWell(
              onTap: _pickImage,  // Call the pick image function
              child: Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 2, color: Colors.blueGrey),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 8),
                    Text(_isImageUploaded ? 'Logo Uploaded' : 'Upload Clinic Logo'),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),

        // Show an error message if the image is too large
        if (_isImageTooLarge)
          Text(
            'Please upload an image smaller than 1MB!',
            style: TextStyle(color: Colors.red),
          ),

        // Show Lottie animation while loading/compressing
        if (_isLoading)
          Center(
            child: Column(
              children: [
                Lottie.asset('assets/loading2.json', width: 100, height: 100),
                SizedBox(height: 10),
                Text(
                  'Uploading logo...',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),
      ],
    );
  }


  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clinic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Clinic Name',
            labelStyle: TextStyle(color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter clinic name';
            }
            return null;
          },
          onSaved: (value) => _firstName = value,
        ),
        SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedLocation,
          items: _locations.map((String location) {
            return DropdownMenuItem<String>(
              value: location,
              child: Text(location),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Clinic Location',
            labelStyle: TextStyle(color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          ),
          onChanged: (newValue) {
            setState(() {
              _selectedLocation = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a location';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Clinic Address',
            labelStyle: TextStyle(color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
          onSaved: (value) => _firstName = value,
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        TextFormField(
          controller: _contactEmailController,
          decoration: InputDecoration(
            labelText: 'Clinic E-mail',
            labelStyle: TextStyle(color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter clinic e-mail';
            }
            return null;
          },
          onSaved: (value) => _email = value,
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Clinic Number',
            labelStyle: TextStyle(color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter clinic number';
            }
            return null;
          },
          onSaved: (value) => _phone = value,
        ),
      ],
    );
  }

  Widget _buildScheduleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        // Circular Day Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_weeklySchedule.length, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              child: CircleAvatar(
                backgroundColor: _selectedDayIndex == index ? Colors.blue : Colors.grey,
                child: Text(
                  _weeklySchedule[index].day.substring(0, 3),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 20),

        // "Open for 24 hours" and "Closed" checkboxes
        Row(
          children: [
            Checkbox(
              value: _weeklySchedule[_selectedDayIndex].open24Hours,
              onChanged: (value) {
                setState(() {
                  _weeklySchedule[_selectedDayIndex].open24Hours = value ?? false;
                  if (value == true) {
                    _weeklySchedule[_selectedDayIndex].startTime = null;
                    _weeklySchedule[_selectedDayIndex].endTime = null;
                  }
                });
              },
            ),
            Text('Open for 24 hours'),
            SizedBox(width: 20), // Add some space between the checkboxes
            Checkbox(
              value: _weeklySchedule[_selectedDayIndex].closed,
              onChanged: (value) {
                setState(() {
                  _weeklySchedule[_selectedDayIndex].closed = value ?? false;
                  if (value == true) {
                    _weeklySchedule[_selectedDayIndex].open24Hours = false;
                    _weeklySchedule[_selectedDayIndex].startTime = null;
                    _weeklySchedule[_selectedDayIndex].endTime = null;
                  }
                });
              },
            ),
            Text('Closed'),
          ],
        ),

        // Time pickers for opening and closing times (visible only if "Open for 24 hours" and "Closed" are unchecked)
        if (!_weeklySchedule[_selectedDayIndex].open24Hours && !_weeklySchedule[_selectedDayIndex].closed)
          Column(
            children: [
              _buildTimeField(
                "Opening Time",
                _weeklySchedule[_selectedDayIndex].startTime,
                    (newTime) => setState(() => _weeklySchedule[_selectedDayIndex].startTime = newTime),
              ),
              SizedBox(height: 10), // Add space between time fields
              _buildTimeField(
                "Closing Time",
                _weeklySchedule[_selectedDayIndex].endTime,
                    (newTime) => setState(() => _weeklySchedule[_selectedDayIndex].endTime = newTime),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTimeField(String label, double? selectedTime, ValueChanged<double> onTimeChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label),
        TextButton(
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: selectedTime != null
                  ? doubleToTimeOfDay(selectedTime)
                  : TimeOfDay.now(),
            );
            if (picked != null) onTimeChanged(timeOfDayToDouble(picked));
          },
          child: Text(
            selectedTime != null
                ? doubleToTimeOfDay(selectedTime).format(context)
                : 'Select Time',
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  foregroundColor: WidgetStatePropertyAll(Colors.white)),
              child: Text(_medicalLicense != null
                  ? 'Medical License Uploaded'
                  : 'Upload Medical License'),
              onPressed: () => _pickDocument(isLicense: true),
            ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.pink),
                  foregroundColor: WidgetStatePropertyAll(Colors.white)),
              child: Text(_otherDocument != null
                  ? 'Other Document Uploaded'
                  : 'Upload Other Document'),
              onPressed: () => _pickDocument(isLicense: false),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();  // Navigate back when cancel is pressed
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
            height: 30,
            width: 30,
            child: Lottie.asset('assets/loading2.json'),  // Show Lottie during loading
          )
              : Text('Save Profile'),
          onPressed: _isLoading ? null : () async {
            setState(() {
              _isLoading = true;  // Start loading when the button is pressed
            });

            // Call your form submission logic here
            await _submitForm();

            setState(() {
              _isLoading = false;  // Stop loading after form submission is done
            });
          },
        ),
      ],
    );
  }

  Future<void> _pickDocument({required bool isLicense}) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        if (kIsWeb) {
          if (isLicense) {
            _medicalLicense = file as File?;
          } else {
            _otherDocument = file as File?;
          }
        } else {
          if (isLicense) {
            _medicalLicense = File(file.path);
          } else {
            _otherDocument = File(file.path);
          }
        }
      });
    }
  }

  double timeOfDayToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }

  TimeOfDay doubleToTimeOfDay(double time) {
    int hour = time.floor();
    int minute = ((time - hour) * 60).round();
    return TimeOfDay(hour: hour, minute: minute);
  }


}

class DaySchedule {
  String day;
  double? startTime;  // Changed to double
  double? endTime;    // Changed to double
  bool open24Hours;
  bool closed; // New closed property


  DaySchedule({required this.day, this.startTime, this.endTime, this.open24Hours = false, this.closed= false});
}