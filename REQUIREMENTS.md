# Requisitos de la Aplicación

## Requisitos del Sistema

### Software Obligatorio

- **Flutter**: 3.44.0 (master channel) o superior
  - Ubicación: `c:\src\flutter`
  - Incluye: Dart SDK
  - Instalación: Se encuentra en el PATH del sistema
  
- **Git**: 2.45.2 o superior
  - Necesario para clonar el repositorio y versionado

- **Windows 10/11** (64-bit)
  - Windows 11 Pro 25H2 comprobado como compatible

### Software Opcional (por target)

- **Android Studio**: Para desarrollo en Android
  - Incluye Android SDK
  - Documentación: https://flutter.dev/to/windows-android-setup

- **Visual Studio**: Para desarrollo en Windows apps
  - Requiere workload: "Desktop development with C++"
  - Descarga: https://visualstudio.microsoft.com/downloads/

- **Xcode**: Para desarrollo en iOS/macOS (solo disponible en macOS)

## Verificación de Instalación

### Verificar Flutter
```powershell
flutter --version
flutter doctor
```

### Verificar dependencias del proyecto
```powershell
cd reading_tracker
flutter pub get
```

## Stack Tecnológico

### Framework & Lenguaje
- **Flutter 3.44.0**: Framework multi-plataforma
- **Dart**: Lenguaje de programación

### Dependencias Principales (pubspec.yaml)
- **flutter_riverpod 2.6.1**: Gestión de estado e inyección de dependencias
- **drift 2.32.1**: ORM y persistencia con SQLite (declarado)
- **uuid 4.5.3**: Generación de identificadores únicos
- **intl 0.19.0**: Internacionalización y formato de fechas
- **sqlite3_flutter_libs 0.5.42**: SQLite para Flutter

### Dependencias de Desarrollo
- **build_runner**: Generador de código para Drift
- **drift_dev**: Herramientas de desarrollo para Drift

## Ruta de Instalación

Flutter se instaló en:
```
c:\src\flutter
```

Variables de entorno:
- `PATH`: `c:\src\flutter\bin` añadido permanentemente al PATH del usuario

## Troubleshooting

### Flutter no se encuentra después de instalar
- Reinicia el terminal o VS Code
- Verifica que `c:\src\flutter\bin` está en PATH: `echo %PATH%`

### Error de symlinks en Windows
- Habilita Developer Mode: `start ms-settings:developers`
- O usa WSL2 para desarrollo en Linux

### Doctor muestra issues
- Ejecuta `flutter doctor -v` para más detalles
- Instala los componentes necesarios según tus targets

## Referencias

- [Documentación oficial de Flutter](https://docs.flutter.dev/)
- [Instalación de Flutter en Windows](https://docs.flutter.dev/get-started/install/windows)
- [Flutter Doctor Documentation](https://docs.flutter.dev/reference/flutter-cli)
