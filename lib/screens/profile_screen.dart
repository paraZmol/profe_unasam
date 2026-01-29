import 'package:flutter/material.dart';
import 'package:profe_unasam/models/user_role.dart';
import 'package:profe_unasam/services/data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _emailController = TextEditingController();
  final _dataService = DataService();

  @override
  void initState() {
    super.initState();
    final user = _dataService.getCurrentUser();
    if (user != null) {
      _aliasController.text = user.alias;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final currentEmail = _dataService.getCurrentUser()?.email ?? '';
    final newEmail = _emailController.text.trim().toLowerCase();

    // Verificar si el email ya existe (si fue cambiado)
    if (newEmail != currentEmail.toLowerCase()) {
      final allUsers = _dataService.getAllUsers();
      final emailExists = allUsers.values.any(
        (user) =>
            user.email.toLowerCase() == newEmail &&
            user.email.toLowerCase() != currentEmail.toLowerCase(),
      );

      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este correo ya está registrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    _dataService.updateProfile(
      alias: _aliasController.text.trim(),
      email: _emailController.text.trim(),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));

    Navigator.pop(context);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _dataService.logout();
              // Ir al LoginScreen y limpiar la pila de navegación
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _changeOwnRole(UserRole newRole) {
    if (!_dataService.canChangeOwnRole(newRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para cambiar a este rol'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // El usuario actual cambia su propio rol
      final currentUserId = _dataService.getCurrentUser()?.id ?? '';
      _dataService.setUserRole(currentUserId, newRole);

      // Actualizar el rol local del usuario
      _dataService.setRoleInternal(newRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado a ${newRole.label}')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showChangeRoleDialog() {
    final currentRole = _dataService.getRole();
    final baseRole = _dataService.getBaseRole();
    final theme = Theme.of(context);

    // Verificar si el usuario puede cambiar de rol
    if (!_dataService.canUserChangeRole()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para cambiar de rol'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Determinar qué roles puede cambiar basado en su rol BASE
    List<UserRole> availableRoles = [];
    if (baseRole == UserRole.moderator) {
      availableRoles = [UserRole.user, UserRole.moderator];
    } else if (baseRole == UserRole.admin) {
      availableRoles = [UserRole.user, UserRole.moderator, UserRole.admin];
    } else {
      // Usuario normal no puede cambiar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para cambiar de rol'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rol actual: ${currentRole.label}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rol base: ${baseRole?.label ?? "Desconocido"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('Seleccionar nuevo rol:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            ...availableRoles.map(
              (role) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _changeOwnRole(role);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: role == UserRole.admin
                          ? Colors.red
                          : role == UserRole.moderator
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    child: Text(
                      role.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoleInfo() async {
    final theme = Theme.of(context);
    final currentRole = _dataService.getRole();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu Rol', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentRole == UserRole.admin
                        ? Colors.red.withOpacity(0.1)
                        : currentRole == UserRole.moderator
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currentRole == UserRole.admin
                          ? Colors.red
                          : currentRole == UserRole.moderator
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentRole == UserRole.admin
                            ? Icons.admin_panel_settings
                            : currentRole == UserRole.moderator
                            ? Icons.gavel
                            : Icons.person,
                        color: currentRole == UserRole.admin
                            ? Colors.red
                            : currentRole == UserRole.moderator
                            ? Colors.orange
                            : Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentRole.label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentRole == UserRole.admin
                                  ? 'Control total del sistema'
                                  : currentRole == UserRole.moderator
                                  ? 'Valida sugerencias y gestiona contenido'
                                  : 'Usuario con acceso básico',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Permisos', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  context,
                  Icons.add_circle,
                  'Sugerir Profesores',
                  true,
                ),
                const SizedBox(height: 8),
                _buildPermissionItem(
                  context,
                  Icons.check_circle,
                  'Validar Sugerencias',
                  currentRole == UserRole.admin ||
                      currentRole == UserRole.moderator,
                ),
                const SizedBox(height: 8),
                _buildPermissionItem(
                  context,
                  Icons.school,
                  'Gestionar Facultades',
                  currentRole == UserRole.admin ||
                      currentRole == UserRole.moderator,
                ),
                const SizedBox(height: 8),
                _buildPermissionItem(
                  context,
                  Icons.people,
                  'Gestionar Usuarios',
                  currentRole == UserRole.admin,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionItem(
    BuildContext context,
    IconData icon,
    String label,
    bool hasPermission,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          color: hasPermission
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasPermission
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            decoration: hasPermission
                ? TextDecoration.none
                : TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _dataService.getCurrentUser();
    final role = _dataService.getRole();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No hay usuario activo'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.alias[0].toUpperCase(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_dataService.isSensitiveActionsLocked) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Acciones sensibles bloqueadas',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _dataService
                                                .sensitiveActionsLockMessage,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              'INFORMACIÓN DE LA CUENTA',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _showRoleInfo,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: role == UserRole.admin
                                      ? Colors.red.withOpacity(0.1)
                                      : role == UserRole.moderator
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: role == UserRole.admin
                                        ? Colors.red
                                        : role == UserRole.moderator
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      role == UserRole.admin
                                          ? Icons.admin_panel_settings
                                          : role == UserRole.moderator
                                          ? Icons.gavel
                                          : Icons.person,
                                      color: role == UserRole.admin
                                          ? Colors.red
                                          : role == UserRole.moderator
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rol',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            role.label,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'change') {
                                          _showChangeRoleDialog();
                                        } else if (value == 'info') {
                                          _showRoleInfo();
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem<String>(
                                          value: 'info',
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline),
                                              SizedBox(width: 8),
                                              Text('Ver permisos'),
                                            ],
                                          ),
                                        ),
                                        if (_dataService.canUserChangeRole())
                                          const PopupMenuItem<String>(
                                            value: 'change',
                                            child: Row(
                                              children: [
                                                Icon(Icons.swap_horiz),
                                                SizedBox(width: 8),
                                                Text('Cambiar rol'),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'EDITAR PERFIL',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aliasController,
                      decoration: const InputDecoration(
                        labelText: 'Alias',
                        prefixIcon: Icon(Icons.person_outline),
                        helperText: 'Tu identidad anónima',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El alias es requerido';
                        }
                        if (value.trim().length < 3) {
                          return 'Mínimo 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El correo es requerido';
                        }
                        if (!value.contains('@')) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        child: const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
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
