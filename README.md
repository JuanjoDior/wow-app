# 🎮 WoW Companion

**WoW Companion** es una aplicación companion multiplataforma para World of Warcraft que permite a los jugadores consultar perfiles de personajes, progresión Mythic+, raids, equipamiento y comparar personajes. Desarrollada con Flutter y alimentada por la API de Raider.IO.

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.7+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.7+-0175C2?logo=dart)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20Android%20|%20Web%20|%20Windows%20|%20macOS%20|%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

## ✨ Características

### 🔍 Búsqueda de Personajes
- Búsqueda por región (US, EU, KR, TW, CN), reino y nombre
- Historial de búsquedas recientes con opción de eliminar
- Soporte para todas las regiones de WoW

### 👤 Perfil de Personaje
- Información básica: nivel, raza, clase, especialización
- Guild actual
- Avatar de alta calidad (render completo del personaje)
- Puntos de logros
- Item level promedio y equipado

### 🎒 Equipamiento Detallado
- Vista completa de todos los slots equipados (head, neck, shoulders, etc.)
- Item level por pieza
- Calidad de items con códigos de color (Legendary, Epic, Rare)
- Enchantments y gemas aplicadas
- Bonus IDs
- Enlaces directos a Wowhead para información detallada de cada item
- Íconos de items de alta calidad

### ⛰️ Progresión Mythic+
- Puntuación M+ total de la temporada actual
- Puntuaciones separadas por rol (DPS, Healer, Tank)
- Lista de mejores runs por mazmorra
- Detalles por run:
  - Nivel de llave completada
  - Tiempo de completado vs tiempo par
  - Número de upgrades de piedra angular
  - Afijos aplicados
  - Puntuación obtenida
  - Enlace a Raider.IO para ver detalles completos

### 🏰 Progresión de Raids
- Seguimiento de todas las raids de la expansión actual
- Clears por dificultad (Normal, Heroico, Mítico)
- Conteo de bosses derrotados por raid
- Nombre formateado de raids (Nerub-ar Palace, Liberation of Undermine, etc.)

### ⭐ Favoritos
- Guardado local de personajes favoritos
- Acceso rápido desde página dedicada
- Persistencia entre sesiones
- Funcional en todas las plataformas (móvil, web, escritorio)

### 🔄 Comparación de Personajes
- Comparar 2 personajes lado a lado
- Visualización comparativa de:
  - Equipamiento
  - Stats
  - Progresión M+
  - Progresión de raids
- URL compartible: `/compare/:region1/:realm1/:name1/vs/:region2/:realm2/:name2`

### 📚 Guías de Clases y Especializaciones
- Rotaciones básicas por especialización
- Prioridades de estadísticas (Haste, Crit, Mastery, Versatility)
- Consumibles recomendados (flasks, foods, potions)
- Tips y mejores prácticas
- Datos almacenados localmente en JSON

### 🌍 Internacionalización
- Soporte completo para **Español** e **Inglés**
- Traducción de toda la UI
- Selección de idioma persistente
- Toggle de idioma accesible desde navegación

### 📱 Diseño Responsive
- Navegación adaptativa:
  - **Móvil**: Bottom navigation bar
  - **Tablet/Desktop**: Side navigation rail
- Optimizado para diferentes tamaños de pantalla
- Soporte para orientación portrait y landscape

