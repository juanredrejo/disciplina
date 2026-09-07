# Disciplina

App de hábitos y disciplina para Android (móvil + tablet) con sincronización en la nube.

Inspirada en **HelloHabit**: marcas cada día, ves tus rachas 📈 y tienes estadísticas con gráficos.

## Qué hace
- **Hoy**: lista de hábitos con un check grande para marcar el día, racha actual 🔥 y barra de progreso.
- **Calendario**: rejilla mensual por hábito (tipo HelloHabit). Toca cualquier día para marcarlo/desmarcarlo.
- **Estadísticas**: anillo de cumplimiento (30 días), gráfico de barras de la última semana, y por hábito: racha actual, récord, total y %.
- **Sincronización**: usas la misma cuenta en el móvil y la tablet → lo que marcas en uno aparece al instante en el otro (Firebase).
- **Hábitos recurrentes**: diarios o en días sueltos (L, M, X…).

## Stack
- Flutter (una sola base de código para móvil y tablet)
- Firebase: Authentication (email/contraseña) + Cloud Firestore
- fl_chart para los gráficos

---

## ⚠️ Antes de nada: la configuración de Firebase

La app necesita que crees un proyecto en Firebase y pegues sus datos. **Una sola vez.**

### Paso 1 — Crear el proyecto
1. Entra en **https://console.firebase.google.com** (con tu cuenta de Google).
2. Pulsa **"Crear proyecto"**. Ponle un nombre (p. ej. `disciplina`). Acepta las condiciones. Puedes desactivar Google Analytics (no hace falta).
3. Espera a que se cree y entra en el **panel del proyecto**.

### Paso 2 — Activar Authentication (email/contraseña)
1. En el menú de la izquierda: **Build → Authentication** (o "Construir → Identification").
2. Pulsa **"Comenzar"**.
3. En la pestaña **"Sign-in method"**, activa **Email/Password** → **Guardar**.

### Paso 3 — Activar Firestore
1. Menú izquierdo: **Build → Firestore Database**.
2. Pulsa **"Crear base de datos"**.
3. Elige **Modo producción** (o "test mode" si quieres probar rápido). Ubicación: `europe-west1` (más cerca de España).
4. **Importante — reglas de seguridad.** En la pestaña **Reglas** pon esto y pulsa **Publicar**:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == uid;
    }
  }
}
```
(Eso garantiza que cada persona solo puede ver/escribir sus propios datos.)

### Paso 4 — Conseguir la configuración de la app
1. Menú izquierdo: **Proyecto** (icono ⚙️ "Configuración del proyecto").
2. Baja hasta la sección **"Tus aplicaciones"**.
3. Pulsa el icono **`</>`** (Web).
4. Ponle un nombre (p. ej. `disciplina`). No hace falta registrar "hosting". Pulsa **Registrar app**.
5. Te mostrará un bloque de código `firebaseConfig = { ... }` con estas claves:
   - `apiKey`
   - `authDomain`
   - `projectId`
   - `storageBucket`
   - `messagingSenderId`
   - `appId`

### Paso 5 — Pegar los valores
Copia esos 6 valores en el archivo **`lib/firebase_options.dart`** (sustituye los `TU_...` / `PASTE_...`).

> Si no quieres tocar el código: pásame esos 6 valores por aquí y yo los pego.

---

## Cómo compilar el APK (gratis, sin Android Studio)

La app se compila en **GitHub Actions** (servidores con el SDK de Android). Tú solo subes el código.

### Opción A — Te lo compilo yo (recomendado)
Necesito que crees un **repositorio de GitHub** y me des acceso:
1. Crea una cuenta en **https://github.com** (gratis) si no la tienes.
2. Crea un repositorio nuevo (p. ej. `disciplina`), **privado** si quieres.
3. Me das un **token** de GitHub (o me añades como colaborador) y yo subo el código y lanzo el build.
4. Cuando termine (≈5 min), descargas el `app-release.apk` desde la pestaña **Actions**.

### Opción B — Lo subes tú (3 min)
```bash
# en la carpeta del proyecto
git init
git add .
git commit -m "App Disciplina"
# crea el repo en github.com y luego:
git remote add origin https://github.com/TU_USUARIO/disciplina.git
git branch -M main
git push -u origin main
```
Al hacer push, GitHub Actions compila solo. Ve a **Actions → Build APK** y descarga el artefacto.

---

## Instalar en el móvil y la tablet
1. Pasa el `app-release.apk` a los dos dispositivos (o descarga el APK en cada uno desde el navegador, si lo pides en un enlace).
2. Ábrelo. Android te pedirá permitir "Instalar apps desconocidas" → dale a **Permitir**.
3. **Primera vez**: crea tu cuenta (email + contraseña).
4. En el **segundo** dispositivo, instala el mismo APK e **inicia sesión con la misma cuenta**.
5. ✅ Listo: ya se sincronizan. Marca algo en el móvil y al coger la tablet estará marcado.

> Nota: el APK está firmado con una clave de prueba (debug). Para una app personal es perfecto. Si algún día quieres subirlo a Google Play, se cambia la firma (te lo preparo cuando llegue el momento).

---

## Estructura
```
lib/
  main.dart                 # arranque + Firebase + gate de login
  firebase_options.dart     # ⚠️ pega aquí tu config de Firebase
  models/habit.dart         # modelo Habit + rachas/estadísticas + fechas
  services/auth_service.dart    # login/registro
  services/habit_service.dart   # Firestore (CRUD + toggle atómico)
  screens/login_screen.dart
  screens/home_screen.dart      # pestañas
  screens/today_tab.dart        # "Hoy"
  screens/calendar_tab.dart     # rejilla mensual
  screens/stats_tab.dart        # gráficos
  widgets/habit_card.dart
  widgets/add_habit_sheet.dart  # crear/editar hábito
  theme/app_theme.dart
android/                    # capa Android (gradle, manifest, iconos)
.github/workflows/build-apk.yml  # compila el APK en GitHub Actions
```
