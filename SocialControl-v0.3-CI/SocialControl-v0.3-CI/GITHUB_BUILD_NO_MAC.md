# Compilar sin Mac y sin pagar Apple

Objetivo: usar un Mac de GitHub Actions únicamente para comprobar que el proyecto compila.

Esto NO instala todavía la app en tu iPhone y NO requiere Apple Developer.

## Paso 1 — Crear cuenta/repositorio
1. Entra en GitHub.
2. Crea un repositorio nuevo, por ejemplo `social-control-ios`.
3. Déjalo privado si no quieres publicar el código.

## Paso 2 — Subir el proyecto
Descomprime este ZIP.

En la web de GitHub:
1. `Add file`
2. `Upload files`
3. Arrastra TODO el contenido de la carpeta `SocialControl-v0.3-CI`.
4. Commit changes.

Importante: `.github/workflows/` debe quedar dentro del repositorio.

## Paso 3 — Ejecutar compilación
1. Abre la pestaña `Actions`.
2. Selecciona `iOS CI`.
3. Pulsa `Run workflow`.
4. Espera al resultado.

Verde = compila y pasan tests.
Rojo = abre el job y copia el error completo a ChatGPT.

También se ejecuta `Structure Check`, que detecta errores simples y reglas de ad-block potencialmente peligrosas.

## Qué conseguimos con esto
- Xcode real.
- macOS real.
- Compilación de Swift/SwiftUI.
- Compilación de las extensiones.
- Tests automáticos.
- Sin alquilar un Mac.
- Sin pagar Apple Developer.

## Qué NO conseguimos todavía
- Instalar la build en un iPhone real.
- Probar login real de Instagram/YouTube.
- Validar anuncios reales de YouTube.
- Obtener Screen Time real del dispositivo.

Esos son tests de dispositivo y vienen después.
