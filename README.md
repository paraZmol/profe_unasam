# DocIn

DocIn es una app móvil para estudiantes universitarios que desean conocer
experiencias reales sobre docentes antes de matricularse o llevar un curso.

## Funcionalidades principales

- Listado y búsqueda de docentes por nombre o curso.
- Filtros por curso y ordenamiento por calificación/recencia.
- Detalle del docente con calificación y reseñas.
- Planes locales: Básico, Prueba y Premium.
- Bloqueo de información avanzada en plan Básico.
- Seguimiento de docente/curso (solo con acceso completo).
- Notificaciones in-app cuando hay nuevas reseñas seguidas.

## Estado actual

- La data es local (mock) y no requiere backend.
- Listo para migrar a Firebase o API propia en el futuro.

## Estructura del proyecto

- lib/main.dart: entrada principal.
- lib/screens: pantallas principales.
- lib/models: modelos de datos.
- lib/services: capa local de datos.
- lib/data: data mock.
- lib/widgets: componentes reutilizables.

## Cómo ejecutar

1. Instala Flutter y configura el SDK.
2. Ejecuta en la raíz del proyecto:

```bash
flutter pub get
flutter run
```

## Notas

- Las notificaciones son locales (in-app), no push.
- Los planes son simulados y no requieren pago real.

## Próximos pasos sugeridos

- Persistencia local (SharedPreferences/Hive).
- Autenticación de usuarios.
- Backend/Firebase para reseñas y notificaciones push.
- Moderación y reportes de reseñas.
