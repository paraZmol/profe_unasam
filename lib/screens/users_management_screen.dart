import 'package:flutter/material.dart';

import 'package:profe_unasam/models/app_user.dart';
import 'package:profe_unasam/models/user_role.dart';
import 'package:profe_unasam/services/data_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen>
    with TickerProviderStateMixin {
  final _dataService = DataService();
  final _searchController = TextEditingController();
  late TabController _tabController;
  List<MapEntry<String, AppUser>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Verificar si el usuario es admin
    if (_dataService.isSensitiveActionsLocked ||
        _dataService.getRole() != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _dataService.isSensitiveActionsLocked
                  ? _dataService.sensitiveActionsLockMessage
                  : 'Solo administradores pueden gestionar usuarios',
            ),
          ),
        );
        Navigator.pop(context);
      });
      return;
    }
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    await _dataService.refreshUsersFromFirestore();
    _filterUsers();
  }

  void _filterUsers() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      final users = _dataService.getAllUsers();
      _filteredUsers = users.entries
          .where(
            (entry) =>
                entry.value.alias.toLowerCase().contains(query) ||
                entry.value.email.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<void> _changeUserRole(String userId, UserRole newRole) async {
    if (!_guardSensitiveAction()) {
      return;
    }
    try {
      await _dataService.setUserRole(userId, newRole);
      setState(() {
        _loadUsers();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado a ${newRole.label}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _promoteToModerator(String userId) async {
    if (!_guardSensitiveAction()) {
      return;
    }
    try {
      await _dataService.promoteToModerator(userId);
      setState(() {
        _loadUsers();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario promovido a Moderador')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _demoteModerator(String userId) async {
    if (!_guardSensitiveAction()) {
      return;
    }
    try {
      await _dataService.demoteModerator(userId);
      setState(() {
        _loadUsers();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moderador degradado a Usuario')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showAddModeratorDialog() {
    final theme = Theme.of(context);
    final localSearchController = TextEditingController();
    List<MapEntry<String, AppUser>> searchResults = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar Moderador'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: localSearchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar usuario...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          final q = query.toLowerCase();
                          final users = _dataService.getAllUsers();
                          searchResults = users.entries
                              .where(
                                (entry) =>
                                    _dataService.getRole(entry.key) ==
                                        UserRole.user &&
                                    (entry.value.alias.toLowerCase().contains(
                                          q,
                                        ) ||
                                        entry.value.email
                                            .toLowerCase()
                                            .contains(q)),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (searchResults.isEmpty)
                      Text(
                        'No se encontraron usuarios',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final entry = searchResults[index];
                            final user = entry.value;
                            return ListTile(
                              title: Text(user.alias),
                              subtitle: Text(user.email),
                              trailing: IconButton(
                                icon: const Icon(Icons.check_circle),
                                color: Colors.green,
                                onPressed: () {
                                  _promoteToModerator(entry.key);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Todos los Usuarios'),
            Tab(text: 'Moderadores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Todos los usuarios
          _buildAllUsersTab(theme),
          // Tab 2: Moderadores
          _buildModeratorsTab(theme),
        ],
      ),
    );
  }

  bool _guardSensitiveAction() {
    if (_dataService.isSensitiveActionsLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dataService.sensitiveActionsLockMessage)),
      );
      return false;
    }

    if (_dataService.getRole() != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo administradores pueden gestionar usuarios'),
        ),
      );
      return false;
    }

    return true;
  }

  Widget _buildAllUsersTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por alias o email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No hay usuarios',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredUsers[index];
                    final user = entry.value;
                    final currentRole = _dataService.getRole(entry.key);

                    // Determinar qué roles se pueden asignar
                    List<UserRole> availableRoles = [];
                    if (currentRole == UserRole.user) {
                      availableRoles = [UserRole.user, UserRole.moderator];
                    } else if (currentRole == UserRole.moderator) {
                      availableRoles = [
                        UserRole.user,
                        UserRole.moderator,
                        UserRole.admin,
                      ];
                    } else if (currentRole == UserRole.admin) {
                      availableRoles = [
                        UserRole.user,
                        UserRole.moderator,
                        UserRole.admin,
                      ];
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(currentRole),
                          child: Text(
                            user.alias[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user.alias),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text(
                              'Rol: ${currentRole.label}',
                              style: TextStyle(
                                color: _getRoleColor(currentRole),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: DropdownButton<UserRole>(
                          value: currentRole,
                          items: availableRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role.label,
                                    style: TextStyle(
                                      color: _getRoleColor(role),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (newRole) {
                            if (newRole != null && newRole != currentRole) {
                              _changeUserRole(entry.key, newRole);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildModeratorsTab(ThemeData theme) {
    final moderators = _dataService.getModerators();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddModeratorDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Moderador'),
          ),
        ),
        Expanded(
          child: moderators.isEmpty
              ? Center(
                  child: Text(
                    'No hay moderadores',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: moderators.length,
                  itemBuilder: (context, index) {
                    final entry = moderators[index];
                    final user = entry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            user.alias[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user.alias),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón para promover a admin
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              tooltip: 'Promover a Administrador',
                              color: Colors.green,
                              onPressed: () async {
                                try {
                                  await _dataService.promoteToAdmin(entry.key);
                                  setState(() {
                                    _loadUsers();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Moderador promovido a Administrador',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                    ),
                                  );
                                }
                              },
                            ),
                            // Botón para degradar a usuario
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Degradar a Usuario',
                              color: Colors.red,
                              onPressed: () {
                                _demoteModerator(entry.key);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }
}
