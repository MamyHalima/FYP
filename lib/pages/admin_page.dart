import 'package:flutter/material.dart';
import '../api_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  List<dynamic> _users = [];
  bool _loading = true;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  String _role = 'CLIENT';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUsers() async {
    setState(() => _loading = true);
    final users = await ApiService.fetchAllUsers();
    final filtered = users.where((u) => u['role'] != 'ADMIN').toList();
    filtered.sort((a, b) => a['username'].toString().toLowerCase().compareTo(b['username'].toString().toLowerCase()));
    setState(() {
      _users = filtered;
      _loading = false;
    });
  }

  void _deleteUser(String username) async {
    final deleted = await ApiService.adminDeleteUser(username);
    if (deleted) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user!')),
      );
    }
  }

  void _showAddUserDialog() {
    _usernameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _role = 'CLIENT';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                  DropdownMenuItem(value: 'CONSTRUCTOR', child: Text('Constructor')),
                ],
                onChanged: (val) {
                  setState(() {
                    _role = val!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'username': _usernameController.text,
                'password': _passwordController.text,
                'email': _emailController.text,
                'role': _role,
              };
              final added = await ApiService.adminAddUser(data);
              Navigator.pop(ctx);
              if (added) {
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User added!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add user!')),
                );
              }
            },
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          title: Text(user['username']),
          subtitle: Text(user['role']),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete User"),
                  content: Text("Are you sure you want to delete ${user['username']}?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                _deleteUser(user['username']);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = _users.where((u) => u['role'] == 'CLIENT').toList();
    final constructors = _users.where((u) => u['role'] == 'CONSTRUCTOR').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Clients'),
            Tab(text: 'Constructors'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(clients),
                _buildUserList(constructors),
              ],
            ),
    );
  }
}