import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class ConstructorPage extends StatefulWidget {
  final String constructorName;
  const ConstructorPage({super.key, required this.constructorName});

  @override
  State<ConstructorPage> createState() => _ConstructorPageState();
}

class _ConstructorPageState extends State<ConstructorPage> {
  int _selected = 0;
  List<dynamic> _projects = [];
  final ApiService api = ApiService();

  final TextEditingController _rejectionReason = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final Map<int, TextEditingController> _incomeControllers = {};
  final Map<int, TextEditingController> _expensesControllers = {};

  File? _profileImage;
  String? _profileBase64;
  bool _isEditingProfile = false;
  int? _showBudgetForm;
  int? _showRejectForm;

  List<Map<String, String>> _budgetItems = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadUserProfile();
    _loadProfilePicture();
  }

  void _loadProjects() async {
    final data = await api.getProjectsForConstructor(widget.constructorName);
    setState(() {
      _projects = data;
    });
  }

  void _loadUserProfile() async {
    final data = await ApiService.fetchUserInfo(widget.constructorName);
    if (data != null) {
      _fullNameController.text = data['fullName'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _addressController.text = data['address'] ?? '';
      _bioController.text = data['bio'] ?? '';
    }
  }

  void _loadProfilePicture() async {
    final base64 = await ApiService.fetchProfilePicture(widget.constructorName);
    setState(() {
      _profileBase64 = base64;
    });
  }

  void _addBudgetRow() {
    setState(() {
      _budgetItems.add({'category': '', 'amount': ''});
    });
  }

  void _removeBudgetRow(int index) {
    setState(() {
      _budgetItems.removeAt(index);
    });
  }

  void _approve(int id) async {
    final budget = _budgetItems
        .where((item) => item['category']!.isNotEmpty && item['amount']!.isNotEmpty)
        .toList();

    final budgetAsString = budget.map((item) => "${item['category']}: ${item['amount']}").join(", ");
    await api.approveProject(id, budgetAsString);

    _loadProjects();
    setState(() {
      _showBudgetForm = null;
      _budgetItems.clear();
    });
  }

  void _reject(int id) async {
    await api.rejectProject(id, _rejectionReason.text);
    _loadProjects();
    setState(() {
      _showRejectForm = null;
      _showBudgetForm = null;
      _rejectionReason.clear();
    });
  }

  void _saveProfile() async {
    final success = await api.updateProfile(widget.constructorName, {
      'fullName': _fullNameController.text,
      'contact': _contactController.text,
      'address': _addressController.text,
      'bio': _bioController.text,
    });
    if (success) {
      setState(() => _isEditingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Saved")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile!")),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
      final uploaded = await api.uploadProfilePicture(widget.constructorName, _profileImage!);
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
      final deleted = await api.deleteAccount(widget.constructorName);
      if (deleted) {
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

  Widget _buildProjectsTab() {
    return ListView.builder(
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final p = _projects[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("From: ${p['clientName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Description: ${p['description']}"),
                Text("Status: ${p['status']}"),
                if (p['status'] == 'pending') ...[
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showBudgetForm = index;
                            _showRejectForm = null;
                            _budgetItems = [
                              {'category': '', 'amount': ''}
                            ];
                          });
                        },
                        child: const Text("Approve"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showRejectForm = index;
                            _showBudgetForm = null;
                          });
                        },
                        child: const Text("Reject"),
                      ),
                    ],
                  ),
                  if (_showBudgetForm == index)
                    Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _budgetItems.length,
                          itemBuilder: (context, i) {
                            return Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: "Expenditure Category"),
                                    onChanged: (val) => _budgetItems[i]['category'] = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: "Amount"),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => _budgetItems[i]['amount'] = val,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeBudgetRow(i),
                                ),
                              ],
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Add Row"),
                          onPressed: _addBudgetRow,
                        ),
                        ElevatedButton(
                          onPressed: () => _approve(p['id']),
                          child: const Text("Submit Budget"),
                        ),
                      ],
                    ),
                  if (_showRejectForm == index)
                    Column(
                      children: [
                        TextField(
                          controller: _rejectionReason,
                          decoration: const InputDecoration(labelText: "Reason"),
                        ),
                        ElevatedButton(
                          onPressed: () => _reject(p['id']),
                          child: const Text("Submit Reason"),
                        ),
                      ],
                    ),
                ],
                if (p['status'] == 'approved' && p['budget'] != null)
                  Text("Budget: ${p['budget']}"),
                if (p['status'] == 'rejected' && p['rejectionReason'] != null)
                  Text("Rejected because: ${p['rejectionReason']}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialTab() {
    return ListView.builder(
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final p = _projects[index];
        final int projectId = p['id'] ?? index;

        _incomeControllers.putIfAbsent(projectId, () => TextEditingController());
        _expensesControllers.putIfAbsent(projectId, () => TextEditingController());

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Project: ${p['description']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _incomeControllers[projectId],
                  decoration: const InputDecoration(labelText: "Income"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _expensesControllers[projectId],
                  decoration: const InputDecoration(labelText: "Expenditure"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final income = double.tryParse(_incomeControllers[projectId]?.text ?? '') ?? 0;
                    final expenses = double.tryParse(_expensesControllers[projectId]?.text ?? '') ?? 0;
                    final profit = income - expenses;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Income Statement"),
                        content: Text(profit >= 0 ? "Profit: $profit" : "Loss: ${-profit}"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          )
                        ],
                      ),
                    );
                  },
                  child: const Text("Calculate Profit/Loss"),
                ),
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
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                TextField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: "Contact"),
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: "Bio"),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text("Save Profile"),
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
      _buildProjectsTab(),
      _buildFinancialTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Constructor Dashboard')),
      body: tabs[_selected],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected,
        onTap: (i) => setState(() => _selected = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Projects"),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: "Finance"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}