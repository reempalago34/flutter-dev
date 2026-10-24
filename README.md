# DevPlay — Frontend Flutter 🎮

## APK para Android

[Descargar DevPlay para Android](downloads/DevPlay.apk)

Este APK de prueba se conecta a `https://apifast.proyecto.sbs/api/v1`. Está
firmado con una clave de depuración; para publicar en Google Play se necesita
una clave de firma de producción.

Frontend móvil de **DevPlay** construido con **Flutter**. Reemplaza al
antiguo frontend de Next.js: la app habla con la **API de FastAPI**, que
es el único backend.

> ✅ **Flutter SDK instalado (3.47.6, stable)** en `C:\src\flutter`. App
> generada con `flutter create` (plataformas: web + android). Se corre con
> `flutter run -d chrome` (web) o se migra a móvil con el Android SDK.

> 🎨 **Diseño = el de la web** (rama `visual` del backend): paleta oscura
> "papel, tinta y filetes", fuentes Fraunces/Bitter/JetBrains Mono, glass
> cards, consola CRT, hero ticker, post cards con like + confeti y dock de
> crear. Por ahora con datos de ejemplo (`lib/models/post.dart`); las
> funciones de la API las integra el compañero en otra rama.

## Arquitectura

```
Flutter (este repo)  →  FastAPI (http://localhost:8000/api/v1)  →  PostgreSQL
```

- **API en desarrollo:** `http://localhost:8000`
- **Swagger (inventario de endpoints):** `http://localhost:8000/docs`
- **Base de datos:** PostgreSQL, base `devplay_api`
- **Especificación de endpoints (referencia):** las 51 rutas originales
  de Prisma viven en `devplay/src/app/api/devplay/` — solo como spec,
  NO se tocan.

## Autenticación

La API usa **JWT**. Flujos que ya soporta el backend:

| Flujo | Endpoint | Notas |
|---|---|---|
| Login por código | `POST /auth/login-code` | sin contraseña: pide código, se verifica |
| Invitado | `POST /auth/guest` | responde plano `{id, username, isGuest, tokens}` |
| Registro | `POST /auth/register` | con honeypot `website` (dejarlo vacío) |

Los tokens van en `Authorization: Bearer <token>`.

## Endpoints principales

- `GET/POST /posts` — feed (types: `TEXT`, `IMAGE`, `VIDEO`, `BETA`, `POLL`; en minúsculas en el schema)
- `POST /posts/{id}/poll` — crea la encuesta de un post POLL
- `POST /polls/{id}/vote` — votar (`option_ids`)
- `GET /posts?type=BETA` — betas
- `GET /chat`, `POST /chat` — chat global
- `GET /dm`, `POST /dm/{user_id}` — mensajes directos
- `GET /notifications` — notificaciones
- `GET /users`, `POST /follow` — perfiles y seguidores
- `GET /store` — tienda
- `GET /realtime-token` — token firmado para el socket (si se usa)

Detalles finos (importantes para no fallar):
- Los enums van en **minúsculas**: `"image"`, `"video"` — `"IMAGE"` da 422.
- Likes y bookmarks son **toggles**: un solo `POST` activa o desactiva.
- La API responde `snake_case`; el frontend Next.js traducía a `camelCase`.

## Plan de trabajo (cuadre)

1. ✅ Backend FastAPI terminado (posts, polls, betas, chat, dm, notificaciones…)
2. ✅ Visual Next.js conservado en la rama `visual` del repo backend (`fastapi_devplay-main`) + respaldo en `_backup_nextjs_frontend`
3. ⬜ Este repo: construir la app Flutter consumiendo `/api/v1`
4. ⬜ Más adelante: **juntar backend y frontend** (deploy conjunto)
5. ⬜ Las funciones de la API que faltan las hace el compañero en otra rama

## Estado del repo

- Rama: `main`
- GitHub: `frankalexander-GM/frontend-web` (privado)
- Detalle: **este repo es 100% Flutter** — la versión Next.js del visual se
  borró de aquí y quedó conservada en la rama `visual` del repo backend
  (`reempalago34/fastapi_devplay-main`) y en el respaldo local
  `_backup_nextjs_frontend`
- Backend y frontend viven separados a propósito; el merge se decide después.
