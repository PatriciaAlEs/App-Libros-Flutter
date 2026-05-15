# Instrucciones para levantar el proyecto (Windows)

Estas instrucciones describen los pasos mínimos para ejecutar la aplicación Flutter incluida en este repositorio en modo web (Chrome) desde Windows.

## Requisitos
- Flutter SDK instalado (stable): https://flutter.dev/docs/get-started/install/windows
- Google Chrome instalado (para web)
- (Opcional) Android SDK / Visual Studio para ejecutar en dispositivos móviles o `windows`.

## Instalar Flutter y añadir al PATH (resumen)
1. Descarga el SDK desde la página oficial y extrae la carpeta, por ejemplo en `C:\src\flutter`.
2. Añade `C:\src\flutter\bin` a la variable de entorno `Path` del usuario.

Ejemplo (PowerShell — añadir al Path del usuario):

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")
```

Después de modificar el `Path` cierra y vuelve a abrir la terminal (PowerShell/CMD). Si usas Git Bash, prueba también en PowerShell o CMD si `flutter` no se detecta.

## Preparar y ejecutar en Chrome
1. Abre una terminal nueva (PowerShell o CMD).
2. Ve al subproyecto (la app Flutter está en la carpeta `reading_tracker`):

```bash
cd C:/Users/piruj/OneDrive/Desktop/Patri/App-libros-flutter/reading_tracker
```

3. Habilita web (si no se ha hecho antes):

```bash
flutter config --enable-web
```

4. Instala dependencias y verifica el entorno:

```bash
flutter pub get
flutter doctor
flutter devices    # verifica que aparezca "Chrome"
```

5. Ejecuta la app en Chrome:

```bash
flutter run -d chrome
```

## Ejecutar en otros targets
- Windows (si está configurado): `flutter run -d windows`
- Android (emulador o dispositivo): `flutter run -d <device_id>`

## Errores comunes y soluciones
- `bash: flutter: command not found` — Flutter no está en el PATH; añade `C:\src\flutter\bin` y abre una nueva terminal.
- `Expected to find project root in current working directory.` — asegúrate de ejecutar los comandos desde `reading_tracker` (contiene `pubspec.yaml`).
- Si Chrome no aparece en `flutter devices`, asegúrate de tener Google Chrome instalado y ejecuta `flutter config --enable-web`.

## Recomendaciones
- Usa PowerShell o CMD en Windows para evitar problemas con PATH en Git Bash.
- Si quieres que te guíe paso a paso mientras lo instalas, pega aquí las salidas de `flutter --version` y `flutter doctor`.

---
Archivo creado para el equipo: instrucciones mínimas para levantar la app en desarrollo.
