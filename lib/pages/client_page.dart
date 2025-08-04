import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class ClientPage extends StatefulWidget {
  final String clientName;
  const ClientPage({super.key, required this.clientName});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final ApiService api = ApiService();

  int _selected = 0;
  List<dynamic> _myProjects = [];

  List<Map<String, String>> _constructors = [];
  Map<String, String>? _selectedConstructor;

  final _descriptionController = TextEditingController();

  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  Map<String, dynamic>? _constructorProfile;
  File? _profileImage;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadConstructors();
    _loadClientProfile();
  }

  void _loadProjects() async {
    final data = await api.getProjectsForClient(widget.clientName);
    setState(() {
      _myProjects = data;
    });
  }

  void _loadConstructors() async {
    final data = await ApiService.fetchAllConstructors();
    setState(() {
      _constructors = data.map<Map<String, String>>((e) => {
        'username': e['username'] ?? '',
        'fullName': e['fullName'] ?? '',
      }).toList();
    });
  }

  void _loadConstructorProfile(String username) async {
    final data = await ApiService.fetchUserInfo(username);
    setState(() {
      _constructorProfile = data;
    });
  }

  void _loadClientProfile() async {
    final data = await ApiService.fetchUserInfo(widget.clientName);
    if (data != null) {
      setState(() {
        _fullNameController.text = data['fullName'] ?? '';
        _contactController.text = data['contact'] ?? '';
        _addressController.text = data['address'] ?? '';
        _bioController.text = data['bio'] ?? '';
      });
    }
  }

  void _submitProject() async {
    if (_selectedConstructor == null || _descriptionController.text.isEmpty) return;

    await api.submitProject({
      'clientName': widget.clientName,
      'constructorName': _selectedConstructor!['username'],
      'description': _descriptionController.text,
    });

    _descriptionController.clear();
    setState(() {
      _selectedConstructor = null;
      _constructorProfile = null;
    });
    _loadProjects();
  }

  void _saveProfile() async {
    final success = await api.updateProfile(widget.clientName, {
      'fullName': _fullNameController.text,
      'contact': _contactController.text,
      'address': _addressController.text,
      'bio': _bioController.text,
      // Optional: handle image upload here
    });
    if (success) {
      setState(() => _isEditingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile!')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
      // Optional: upload image to backend
    }
  }

  Widget _buildSubmitTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, String>>(
            value: _selectedConstructor,
            decoration: const InputDecoration(labelText: 'Select Constructor'),
            items: _constructors.isNotEmpty
                ? _constructors.map((constructor) {
                    return DropdownMenuItem(
                      value: constructor,
                      child: Text(constructor['fullName'] ?? ''),
                    );
                  }).toList()
                : [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No constructors found'),
                    ),
                  ],
            onChanged: (value) {
              setState(() => _selectedConstructor = value);
              if (value != null) {
                _loadConstructorProfile(value['username']!);
              } else {
                setState(() {
                  _constructorProfile = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          if (_constructorProfile != null)
            Card(
              elevation: 2,
              child: ListTile(
                title: Text(_constructorProfile!['fullName'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contact: ${_constructorProfile!['contact'] ?? 'N/A'}"),
                    Text("Address: ${_constructorProfile!['address'] ?? 'N/A'}"),
                    Text("Bio: ${_constructorProfile!['bio'] ?? 'N/A'}"),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: "Project Description"),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitProject,
            child: const Text("Submit Offer"),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjectsTab() {
    return ListView.builder(
      itemCount: _myProjects.length,
      itemBuilder: (context, index) {
        final p = _myProjects[index];
        return Card(
          child: ListTile(
            title: Text("To: ${p['constructorName']}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Description: ${p['description']}"),
                Text("Status: ${p['status']}"),
                if (p['budget'] != null) Text("Budget: ${p['budget']}"),
                if (p['status'] == 'rejected' && p['rejectionReason'] != null)
                  Text("Rejected because: ${p['rejectionReason']}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null ? const Icon(Icons.person, size: 50) : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.upload),
            label: const Text("Upload Picture"),
            onPressed: _pickProfileImage,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: Text(_fullNameController.text.isNotEmpty ? _fullNameController.text : "Full Name"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Contact: ${_contactController.text}"),
                  Text("Address: ${_addressController.text}"),
                  Text("Bio: ${_bioController.text}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _isEditingProfile = !_isEditingProfile),
            child: Text(_isEditingProfile ? 'Cancel' : 'Update Profile'),
          ),
          if (_isEditingProfile)
            Column(
              children: [
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildSubmitTab(),
      _buildMyProjectsTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Client Dashboard")),
      body: tabs[_selected],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected,
        onTap: (i) => setState(() => _selected = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "Submit"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "My Projects"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}