### 🌐 Progressive Web App (PWA)
- Instalable como aplicación nativa en el navegador
- Tema personalizado de WoW (#1A1A2E background, #FFD100 accent)
- Íconos maskables para mejor integración en dispositivos
- Funcionalidad offline limitada

---

## 🛠️ Stack Tecnológico

### Framework y Lenguaje
- **Flutter** `^3.10.7` - Framework UI multiplataforma
- **Dart** `^3.10.7` - Lenguaje de programación

### Arquitectura y Patrones
- **Clean Architecture** - Separación en capas (data, domain, presentation)
- **BLoC Pattern** con `flutter_bloc ^8.1.6` - State management
- **Dependency Injection** con `get_it ^8.0.2`

### Networking y APIs
- **Dio** `^5.7.0` - Cliente HTTP con interceptores
- **Raider.IO API** - Fuente de datos de WoW
  - Endpoint: `https://raider.io/api/v1/characters/profile`
  - Fields: gear, mythic_plus_scores, raid_progression

### Routing y Navegación
- **GoRouter** `^14.6.2` - Routing declarativo con deep linking

### UI y Diseño
- **Material Design 3** - Sistema de diseño moderno
- **Google Fonts** `^6.2.1` - Tipografía personalizada
- **cached_network_image** `^3.4.1` - Caching de imágenes
- **Tema oscuro personalizado** - Estilo inspirado en WoW

### Almacenamiento y Cache
- **SharedPreferences** `^2.3.4` - Persistencia local (favoritos, idioma)
- **Memory Cache** - Cache en memoria para personajes consultados

### Utilidades
- **equatable** `^2.0.5` - Comparación de valores
- **dartz** `^0.10.1` - Programación funcional (Either, Option)
- **logger** `^2.5.0` - Logging
- **url_launcher** `^6.3.2` - Apertura de URLs externas
- **intl** `^0.20.2` - Internacionalización

### Testing
- **flutter_test** - Testing framework de Flutter
- **bloc_test** `^9.1.7` - Testing de BLoCs
- **mocktail** `^1.0.4` - Mocking

---

## 📁 Estructura del Proyecto

```
wow_companion/
├── lib/
│   ├── main.dart                          # Punto de entrada de la app
│   ├── core/                              # Infraestructura compartida
│   │   ├── cache/
│   │   │   └── memory_cache.dart         # Cache en memoria
│   │   ├── di/
│   │   │   └── injection.dart            # Configuración GetIt (DI)
│   │   ├── error/
│   │   │   ├── exceptions.dart           # Excepciones custom
│   │   │   └── failures.dart             # Failures (domain layer)
│   │   ├── l10n/
│   │   │   └── locale_cubit.dart         # State management de idioma
│   │   ├── network/
│   │   │   └── api_client.dart           # Cliente Dio configurado
│   │   ├── router/
│   │   │   └── app_router.dart           # Configuración GoRouter
│   │   ├── theme/
│   │   │   └── wow_theme.dart            # Tema oscuro WoW
│   │   └── utils/
│   │       └── url_strategy.dart         # Estrategia de URL para web
│   ├── features/                          # Módulos por funcionalidad
│   │   ├── character/                    # Feature: Perfil de personaje
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── raiderio_datasource.dart    # API Raider.IO
│   │   │   │   └── repositories/
│   │   │   │       └── character_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── character.dart              # Entity principal
│   │   │   │   └── repositories/
│   │   │   │       └── character_repository.dart   # Abstract repo
│   │   │   └── presentation/
│   │   │       ├── cubit/
│   │   │       │   └── character_cubit.dart        # BLoC state
│   │   │       ├── pages/
│   │   │       │   └── character_detail_page.dart  # UI del perfil
│   │   │       └── widgets/                        # Widgets específicos
│   │   ├── compare/                      # Feature: Comparación
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── compare_select_page.dart    # Selección de personajes
│   │   │       │   └── compare_result_page.dart    # Vista comparativa
│   │   ├── favorites/                    # Feature: Favoritos
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── cubit/
│   │   │       │   └── favorites_cubit.dart
│   │   │       └── favorites_page.dart
│   │   ├── guides/                       # Feature: Guías
│   │   │   ├── data/
│   │   │   │   └── datasources/
│   │   │   │       └── cheatsheet_local_datasource.dart
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── cheatsheet.dart
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           ├── guides_list_page.dart       # Lista de clases
│   │   │           └── guide_detail_page.dart      # Detalle de spec
│   │   ├── items/                        # Feature: Items
│   │   │   └── presentation/
│   │   │       └── widgets/
│   │   │           └── item_detail_dialog.dart     # Dialog de item
│   │   └── search/                       # Feature: Búsqueda
│   │       └── presentation/
│   │           ├── cubit/
│   │           │   └── search_history_cubit.dart
│   │           └── home_page.dart                  # Página principal
│   ├── shared/                           # Componentes compartidos
│   │   └── widgets/
│   │       ├── shell_layout.dart         # Layout con navegación
│   │       ├── error_view.dart           # Vista de errores
│   │       └── loading_indicator.dart    # Indicador de carga
│   └── l10n/                             # Archivos de traducción
│       ├── app_en.arb                    # Inglés
│       └── app_es.arb                    # Español
├── assets/
│   └── cheatsheets/
│       └── cheatsheets.json              # Datos de guías (rotaciones, stats)
├── web/
│   ├── index.html                        # HTML de la web app (SEO optimizado)
│   ├── manifest.json                     # PWA manifest
│   └── icons/                            # Íconos de la app
├── android/                              # Configuración Android
├── ios/                                  # Configuración iOS
├── windows/                              # Configuración Windows
├── macos/                                # Configuración macOS
├── linux/                                # Configuración Linux
├── pubspec.yaml                          # Dependencias y assets
├── l10n.yaml                             # Config de localización
└── analysis_options.yaml                 # Reglas de linting
```

---

## 🚀 Instalación y Desarrollo

### Requisitos Previos
- Flutter SDK `^3.10.7` ([Instalar Flutter](https://docs.flutter.dev/get-started/install))
- Dart SDK `^3.10.7` (incluido con Flutter)
- Editor: VS Code, Android Studio o IntelliJ IDEA
- Emulador/dispositivo (para móvil) o navegador web

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd wow_companion
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Generar archivos de localización**
   ```bash
   flutter gen-l10n
   ```

### Ejecutar la Aplicación

#### Web
```bash
flutter run -d chrome
```

#### iOS (requiere macOS)
```bash
flutter run -d ios
```

#### Android
```bash
flutter run -d android
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### Linux
```bash
flutter run -d linux
```

### Build de Producción

#### Web (PWA)
```bash
flutter build web --release
```
Archivos generados en `build/web/`

#### Android (APK)
```bash
flutter build apk --release
```

#### iOS (requiere cuenta de desarrollador)
```bash
flutter build ios --release
```

#### Windows
```bash
flutter build windows --release
```

---

## 🎨 Tema y Diseño

La aplicación utiliza un tema oscuro inspirado en la estética de World of Warcraft:

- **Background**: `#1A1A2E` (Dark blue-gray)
- **Primary**: `#FFD100` (WoW gold)
- **Surface**: `#16213E` (Darker blue)
- **Error**: `#FF6B6B` (Soft red)

Los colores de calidad de items siguen el estándar de WoW:
- **Legendary**: `#FF8000` (Orange)
- **Epic**: `#A335EE` (Purple)
- **Rare**: `#0070DD` (Blue)
- **Uncommon**: `#1EFF00` (Green)

---

## 🏗️ Arquitectura

El proyecto sigue **Clean Architecture** con separación clara de responsabilidades:

### Capas

1. **Presentation Layer**
   - Widgets (UI)
   - Cubits/BLoCs (state management)
   - Pages

2. **Domain Layer**
   - Entities (modelos de negocio puros)
   - Repositories (interfaces abstractas)
   - Use Cases (lógica de negocio)

3. **Data Layer**
   - Data Sources (API, local storage)
   - Repository Implementations
   - Models (mapeo de JSON a entidades)

### Flujo de Datos

```
User Input → Widget → Cubit → Use Case → Repository → Data Source → API
                ↑                                                      ↓
                └──────────── State Update ←─── Mapper ← Response ←───┘
```

### Manejo de Errores

- **Exceptions** en data layer (NetworkException, NotFoundException, etc.)
- **Failures** en domain layer (NetworkFailure, ServerFailure, etc.)
- Uso de `Either<Failure, Success>` de Dartz para manejo funcional de errores

---

## 📱 Plataformas Soportadas

| Plataforma | Estado | Notas |
|------------|--------|-------|
| **Web** | ✅ Completo | PWA instalable, SEO optimizado |
| **Android** | ✅ Completo | Min SDK 21 (Lollipop) |
| **iOS** | ✅ Completo | Min iOS 12 |
| **Windows** | ✅ Completo | Win32 API |
| **macOS** | ✅ Completo | macOS 10.14+ |
| **Linux** | ✅ Completo | GTK3 |

**Notas importantes:**
- Todas las features (favoritos, búsqueda, comparación) son funcionales en las 6 plataformas
- El almacenamiento local persiste correctamente en móvil y escritorio

---

## 🗺️ Roadmap

### ✅ Completado (v1.0.0)
- [x] Búsqueda de personajes con soporte multiregión
- [x] Visualización de perfil completo
- [x] Equipamiento detallado con enlaces a Wowhead
- [x] Progresión M+ y Raids
- [x] Sistema de favoritos multiplataforma
- [x] Comparación de personajes
- [x] Guías de clases y specs
- [x] Internacionalización (ES/EN)
- [x] PWA funcional
- [x] Tema oscuro WoW
- [x] Soporte para 6 plataformas

### 🚧 En Progreso
- [ ] Testing automatizado (unit, widget, integration)
- [ ] Optimización de rendimiento

### 📋 Próximas Features (v1.1.0+)

#### 🎯 Alta Prioridad
- [ ] **Armería Personalizada (Build Creator)**
  - Crear builds personalizados slot por slot
  - Cálculo automático de stats totales
  - Cálculo de iLvl promedio
  - Guardar/cargar builds
  - Comparar build actual vs build objetivo
  - *Beneficio*: Planificar BiS (Best in Slot) sin tener el equipo

#### 🎨 Media Prioridad
- [ ] Gráficos de progresión histórica (charts)
- [ ] Modo offline mejorado (cache completo)
- [ ] Animaciones de transición
- [ ] Skeleton loaders
- [ ] Notificaciones push (nuevo boss derrotado, M+ score aumentado)
- [ ] Exportar comparaciones como imagen

#### 🔧 Baja Prioridad
- [ ] Integración con Warcraft Logs
- [ ] Análisis de talento builds
- [ ] Compatibilidad con Classic/TBC/WotLK
- [ ] Google Analytics
- [ ] Modo claro (light theme)

---

## 📊 APIs Utilizadas

### Raider.IO API
- **Base URL**: `https://raider.io/api/v1`
- **Endpoint principal**: `/characters/profile`
- **Documentación**: [Raider.IO API Docs](https://raider.io/api)

**Parámetros utilizados:**
```
region: us, eu, kr, tw, cn
realm: <nombre-del-reino>
name: <nombre-del-personaje>
fields: gear, mythic_plus_scores_by_season:current, mythic_plus_best_runs, raid_progression
```

**Rate Limits**: Respetar límites de la API (429 Too Many Requests)

### Wowhead (Enlaces)
- Ítems: `https://www.wowhead.com/item=<itemId>?bonus=<bonusIds>`
- Usado solo para enlaces, no para datos

### Zamimg (Íconos)
- Íconos de items: `https://wow.zamimg.com/images/wow/icons/large/<iconName>.jpg`

---

## 🐛 Issues Conocidos

- ⚠️ **Sin issues críticos** - La app está estable en v1.0.0

### Resueltos Recientemente
- ✅ Favoritos funcionan correctamente en móvil (resuelto en `ebd3711`)
- ✅ Iconos de banderas de región arreglados (resuelto en `ebd3711`)
- ✅ Traducciones completas ES/EN (resuelto en `f276e47`)

---

## 📝 Changelog Reciente

### v1.0.0 (2026-02-12)
- ✅ PWA completo con manifest y SEO optimizado
- ✅ Limpieza de código (comentarios DEBUG eliminados)
- ✅ HTML de web app estructurado correctamente
- ✅ Tema personalizado de WoW (#1A1A2E, #FFD100)

### Commits Anteriores
- `ebd3711` - Solución icono banderas y bug favoritos
- `e8c498b` - Versión estable después de intento de cambio de tema
- `f276e47` - Traducción completa estable
- `9f4fa38` - Traducción + solución Android
- `5c30205` - Phase 2: M+ detail, raid bars, tooltips, compare, cheatsheets
- `b838592` - Objetos con información al hacer click (Wowhead links)
- `e561965` - Limpieza código, historial búsqueda, cache in-memory

---

## 🤝 Contribución

### Para Desarrolladores
Este proyecto sigue Clean Architecture y patrones de Flutter modernos. Al contribuir:

1. **Mantén la separación de capas** (data/domain/presentation)
2. **Usa BLoC/Cubit** para state management
3. **Escribe tests** para nuevas features
4. **Sigue las reglas de linting** (`analysis_options.yaml`)
5. **Documenta código complejo** con comentarios
6. **Traduce textos** en ambos idiomas (ES/EN)

### Estilo de Código
- Nombres en inglés (clases, variables, funciones)
- Comentarios en español o inglés según contexto
- Usar trailing commas para mejor formato
- Preferir composition sobre inheritance

---

## 📄 Licencia

Este proyecto es de código abierto. Consulta el archivo LICENSE para más detalles.

---

## 🙏 Agradecimientos

- **Raider.IO** por proporcionar una API gratuita y completa
- **Blizzard Entertainment** por World of Warcraft
- **Flutter Team** por el increíble framework
- **Comunidad de WoW** por feedback y sugerencias

---

## 📞 Contacto y Soporte

Para preguntas, sugerencias o reportar bugs:
- Crea un issue en GitHub
- Revisa la documentación de Flutter: [docs.flutter.dev](https://docs.flutter.dev)
- Consulta la API de Raider.IO: [raider.io/api](https://raider.io/api)

---

<div align="center">

**Hecho con ❤️ para la comunidad de World of Warcraft**

*"For the Horde! ...and the Alliance too, I guess."* 🎮

</div>
