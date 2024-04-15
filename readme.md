# TuFlota

## Descripción
TuFlota es una aplicación móvil diseñada para gestionar y monitorear la condición y el desgaste de vehículos, específicamente camiones. Esta aplicación es una herramienta esencial para operadores y administradores, proporcionando funcionalidades claves para la supervisión eficiente del estado de cada camión en tiempo real.

## Funciones Principales

- **Gestión de Camiones:** Permite registrar y visualizar información detallada de cada camión, incluyendo marca, modelo, placa, año, kilometraje, color, estado y nivel de desgaste.

- **Monitoreo de Desgaste:** La aplicación actualiza automáticamente el nivel de desgaste de los camiones cada hora, ayudando a identificar aquellos que requieren atención inmediata.

- **Chat Global:** Integración de un chat global donde los usuarios pueden comunicarse, compartir información y recibir notificaciones importantes del sistema.

- **Notificaciones en Tiempo Real:** Envía alertas a los operadores cuando un camión alcanza un nivel crítico de desgaste, requiriendo atención.

- **Búsqueda Avanzada:** Funcionalidad de búsqueda que permite a los usuarios encontrar rápidamente camiones específicos por marca, modelo o placa.

- **Generación de reportes:** Los camiones cuyo nivel de desgaste llegue al mínimo (1) permiten generar reportes con los detalles del mismo en la pantalla Camiones. Esta bitácora será llenada por quien aborde la jornada de mantenimiento. 

## Ventajas

- **Centralización de Información:** Toda la información relacionada con los camiones se encuentra en un solo lugar, accesible fácilmente por operadores y administradores.

- **Mejora en el Mantenimiento:** La detección temprana del desgaste permite realizar mantenimientos preventivos, prolongando la vida útil de los camiones.

- **Comunicación Efectiva:** El chat global mejora la comunicación entre los usuarios, facilitando la gestión y resolución de incidencias.

- **Accesibilidad:** Diseñada para ser intuitiva y fácil de usar, permitiendo a los usuarios acceder a la información y funcionalidades clave rápidamente.

## Integraciones

- **Firebase:** Utiliza Firebase para la autenticación de usuarios, almacenamiento de datos, y envío de notificaciones push, asegurando una experiencia de usuario fluida y segura.

- **Firebase Cloud Messaging (FCM):** Implementa FCM para el envío de notificaciones en tiempo real, informando a los operadores sobre el estado crítico de los camiones.

- **Flutter:** Desarrollada con Flutter, proporcionando una experiencia de usuario consistente tanto en dispositivos Android como iOS.

## Instrucciones de Uso

1. **Inicio de Sesión:** Los usuarios deben autenticarse utilizando sus credenciales para acceder a las funcionalidades de la aplicación.

2. **Visualización de Camiones:** En la sección de camiones, los usuarios pueden ver todos los camiones registrados y su información detallada.

3. **Monitoreo de Desgaste:** La aplicación muestra el nivel de desgaste actualizado de cada camión, permitiendo a los usuarios identificar aquellos que necesitan mantenimiento.

4. **Uso del Chat:** Los usuarios pueden comunicarse y compartir información relevante a través del chat global.

5. **Gestión de Alertas:** Cuando un camión requiere atención, los operadores recibirán una notificación push, permitiéndoles actuar rápidamente.

## Requisitos

- Dispositivo Android o iOS con acceso a internet.
- Crear proyecto de Google Cloud
  - Activar Firebase
  - Activar FCM (Firebase Cloud Messaging)