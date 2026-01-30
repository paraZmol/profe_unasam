import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/screens/profesor_detail_screen.dart';
import 'package:profe_unasam/theme/app_theme.dart';

class ProfesorCard extends StatelessWidget {
  final Profesor profesor;
  final VoidCallback? onReturn;

  const ProfesorCard({super.key, required this.profesor, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias, // para que el efecto respete bordes
      child: InkWell(
        // para detectar el toque
        onTap: () {
          // navegacion
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfesorDetailScreen(profesor: profesor),
            ),
          ).then((_) => onReturn?.call());
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: profesor.id,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      profesor.fotoUrl.isNotEmpty && profesor.fotoUrl != 'url'
                      ? NetworkImage(profesor.fotoUrl)
                      : null,
                  onBackgroundImageError:
                      profesor.fotoUrl.isNotEmpty && profesor.fotoUrl != 'url'
                      ? (exception, stackTrace) {}
                      : null,
                  child: (profesor.fotoUrl.isEmpty || profesor.fotoUrl == 'url')
                      ? Icon(
                          Icons.person,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profesor.nombre,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    if (profesor.apodo != null && profesor.apodo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '"${profesor.apodo}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      profesor.cursos.isNotEmpty
                          ? profesor.cursos.join(', ')
                          : 'Sin cursos asignados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text('Calificación', style: theme.textTheme.bodySmall),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.accentAmber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        profesor.calificacion.toStringAsFixed(1),
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
