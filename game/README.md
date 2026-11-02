# The Floor Is Bricks: prototipo (Godot 4.7)

> Una habitación tranquila al atardecer con 10 mesas y el suelo lleno de piezas. Búscalas, clasifícalas por color y monta una figura en cada mesa antes de que alguien pise una.

Prototipo con estilo **creamy, lofi y minimalista**: todo son bloques y formas geométricas en tonos crema, generados por código.

> ⚠️ Este proyecto se escribe sin poder ejecutar Godot (el entorno donde se crea no lo permite). Pasa revisiones estáticas de sintaxis y estructura, pero **puede salir algún error** al abrirlo. Copia el mensaje del panel *Output*/*Debugger* tal cual y se arregla rápido.

## Cómo abrirlo

1. Descarga **Godot 4.7** (versión estándar, no la .NET) desde <https://godotengine.org/download>.
2. Abre Godot → **Import** → selecciona `game/project.godot`.
3. Pulsa **F5** (o el botón ▶). Se abre el menú: **Jugar solo**.

## Probar el coop en tu propio PC

1. En Godot: menú **Debug → Customize Run Instances...** → activa *Enable Multiple Instances* y pon **2** (o hasta 4).
2. Pulsa **F5**: se abren dos ventanas.
3. En una: **Crear partida (host)**. En la otra: **Unirse** con `127.0.0.1`.

Para jugar con un amigo por internet en el prototipo, el host tiene que abrir el puerto **7777 (UDP)** en su router y pasarle su IP pública. Esto desaparece al pasar a Steam.

## Controles

| Tecla | Acción |
|---|---|
| WASD | Moverse |
| Ratón | Mirar |
| Shift | Correr |
| Espacio | Saltar |
| E / clic izquierdo | Interactuar (mantener pulsado en los grupitos de piezas) |
| Q | Soltar lo que llevas (las piezas vuelven a su sitio) |
| Esc | Pausa / cerrar menús |

## El bucle

```
Grupitos de piezas por el suelo ──[E recoger]──► cesta con piezas de varios colores
   ──► cualquier mesa [E]: su clasificador se queda solo lo que necesita ──► los bloques aparecen en su sitio
Piezas especiales (ojos, puerta, manzana, bandera, ventanilla, con un brillito) ──[E coger]──► mira su mesa y E
Pegatinas ──► tablón de MEJORAS (compartidas): cesta, puñados, zapatillas, lupa, ayudantes de cuerda
```

**Objetivo:** montar las 10 figuras (280 piezas + 9 piezas especiales). Mira también debajo de las mesas. El clasificador de cada mesa enseña, por colores, cuántas piezas lleva y cuántas necesita.

## Dónde tocar cada cosa

| Quiero cambiar... | Archivo |
|---|---|
| **Las figuras** (forma, colores, piezas especiales) | `scripts/figure_data.gd`: cada figura son capas de caracteres, fáciles de editar |
| Números (precios, velocidades, cuántas piezas se cogen...) | `scripts/balance.gd` |
| Dónde está cada cosa (mesas, piezas especiales, tablón) | `scenes/world.tscn` (ábrelo en el editor y mueve los nodos) |
| Cuántos grupitos de piezas hay y por dónde | `scripts/floor_scatter.gd` (y su nodo `FloorScatter` en `world.tscn`) |
| Colores, materiales y el bloque con pivotes | `scripts/visuals.gd` |
| La habitación (paredes, ventana, luces, muebles, filtro lofi) | `scripts/room.gd` |
| Textos de la interfaz | `scripts/hud.gd` y `scripts/menu.gd` |

Si añades o cambias figuras, las piezas del suelo se recalculan solas: siempre hay exactamente las que hacen falta.

## Cómo está hecho (resumen)

- **`Game` (autoload)** guarda todo el estado. **Solo el host lo cambia**: los jugadores piden cosas con `Game.request("_srv_algo", [...])` y el host valida, aplica y reenvía lo que ha cambiado. En solitario funciona igual, sin red.
- **`Network` (autoload)** crea la conexión. Hoy usa ENet (IP directa); para Steam se cambia por GodotSteam.
- **Miles de bloques** se dibujan con `MultiMesh`: un solo bloque con pivotes y un color por pieza.
- **Los scripts con `@tool`** generan sus formas también en el editor, así que ves el mapa (y las figuras terminadas) al abrir `world.tscn`.
- **Ruido:** el sistema sigue en `Game`, pero está apagado (`Balance.NOISE_ENABLED = false`) para que el juego sea cozy.

## Siguientes pasos

1. **Jugarlo y apuntar qué es divertido y qué no.**
2. Ajustar `balance.gd` y el tamaño de las figuras.
3. Sonido: clic de piezas, una música tranquila.
4. **Steam:** GodotSteam (Asset Library → "GodotSteam GDExtension") en `scripts/autoload/network.gd`.
