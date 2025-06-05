# LittleCow 
## Entorno de desarrollo
| Componente| Version | 
|----------|----------|
| Flutter    |  3.29.3  | 
| Dart    | 3.7.2   | 
| Android Studio    | 2024.3 | 
| Android SDK  | 35.0.1 | 
---
## Instalación Detallada
Todos los pasos técnicos están en:  
[**INSTALL.md**](INSTALL.md)

## Ejecución del Proyecto
Sigue estos pasos para configurar y ejecutar el proyecto localmente:
```bash
# 1. Clonar repositorio
git clone https://github.com/jokoframework/littlecow.git
cd littlecow

# 2. Configurar variables de entorno
cp .env.example .env
# Edita el archivo .env con tus configuraciones

# 3. Limpiar el proyecto 
flutter clean

# 4. Instalar dependencias
flutter pub get

# 5. Ejecutar (usar tu dispositivo conectado o emulador)
flutter run
```

### Configuración para Dispositivos Móviles
**IMPORTANTE:** Cuando pruebes la aplicación con un teléfono conectado o emulador, debes modificar el archivo `.env` para cambiar "localhost" por la IP del servidor en `BASE_URL`.

Ejemplo:
```bash
# Original
BASE_URL="http://localhost:8080/api"

# Modificado para dispositivo móvil
BASE_URL="http://192.168.X.X:8080/api"
```


### Ejecutar en Linux Desktop
Para ejecutar específicamente en tu escritorio Linux, sigue estos pasos:

```bash
# 1. Verificar las dependencias necesarias para desarrollo en Linux
sudo apt-get update
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```
```bash
# 2. Habilitar soporte para Linux (si aún no está habilitado)
flutter config --enable-linux-desktop
```
```bash
# 3. Ejecutar específicamente para Linux desktop
flutter run -d linux
```

> **Nota:** Este repositorio ya incluye todos los archivos necesarios para ejecutar en Linux Desktop. No es necesario ejecutar `flutter create .` después de clonar el repositorio.

## Capturas de Pantalla

### Pantalla de Login
<img src="images/login.jpg" width="300" >

### Listado de Posts
<img src="images/posts.jpg" width="300">

