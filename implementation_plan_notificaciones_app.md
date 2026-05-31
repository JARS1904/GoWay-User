# Push Notifications Fuera de la App (FCM + PHP)

## Resumen del problema

Actualmente la app **solo recibe notificaciones mientras está abierta**, porque consulta el API de PHP con un timer periódico (`Timer.periodic`). Cuando la app se cierra o está en background, ese timer no corre y no hay forma de que el servidor "empuje" información al dispositivo.

La solución estándar para esto es **Firebase Cloud Messaging (FCM)**: el servidor de Google actúa como intermediario que entrega notificaciones al dispositivo incluso cuando la app está cerrada.

---

## Arquitectura propuesta

```
Admin PHP  ──► PHP API  ──► FCM API (Google)  ──► Dispositivo Android/iOS
                │                                       │
                ▼                                       ▼
            MySQL (guarda                         App Flutter recibe
            FCM tokens y                          notificación aunque
            notificaciones)                       esté cerrada
```

**Flujo completo:**
1. La app Flutter se inicia → solicita permiso de notificaciones → obtiene su **FCM token** único
2. Ese token se envía al servidor PHP y se guarda en MySQL (tabla `fcm_tokens`)
3. Cuando el admin crea una notificación → PHP la guarda en la BD **y** llama a la API de FCM para enviar el push al dispositivo
4. El dispositivo recibe la notificación aunque la app esté cerrada

---

## Requisitos previos

> [!IMPORTANT]
> Necesitas crear un proyecto en **Firebase** (gratuito). Visita https://console.firebase.google.com, crea un proyecto "GoWay" y descarga el archivo `google-services.json` para Android. Sin esto, el resto no funcionará.

> [!NOTE]
> FCM usa la **HTTP v1 API** que requiere autenticación OAuth2. La forma más práctica desde PHP es usar un **Service Account JSON** que descargas desde Firebase Console → Configuración del proyecto → Cuentas de servicio.

---

## Cambios propuestos

### 1. Base de datos MySQL — Nueva tabla

#### [NEW] `fcm_tokens` table (SQL)
```sql
CREATE TABLE fcm_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL,
  fcm_token VARCHAR(512) NOT NULL UNIQUE,
  plataforma VARCHAR(20) DEFAULT 'android',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_id_usuario (id_usuario)
);
```

---

### 2. PHP Backend

#### [MODIFY] `notificaciones_api.php`
- Agregar action `register_token` para guardar/actualizar el FCM token del dispositivo
- Agregar función `sendFcmNotification($tokens, $title, $message, $data)` que llama a la FCM HTTP v1 API
- Modificar la lógica de creación de notificaciones para que también llame a FCM

#### [NEW] `fcm_helper.php`
- Helper con la lógica de autenticación OAuth2 con el Service Account
- Función para obtener el Access Token de Google
- Función para enviar el push a uno o múltiples tokens

---

### 3. Flutter App

#### [MODIFY] `pubspec.yaml`
Agregar dependencias:
```yaml
firebase_core: ^3.x
firebase_messaging: ^15.x
flutter_local_notifications: ^18.x
```

#### [MODIFY] `android/app/build.gradle`
- Agregar `id "com.google.gms.google-services"` en plugins

#### [MODIFY] `android/build.gradle`
- Agregar `classpath 'com.google.gms:google-services:4.x'`

#### [NEW] `android/app/google-services.json`
- Archivo descargado desde Firebase Console (lo proporciona el usuario)

#### [MODIFY] `lib/main.dart`
- Inicializar Firebase con `Firebase.initializeApp()`
- Registrar el handler de mensajes en background con `FirebaseMessaging.onBackgroundMessage`
- Inicializar `flutter_local_notifications` para mostrar notificaciones cuando la app está en foreground

#### [NEW] `lib/services/push_notification_service.dart`
- Clase `PushNotificationService` que encapsula toda la lógica FCM:
  - `initialize()` — pide permisos, obtiene token, lo envía al backend
  - `refreshTokenOnChange()` — actualiza el token si FCM lo renueva
  - `handleForegroundMessages()` — muestra notificación local cuando la app está abierta
  - `handleBackgroundTap()` — navega a la pantalla correcta al tocar una notificación

#### [MODIFY] `lib/services/api_service.dart`
- Agregar endpoint `fcmTokenUrl` para registrar tokens

---

## Preguntas abiertas

> [!IMPORTANT]
> **¿Tienes acceso a Firebase Console?**
> El paso crítico es crear el proyecto Firebase y descargar:
> - `google-services.json` (para Android) → va en `android/app/`
> - `GoogleService-Info.plist` (para iOS, si aplica) → va en `ios/Runner/`
> - El archivo **Service Account JSON** (para el backend PHP) → va en el servidor, nunca en la app

> [!NOTE]
> **¿Tu servidor PHP tiene acceso a internet?**
> El PHP necesita hacer peticiones HTTP a `https://fcm.googleapis.com/`. Si está en red local (192.168.x.x) sin acceso a internet desde el servidor, no podrá comunicarse con FCM.

> [!NOTE]
> **¿La app es solo para Android o también iOS?**
> iOS requiere pasos adicionales (APNs certificates en Firebase). El plan cubre Android completamente; iOS requiere una cuenta de Apple Developer.

---

## Plan de verificación

1. Instalar dependencias con `flutter pub get`
2. Compilar y correr la app → verificar que el token FCM se registra en la BD
3. Desde una herramienta como Postman, llamar al endpoint del admin para crear una notificación
4. Con la app **cerrada**, verificar que llega la notificación al dispositivo
5. Tocar la notificación → verificar que abre la app en la pantalla correcta
