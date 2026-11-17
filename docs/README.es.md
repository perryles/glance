<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">Desbloquea tu Mac con el rostro</h3>

<p align="center">
  <a href="../README.md" lang="en">English</a> ·
  <a href="README.zh-CN.md" lang="zh-CN">简体中文</a> ·
  <a href="README.ja.md" lang="ja">日本語</a> ·
  <a href="README.es.md" lang="es">Español</a> ·
  <a href="README.fr.md" lang="fr">Français</a> ·
  <a href="README.de.md" lang="de">Deutsch</a> ·
  <a href="README.pt-BR.md" lang="pt-BR">Português (Brasil)</a> ·
  <a href="README.tr.md" lang="tr">Türkçe</a>
</p>

<p align="center">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="Licencia MIT"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

Glance lleva a tu Mac una experiencia similar a Face ID en el iPhone. Desbloquea tu Mac con una mirada, sin escribir ni alcanzar la tecla Touch ID. Todo se ejecuta en el dispositivo mediante los frameworks Vision y Core ML de Apple, de modo que tus datos faciales y tu contraseña del Mac nunca se envían a internet. La interfaz se integra en la muesca del MacBook con animaciones fluidas al estilo de Dynamic Island.

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## Lee esto antes de descargar
> ## Glance no es tan seguro como Face ID o Touch ID de Apple
>
> Los MacBook carecen de los sensores de profundidad que hacen que Face ID en el iPhone sea fiable y seguro. Un iPhone crea un mapa 3D del rostro, mientras que la cámara del MacBook captura una imagen plana en 2D. Esto implica lo siguiente.
>
> - Glance puede detectar y rechazar, con una confianza razonable, una foto impresa o una foto en la pantalla de un teléfono (debes activar la detección de presencia real de nivel alto).
> - Glance no rechaza de forma fiable un vídeo de tu rostro.
> - macOS no ofrece una API que permita a una aplicación de terceros autorizar el inicio de sesión, por lo que Glance desbloquea el equipo escribiendo tu contraseña guardada en la pantalla de bloqueo.
>
> Glance ofrece comodidad, no una mejora de seguridad. Continúa únicamente si aceptas este compromiso.

## Instalación

**Requisitos**

- macOS 15 Sequoia o posterior
- Mac con Apple Silicon o Intel

<a href="https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Descargar para Mac" /></a>

Abre el archivo `.dmg`, arrastra Glance a `/Applications` y abre la aplicación.

## Permisos

| Permiso | Motivo |
|---|---|
| **Cámara** | Para detectar tu rostro. Los fotogramas se procesan en memoria y nunca se escriben en el disco. |
| **Accesibilidad** | Para escribir tu contraseña en la pantalla de bloqueo. |
| **Touch ID** | Protege el acceso a la clave que cifra tus datos faciales y tu contraseña. |

## Cómo funciona

1. Abre la aplicación y sigue la configuración inicial para registrar tu rostro. Glance te guía para capturarlo mientras giras la cabeza en nueve direcciones. Cada fotograma se convierte en un *vector de características* de 512 números, una huella matemática, y la imagen se descarta.
2. Introduce la contraseña de tu Mac una vez. Se cifra y queda protegida mediante Touch ID.
3. Cuando tu Mac se bloquea o sale del reposo, aparece una animación en la muesca y comienza la búsqueda de un rostro.
4. Si el rostro coincide contigo y las comprobaciones de presencia real confirman que eres una persona real, Glance escribe la contraseña y desbloquea el Mac.

## Funciones

| Función | Descripción |
|---|---|
| **Desbloqueo facial** | Se activa al salir del reposo, al bloquearse o al pulsar espacio en la pantalla de bloqueo. Puedes combinar estas opciones. |
| **Varias identidades** | Registra a varias personas o distintas apariencias tuyas, con gafas, barba o diferente iluminación. Puedes desactivar cada identidad sin eliminarla. |
| **Detección de presencia real** | Analiza movimientos y reflejos para distinguir un rostro real de una foto. Permite elegir un nivel bajo, alto o desactivarla. |
| **Interfaz en la muesca** | Una cápsula se expande para mostrar la animación de escaneo y los estados de éxito y error. Pasa el puntero por encima para reintentar o desactiva las animaciones por completo para que Glance permanezca invisible. |
| **Cámara y pantalla** | Elige la cámara que quieres usar, con cámaras distintas para la pantalla integrada y un monitor externo. |
| **Bloqueo automático de sesiones** | La sesión de Touch ID vuelve a bloquearse tras el período de inactividad que elijas, para evitar que un Mac desatendido permanezca autorizado indefinidamente. |
| **Respuesta háptica del trackpad** | Al pasar el puntero sobre la muesca, se activa la respuesta háptica. |
| **Compatibilidad con Mac sin muesca** | En los Mac sin muesca se muestra una interfaz en forma de cápsula al estilo de Dynamic Island. |
| **Control de tus datos** | Edita o elimina tus registros faciales o tu contraseña guardada en cualquier momento. Los archivos cifrados correspondientes se eliminan inmediatamente. |

---

# Privacidad y seguridad

Glance está diseñado para mantener los datos biométricos y las credenciales en el dispositivo.

### Datos faciales

Glance nunca guarda imágenes de la cámara. Durante el registro, cada rostro capturado se convierte en un **vector de características de 512 dimensiones** mediante un modelo de Core ML basado en ArcFace. Después se descarta el fotograma original.

Los vectores se guardan localmente, cifrados con **AES-GCM**.

### Credenciales

