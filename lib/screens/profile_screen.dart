import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:profe_unasam/models/user_role.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/services/storage_service.dart';

enum HelpSection { support, creator }

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
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  HelpSection _helpSection = HelpSection.support;
  bool _isUploadingQr = false;

  @override
  void initState() {
    super.initState();
    final user = _dataService.getCurrentUser();
    if (user != null) {
      _aliasController.text = user.alias;
      _emailController.text = user.email;
    }
    _loadHelpSettings();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadHelpSettings() async {
    await _dataService.refreshAppSettingsFromFirestore();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    await _dataService.refreshUsersFromFirestore();

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

    await _dataService.updateProfile(
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
            onPressed: () async {
              await _dataService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              // Ir al LoginScreen y limpiar la pila de navegación
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeOwnRole(UserRole newRole) async {
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
      final currentUserId = _dataService.getCurrentUser()?.id ?? '';
      final baseRole = _dataService.getBaseRole();

      if (newRole == UserRole.user &&
          (baseRole == UserRole.admin || baseRole == UserRole.moderator)) {
        final alias = await _promptPublicAlias(currentUserId);
        if (alias == null) {
          return;
        }
        _dataService.setPublicAlias(currentUserId, alias);
      }

      // El usuario actual cambia su propio rol
      await _dataService.setUserRole(currentUserId, newRole);

      // Actualizar el rol local del usuario
      _dataService.setRoleInternal(newRole);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado a ${newRole.label}')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _promptPublicAlias(String userId) async {
    final controller = TextEditingController(
      text: _dataService.getPublicAlias(userId) ?? '',
    );
    final theme = Theme.of(context);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alias público para comentarios'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para comentar como Usuario, define un alias público (no revela tu rol).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Alias público',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final alias = controller.text.trim();
                if (alias.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El alias debe tener al menos 3 caracteres',
                      ),
                    ),
                  );
                  return;
                }
                if (!_dataService.isAliasAvailable(
                  alias,
                  excludeUserId: userId,
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El alias público ya está en uso'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, alias);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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

  Future<void> _editHelpSettings() async {
    final theme = Theme.of(context);
    final supportController = TextEditingController(
      text: _dataService.getSupportPhone(),
    );
    final yapeController = TextEditingController(
      text: _dataService.getYapeNumber(),
    );
    final qrController = TextEditingController(
      text: _dataService.getYapeQrUrl(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar ayuda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Soporte', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: supportController,
                decoration: const InputDecoration(
                  labelText: 'Número de soporte',
                  prefixIcon: Icon(Icons.phone_in_talk_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Text('Ayuda al creador', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: yapeController,
                decoration: const InputDecoration(
                  labelText: 'Número de Yape',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qrController,
                decoration: const InputDecoration(
                  labelText: 'URL del QR',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _dataService.updateAppSettings(
        supportPhone: supportController.text,
        yapeNumber: yapeController.text,
        yapeQrUrl: qrController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ayuda actualizada')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _uploadYapeQr() async {
    if (_isUploadingQr) return;
    final user = _dataService.getCurrentUser();
    if (user == null) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingQr = true;
    });

    try {
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadYapeQrImage(
        userId: user.id,
        bytes: bytes,
        fileName: picked.name,
      );

      await _dataService.updateAppSettings(
        supportPhone: _dataService.getSupportPhone(),
        yapeNumber: _dataService.getYapeNumber(),
        yapeQrUrl: url,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR actualizado')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingQr = false;
      });
    }
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
                    const SizedBox(height: 24),
                    Text(
                      'AYUDA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Centro de ayuda',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (role == UserRole.admin)
                                  IconButton(
                                    tooltip: 'Editar ayuda',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: _editHelpSettings,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<HelpSection>(
                              segments: const <ButtonSegment<HelpSection>>[
                                ButtonSegment<HelpSection>(
                                  value: HelpSection.support,
                                  label: Text('Soporte'),
                                ),
                                ButtonSegment<HelpSection>(
                                  value: HelpSection.creator,
                                  label: Text('Ayuda al creador'),
                                ),
                              ],
                              selected: <HelpSection>{_helpSection},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _helpSection = value.first;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_helpSection == HelpSection.support) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.phone_in_talk_outlined,
                                ),
                                title: const Text('Llamar a soporte'),
                                subtitle: Text(
                                  _dataService.getSupportPhone().isEmpty
                                      ? 'No configurado'
                                      : _dataService.getSupportPhone(),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Copiar número',
                                  icon: const Icon(Icons.copy),
                                  onPressed:
                                      _dataService.getSupportPhone().isEmpty
                                      ? null
                                      : () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text: _dataService
                                                  .getSupportPhone(),
                                            ),
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Número copiado'),
                                            ),
                                          );
                                        },
                                ),
                              ),
                            ] else ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                                title: const Text('Yape'),
                                subtitle: Text(
                                  _dataService.getYapeNumber().isEmpty
                                      ? 'No configurado'
                                      : _dataService.getYapeNumber(),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Copiar número',
                                  icon: const Icon(Icons.copy),
                                  onPressed:
                                      _dataService.getYapeNumber().isEmpty
                                      ? null
                                      : () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text: _dataService
                                                  .getYapeNumber(),
                                            ),
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Número copiado'),
                                            ),
                                          );
                                        },
                                ),
                              ),
                              if (role == UserRole.admin) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploadingQr
                                        ? null
                                        : _uploadYapeQr,
                                    icon: _isUploadingQr
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.upload_file),
                                    label: Text(
                                      _isUploadingQr
                                          ? 'Subiendo QR...'
                                          : 'Subir QR de Yape',
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (_dataService.getYapeQrUrl().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _dataService.getYapeQrUrl(),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 200,
                                      alignment: Alignment.center,
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      child: const Text('QR no disponible'),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('QR no configurado'),
                                ),
                            ],
                          ],
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
