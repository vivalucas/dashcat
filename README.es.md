# DashCat

Una aplicación ligera para la barra de menús de macOS que combina historial del portapapeles, monitoreo del sistema, prevención de suspensión e inversión de la rueda del mouse en un gato que corre.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Italiano](README.it.md) | [繁體中文](README.zh-TW.md) | [Русский](README.ru.md)

---

Tenía varias herramientas funcionando en la barra de menús de macOS: una para la carga del sistema, otra para el historial del portapapeles (Maccy), otra para evitar la suspensión (Caffeine) y otra solución para la dirección de la rueda de un mouse externo. Varios iconos, varios procesos en segundo plano, me parecía un desperdicio. Así que construí una desde cero, manteniendo solo lo esencial: monitoreo del sistema, gestión del portapapeles, prevención de suspensión e inversión de la rueda del mouse. El monitor está optimizado para Apple Silicon, el gestor del portapapeles es ágil y eficiente, y la prevención de suspensión junto con la inversión de la rueda están integradas. Justo lo necesario, nada más.

Así nació DashCat. Un gato en la barra de menús: cuanto más rápido corre, mayor es la carga; clic izquierdo para ver el historial del portapapeles con búsqueda instantánea; clic derecho para la prevención de suspensión, dirección de la rueda del mouse, modo de monitoreo y cambio de idioma. Un icono cubre varias herramientas cotidianas. Cero dependencias, uso mínimo de recursos, todos los datos almacenados localmente.

---

## Funciones

- **Gestor de Portapapeles**
  - Clic izquierdo en el icono del gato para abrir el panel de historial del portapapeles
  - Filtrado de búsqueda en tiempo real
  - Clic para copiar, `Option + Enter` para copiar como texto sin formato
  - Clic derecho en un elemento para fijarlo arriba
  - Soporte para texto e imágenes (imágenes comprimidas en JPEG, almacenamiento de imágenes opcional)
  - Retención personalizable: 7 / 14 / 30 / 90 días, para siempre, o un valor personalizado de 1-365 días
  - Todos los datos almacenados localmente — totalmente offline, sin recopilación de datos

- **Monitor del Sistema**
  - El menú de clic derecho se organiza alrededor del elemento del gato: Visualización (Gato + valor, Solo gato, Solo valor) y Métrica (Combinado, CPU, Memoria, CPU + memoria)
  - La velocidad de animación del gato refleja la carga del sistema en tiempo real — cuanto más rápido corre, mayor es la presión
  - El modo combinado elige automáticamente el mayor valor entre CPU y memoria para la animación
  - CPU + memoria muestra porcentajes C/M compactos en dos líneas y usa automáticamente Solo valor

- **Batería compacta**
  - Indicador opcional de batería independiente en la barra de menús, separado del gato
  - Muestra un número estrecho sin signo de porcentaje, con un relleno verde sutil para barras de menús llenas
  - Puede ocultarse automáticamente al conectar corriente, sin dejar espacio en la barra
  - Usa información de energía del sistema con actualización de baja frecuencia, sin animación y con carga mínima

- **Prevención de Suspensión**
  - Color predeterminado: normal — el sistema puede suspenderse
  - Azul: evitar suspensión por inactividad del sistema (la pantalla puede apagarse)
  - Naranja: evitar que la pantalla se apague
  - Cambiar directamente desde el menú contextual — el color del gato cambia en tiempo real

- **Más**
  - 11 idiomas: English, 中文, 日本語, 한국어, Deutsch, Français, Español, Português, Italiano, 繁體中文, Русский
  - Invertir la rueda de un mouse externo manteniendo el desplazamiento natural de macOS en el trackpad
  - Crear un archivo TXT o Markdown en la carpeta actual de Finder, mostrando la ruta antes de crear y con opción de elegir otra carpeta
  - Soporte para abrir al iniciar sesión
  - Eficiente: límite de animación de 12 fps, intervalo de muestreo de 5 s, pausa automática en suspensión del sistema
  - Cero dependencias externas — AppKit + Swift puro

## Requisitos

- macOS 13 (Ventura) o posterior
- Mac con Apple Silicon (chips de la serie M)

## Instalación

**Opción 1: Instalador DMG**

