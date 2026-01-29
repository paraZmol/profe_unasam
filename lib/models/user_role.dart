enum UserRole { admin, moderator, user }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.moderator:
        return 'Moderador';
      case UserRole.user:
        return 'Usuario';
    }
  }
}
