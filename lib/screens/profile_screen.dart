import 'package:flutter/material.dart';
import 'package:profe_unasam/models/user_plan.dart';
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _dataService.getCurrentUser();
    final role = _dataService.getRole();
    final plan = _dataService.getPlan();

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
                            Text(
                              'INFORMACIÓN DE LA CUENTA',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.badge),
                              title: const Text('Rol'),
                              subtitle: Text(role.label),
                            ),
                            ListTile(
                              leading: const Icon(Icons.workspace_premium),
                              title: const Text('Plan'),
                              subtitle: Text(plan.label),
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
