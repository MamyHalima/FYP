import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
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
  String? _profileBase64;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadConstructors();
    _loadClientProfile();
    _loadProfilePicture();
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
      _constructors = data
          .where((e) =>
              e['fullName'] != null &&
              e['fullName'].toString().trim().isNotEmpty)
          .map<Map<String, String>>((e) => {
                'username': e['username'] ?? '',
                'fullName': e['fullName'] ?? '',
              })
          .toList();
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

  void _loadProfilePicture() async {
    final base64 = await ApiService.fetchProfilePicture(widget.clientName);
    setState(() {
      _profileBase64 = base64;
    });
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
      final uploaded = await api.uploadProfilePicture(widget.clientName, _profileImage!);
      if (uploaded) {
        _loadProfilePicture();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture uploaded!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload picture!')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final deleted = await api.deleteAccount(widget.clientName);
      if (deleted) {
        // You may want to redirect to login or home page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted!')),
        );
        // Navigator.of(context).pushReplacement(...);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account!')),
        );
      }
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
                      child: Text(constructor['fullName'] ?? constructor['username'] ?? ''),
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
                leading: FutureBuilder<String?>(
                  future: ApiService.fetchProfilePicture(_constructorProfile!['username']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      return CircleAvatar(
                        backgroundImage: MemoryImage(base64Decode(snapshot.data!)),
                        radius: 24,
                      );
                    }
                    return const CircleAvatar(child: Icon(Icons.person));
                  },
                ),
                title: Text(_constructorProfile!['fullName'] ?? _constructorProfile!['username'] ?? ''),
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
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : (_profileBase64 != null && _profileBase64!.isNotEmpty
                    ? MemoryImage(base64Decode(_profileBase64!))
                    : null) as ImageProvider<Object>?,
            child: (_profileImage == null && (_profileBase64 == null || _profileBase64!.isEmpty))
                ? const Icon(Icons.person, size: 50)
                : null,
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("Delete Account", style: TextStyle(color: Colors.red)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: _deleteAccount,
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