# DocIn

DocIn es una aplicación móvil para estudiantes universitarios que centraliza
opiniones y métricas de docentes, ayudando a tomar mejores decisiones antes de
matricularse o elegir cursos.

## Funcionalidades destacadas

- Búsqueda de docentes por nombre y por cursos.
- Filtros por curso y ordenamiento por calificación/recencia.
- Perfil del docente con calificación, reseñas y métodos de enseñanza.
- Roles y permisos (usuario, moderador, administrador).
- Sugerencias de docentes, facultades y escuelas con aprobación.
- Moderación de comentarios con motivo, votación y ocultamiento automático.
- Notificaciones in-app para eventos de moderación y actividad relevante.
- Seguimiento de docente y cursos (local).
- UI adaptada a modo claro/oscuro con buen contraste.

## Estado del proyecto

- Datos locales (mock) con lógica completa en `DataService`.
- Sin backend actualmente; preparado para migración a Firebase.

## Arquitectura y carpetas

- lib/main.dart: entrada y rutas.
- lib/screens: pantallas principales.
- lib/models: modelos de datos.
- lib/services: lógica de negocio y data local.
- lib/data: dataset mock.
- lib/widgets: componentes reutilizables.
- lib/theme: configuración de tema.
- lib/utils: utilitarios (observadores de rutas, etc.).

## Requisitos

- Flutter SDK instalado
- Dispositivo/emulador Android o iOS

## Ejecución

1. Instala dependencias:
	- flutter pub get
2. Ejecuta:
	- flutter run

## Notas importantes

- Notificaciones son locales (in-app), no push.
- Roles y permisos se validan en `DataService` y en UI.
- Los datos no persisten entre reinicios (mock local).

## Roadmap sugerido

- Migración a Firebase (Auth + Firestore + Storage).
- Persistencia local (Hive/SharedPreferences).
- Sincronización en tiempo real de reseñas y moderación.
- Historial de cambios y auditoría de moderación.

## Licencia

Uso interno/educativo. Ajustar según la política del proyecto.