La contraseña de tu Mac se guarda cifrada y nunca se escribe en el disco en texto sin formato. La clave de cifrado es una **clave AES de 256 bits guardada en el llavero de macOS**, protegida con `userPresence`, que requiere Touch ID o la contraseña del dispositivo.

La clave solo permanece en memoria mientras hay una sesión autorizada de Glance activa.

### Proceso de desbloqueo

Para que Glance escriba tu contraseña, deben cumplirse todas estas condiciones.

1. Hay una sesión válida y autorizada de Glance.
2. El Mac está realmente en la pantalla de bloqueo.
3. Una identidad habilitada supera el umbral de similitud configurado.
4. El rostro detectado pasa las comprobaciones de presencia real.
5. El permiso de accesibilidad está disponible para introducir la contraseña.

El reconocimiento facial y la detección de presencia real se ejecutan de forma independiente y ambos deben completarse correctamente antes de introducir la contraseña.

### Procesamiento local

El reconocimiento facial, el registro de rostros y la detección de presencia real se ejecutan íntegramente en el dispositivo con Vision y Core ML. Glance no envía datos faciales, fotogramas de la cámara ni credenciales a un servidor.

### Cómo distingue un rostro de una foto

Se analizan cinco indicios independientes en una ventana móvil de unos 2 segundos, con dos funciones.

- **Indicios de rechazo**, que revelan una suplantación, como los reflejos de una pantalla o un rectángulo con forma de dispositivo alrededor del rostro. Cualquiera de ellos hace fallar el escaneo directamente y prevalece sobre los demás resultados.
- **Indicios de confirmación**, que revelan un rostro real, como la geometría plana o tridimensional de los puntos faciales, el paralaje de la nariz al girar la cabeza y los parpadeos. Basta con uno. Su ausencia nunca supone por sí sola un fallo, ya que una persona real puede permanecer quieta sin parpadear.

El nivel bajo solo utiliza los indicios de rechazo. El nivel alto utiliza tanto los de rechazo como los de confirmación.

### Face Lab

Face Lab es una consola de depuración oculta para probar el reconocimiento facial y la detección de presencia real con valores reales.

Para abrirla, ve a Ajustes → Acerca de y haz clic cinco veces en el icono de la aplicación. Aparecerá una sección de depuración en la barra lateral.

---

## Compilar desde el código fuente

### Requisitos previos

- macOS 15+
- Xcode 26+
- Python 3.9+ y Git, con conexión a Internet para la primera descarga de dependencias

### Pasos de compilación

1. Clona este fork y abre el proyecto.

   ```bash
   git clone https://github.com/perryles/glance.git
   cd glance
   open glance.xcodeproj
   ```

2. Selecciona el target y el esquema `glance`. En **Signing & Capabilities**, elige tu equipo de desarrollo de Apple y activa la firma automática. Utiliza `glance/glance.entitlements` para configurar los permisos de cámara y acceso al llavero protegido.

3. Elige **My Mac** como destino y pulsa `Cmd + R`. La primera compilación firmada descarga versiones fijas de las fuentes de libusb/libuvc e incluye automáticamente el servicio auxiliar de infrarrojos.

Para instalar una versión de desarrollo por separado, puedes utilizar tu propio Bundle Identifier. Las credenciales y los registros faciales se aíslan por identificador. Las actualizaciones automáticas se desactivan con un Bundle Identifier personalizado.

Consulta la guía de infrarrojos para la configuración y las opciones de compilación, incluida `GLANCE_ENABLE_INFRARED=NO`. [IR](../tools/infrared/README.md)

## Contribuciones

Se aceptan PR para corregir errores, añadir funciones, traducciones y documentación. Dirige los PR a la rama `main` de `perryles/glance` y describe los cambios y su verificación. [Abrir un Pull Request](https://github.com/perryles/glance/compare)

Comunica errores y propone funciones mediante GitHub Issues. [Issues](https://github.com/perryles/glance/issues)

## Agradecimientos

- Gracias a Jonathan Zhou y a los colaboradores del proyecto Glance original. [jonnyoo/glance](https://github.com/jonnyoo/glance)
- Gracias a JediBrooker por la implementación de infrarrojos BRIO en el PR #50. [PR #50](https://github.com/jonnyoo/glance/pull/50)
- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — por la física de la ventana de la muesca.
- **[InsightFace](https://github.com/deepinsight/insightface)** — por el modelo ArcFace que realiza el reconocimiento.
- **[Alcove](https://tryalcove.com)** — por su gran inspiración en el diseño.
- Gracias a Sparkle por las actualizaciones de la aplicación. [Sparkle](https://github.com/sparkle-project/Sparkle)
- Gracias a libusb y libuvc por la captura de infrarrojos por USB. [libusb](https://github.com/libusb/libusb), [libuvc](https://github.com/libuvc/libuvc)

## Licencia

El código fuente del proyecto se distribuye bajo la licencia MIT. Obra original © 2026 Jonathan Zhou. Contribuciones al fork © 2026 perryles y colaboradores. [MIT](../LICENSE)

Las bibliotecas de terceros y los pesos de los modelos tienen sus propias licencias. InsightFace especifica una licencia de investigación no comercial para sus modelos preentrenados. [Licencias de InsightFace](https://github.com/deepinsight/insightface#license)

Las compilaciones firmadas con infrarrojos incluyen las licencias nativas en `Contents/Resources/InfraredLicenses` y las fuentes y materiales para volver a enlazar en `Contents/Resources/InfraredSources.zip`.
