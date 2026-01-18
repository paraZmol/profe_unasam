import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/screens/add_review_screen.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/theme/app_theme.dart';

class ProfesorDetailScreen extends StatefulWidget {
  final Profesor profesor;

  const ProfesorDetailScreen({super.key, required this.profesor});

  @override
  State<ProfesorDetailScreen> createState() => _ProfesorDetailScreenState();
}

class _ProfesorDetailScreenState extends State<ProfesorDetailScreen> {
  late Profesor _profesor;
  final _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _profesor = widget.profesor;
  }

  double _computedRating() {
    final reviews = _profesor.reviews;
    if (reviews.isEmpty) return _profesor.calificacion;
    final total = reviews.fold<double>(0.0, (s, r) => s + r.puntuacion);
    return total / reviews.length;
  }

  Dificultad? _getDificultadPromedio() {
    if (_profesor.reviews.isEmpty) return null;
    final dificultades = _profesor.reviews.map((r) => r.dificultad).toList();
    final promedioValor =
        dificultades.fold<int>(0, (sum, d) => sum + d.index).toDouble() /
        dificultades.length;
    return Dificultad.values[promedioValor.round()];
  }

  OportunidadAprobacion? _getOportunidadPromedio() {
    if (_profesor.reviews.isEmpty) return null;
    final oportunidades = _profesor.reviews
        .map((r) => r.oportunidadAprobacion)
        .toList();
    final promedioValor =
        oportunidades.fold<int>(0, (sum, o) => sum + o.index).toDouble() /
        oportunidades.length;
    return OportunidadAprobacion.values[promedioValor.round()];
  }

  String _getDificultadLabel(Dificultad d) {
    switch (d) {
      case Dificultad.muyFacil:
        return 'Muy Fácil';
      case Dificultad.facil:
        return 'Fácil';
      case Dificultad.normal:
        return 'Normal';
      case Dificultad.dificil:
        return 'Difícil';
      case Dificultad.muyDificil:
        return 'Muy Difícil';
    }
  }

  String _getOportunidadLabel(OportunidadAprobacion o) {
    switch (o) {
      case OportunidadAprobacion.casioSeguroe:
        return 'Casi seguro (95%+)';
      case OportunidadAprobacion.probable:
        return 'Probable (70-95%)';
      case OportunidadAprobacion.cincuentaCincuenta:
        return '50/50';
      case OportunidadAprobacion.dificil:
        return 'Difícil (<50%)';
    }
  }

  Color _getOportunidadColor(OportunidadAprobacion o) {
    switch (o) {
      case OportunidadAprobacion.casioSeguroe:
        return Colors.green;
      case OportunidadAprobacion.probable:
        return Colors.blue;
      case OportunidadAprobacion.cincuentaCincuenta:
        return Colors.orange;
      case OportunidadAprobacion.dificil:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profesor = _profesor;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(profesor.nombre)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // foto grande
            Center(
              child: Hero(
                tag: profesor.id,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      profesor.fotoUrl.isNotEmpty && profesor.fotoUrl != 'url'
                      ? NetworkImage(profesor.fotoUrl)
                      : null,
                  onBackgroundImageError: (_, __) {},
                  child: (profesor.fotoUrl.isEmpty || profesor.fotoUrl == 'url')
                      ? Icon(
                          Icons.person,
                          size: 80,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // informacion principal
            Text(profesor.nombre, style: theme.textTheme.displayMedium),
            if (profesor.apodo != null && profesor.apodo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '"${profesor.apodo}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Text(
              profesor.curso,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Divider(
              height: 40,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor,
            ),

            // seccion de la calificacion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: AppTheme.accentAmber, size: 40),
                const SizedBox(width: 10),
                Text(
                  _computedRating().toStringAsFixed(1),
                  style: theme.textTheme.displayLarge,
                ),
              ],
            ),
            Text('Calificación General', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),

            // ============ RESUMEN DE EVALUACIONES ============
            if (_profesor.reviews.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN DE EVALUACIONES',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dificultad promedio
                    if (_getDificultadPromedio() != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dificultad Promedio',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getDificultadLabel(
                                      _getDificultadPromedio()!,
                                    ),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.trending_up,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Oportunidad de aprobar
                    if (_getOportunidadPromedio() != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Oportunidad de Aprobar',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getOportunidadLabel(
                                      _getOportunidadPromedio()!,
                                    ),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: _getOportunidadColor(
                                            _getOportunidadPromedio()!,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.check_circle,
                                color: _getOportunidadColor(
                                  _getOportunidadPromedio()!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Métodos más comunes
                    if (_profesor.reviews
                        .where((r) => r.metodosEnsenanza.isNotEmpty)
                        .isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Métodos de Enseñanza',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _profesor.reviews
                                    .expand((r) => r.metodosEnsenanza)
                                    .toSet()
                                    .map((metodo) {
                                      return Chip(
                                        label: Text(metodo),
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
                                            .withAlpha((0.2 * 255).toInt()),
                                      );
                                    })
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // btn calificar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddReviewScreen(profesor: profesor),
                      ),
                    );
                    if (result != null && result is Review) {
                      _dataService.agregarResena(profesor.id, result);

                      setState(() {
                        _profesor = _dataService.getProfesores().firstWhere(
                          (p) => p.id == profesor.id,
                        );
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('gracias por tu calificacion'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'CALIFICAR AL PROFESOR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reviews list
            if (_profesor.reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Aún no hay comentarios para este profesor.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profesor.reviews.length,
                itemBuilder: (context, index) {
                  final review = profesor.reviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < review.puntuacion
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppTheme.accentAmber,
                                size: 16,
                              );
                            }),
                          ),
                          Text(
                            '${review.fecha.day}/${review.fecha.month}/${review.fecha.year}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dificultad
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dificultad: ${_getDificultadLabel(review.dificultad)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Oportunidad
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: _getOportunidadColor(
                                      review.oportunidadAprobacion,
                                    ),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Aprobar: ${_getOportunidadLabel(review.oportunidadAprobacion)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _getOportunidadColor(
                                        review.oportunidadAprobacion,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Métodos
                              if (review.metodosEnsenanza.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: review.metodosEnsenanza
                                      .map(
                                        (m) => Chip(
                                          label: Text(
                                            m,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor: theme
                                              .colorScheme
                                              .primary
                                              .withAlpha((0.1 * 255).toInt()),
                                        ),
                                      )
                                      .toList(),
                                ),

                              if (review.metodosEnsenanza.isNotEmpty)
                                const SizedBox(height: 12),

                              // Comentario
                              Text(
                                review.comentario,
                                style: theme.textTheme.bodyMedium,
                              ),

                              if (review.consejo.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(
                                      (0.1 * 255).toInt(),
                                    ),
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '💡 Consejo:',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        review.consejo,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