1. Ve a la página [Releases](../../releases) y descarga el último `DashCat-<versión>.dmg`
2. Abre el DMG y arrastra DashCat a tu carpeta de Aplicaciones
3. En el primer inicio, macOS puede mostrar "la aplicación está dañada" o "no se puede verificar el desarrollador" — esto es Gatekeeper bloqueando una aplicación sin firmar; la aplicación está bien. Ejecuta el siguiente comando en Terminal para eliminar la cuarentena:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Luego doble clic para iniciar normalmente. Alternativamente, clic derecho → Abrir → clic en Abrir en el diálogo.

**Opción 2: Compilar desde el código fuente (sin necesidad de evitar Gatekeeper)**

1. Clona este repositorio
2. Abre `DashCat.xcodeproj` en Xcode
3. Selecciona tu propia cuenta de desarrollador en **Signing & Capabilities**
4. Ejecuta con `⌘R` — Xcode firma la aplicación automáticamente

## Uso

- **Clic izquierdo** en el icono del gato: abrir panel de historial del portapapeles
  - Escribe en el cuadro de búsqueda para filtrar
  - Clic en un elemento para copiarlo
  - `Option + Enter` para copiar como texto sin formato
  - Clic derecho en un elemento para fijarlo o desfijarlo
- **Clic derecho** en el icono del gato: abrir menú de configuración
  - Configurar el elemento del gato por visualización y métrica
  - Gestionar historial del portapapeles (guardar imágenes, días de retención, borrar historial)
  - Activar el elemento de batería independiente y ocultarlo al conectar corriente
  - Crear un archivo en la carpeta actual de Finder, invertir rueda del mouse, cambiar idioma, configurar inicio al iniciar sesión

## Preguntas Frecuentes

**¿Dónde se almacenan los datos del portapapeles?**

`~/Library/Application Support/DashCat/` — `clipboard.db` para registros de texto, `Images/` para archivos de imagen. Borrar el historial limpia ambos.

**¿Cuánto espacio en disco usan las imágenes?**

Las imágenes se almacenan como JPEG (unos cientos de KB cada una). El guardado de imágenes está desactivado por defecto. Cuando se activa, hay un límite total de 500 MB — las imágenes no fijadas más antiguas se eliminan automáticamente cuando se alcanza el límite.

**¿Qué significan los colores del gato?**

Predeterminado → comportamiento normal de suspensión. **Azul** → evitando suspensión del sistema. **Naranja** → evitando suspensión de pantalla. Cambia desde el menú contextual.

**¿Por qué invertir la rueda del mouse requiere permiso de Accesibilidad?**

DashCat necesita identificar eventos de rueda del mouse en el flujo de eventos del sistema e invertir su dirección, por lo que macOS requiere permiso de Accesibilidad. Sin él, el historial del portapapeles, el monitoreo del sistema y la prevención de suspensión siguen funcionando; el menú contextual muestra un aviso y un acceso a Ajustes del Sistema.

**¿Por qué crear un archivo en Finder pide controlar Finder?**

DashCat solo lee la carpeta actual de Finder cuando eliges “Nuevo archivo en la carpeta actual de Finder”. macOS puede mostrar un permiso de automatización para obtener esa ruta; DashCat no supervisa Finder en segundo plano. El comando está en el menú de DashCat y no se inserta en el menú contextual de un área vacía de Finder.

**¿Soporta Macs con Intel?**

No. Solo arm64, diseñado para Apple Silicon.

**¿En qué se diferencia de Maccy / CopyClip / Amphetamine?**

DashCat combina la gestión del portapapeles (como Maccy), monitoreo del sistema y prevención de suspensión (como Amphetamine / Caffeine) en una sola aplicación ligera de la barra de menús — un icono, un proceso, cero dependencias. AppKit puro para un uso mínimo de memoria.

**¿Por qué macOS dice que la aplicación está "dañada" o "no se puede verificar el desarrollador" en el primer inicio?**

El binario precompilado no está firmado con un certificado de desarrollador de Apple, por lo que Gatekeeper muestra este mensaje — la aplicación está bien. Ejecuta `xattr -cr /Applications/DashCat.app` en Terminal para eliminar la cuarentena, luego inicia normalmente. Para evitar este paso por completo, compila desde el código fuente y firma con tu propia cuenta.

## Licencia

MIT License
