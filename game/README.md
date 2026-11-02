# The Floor Is Bricks: prototipo (Godot 4.7)

> El suelo del cuarto de Mateo está cubierto de piezas de construcción. Sois sus figuritas: recogedlas, clasificadlas por color y montad las 6 figuras antes de que alguien pise una.

Prototipo con estilo **cozy y minimalista**: todo son bloques y formas geométricas con colores pastel, generados por código.

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
| E / clic izquierdo | Interactuar (mantener pulsado en los montones y en la manivela) |
| Q | Soltar lo que llevas (las piezas vuelven a su sitio) |
| Esc | Pausa / cerrar menús |

## El bucle

```
Montones del suelo ──[E recoger]──► cesta de piezas mezcladas
   ──► tolva de la clasificadora ──[mantener E en la manivela]──► 6 cubetas, una por color
   ──[E coger un color]──► figura que lo necesite ──► los bloques aparecen en su sitio
Piezas especiales (ojos, puerta, manzana, bandera, ventanilla) ──[E coger]──► mira su figura y E
Pegatinas ──► tablón de MEJORAS (compartidas): cesta, puñados, manivela, ayudantes, motorcito, cinta
```

**Objetivo:** montar las 6 figuras (310 piezas + 8 piezas especiales). Mirar una figura sin llevar nada te dice qué colores le faltan.

## Dónde tocar cada cosa

| Quiero cambiar... | Archivo |
|---|---|
| **Las figuras** (forma, colores, piezas especiales) | `scripts/figure_data.gd`: cada figura son capas de caracteres, fáciles de editar |
| Números (precios, velocidades, cuántas piezas se cogen...) | `scripts/balance.gd` |
| Dónde está cada cosa (figuras, montones, máquina, piezas especiales) | `scenes/world.tscn` (ábrelo en el editor y mueve los nodos) |
| Colores, materiales y el bloque con pivotes | `scripts/visuals.gd` |
| El cuarto (suelo, luz, cielo, muebles) | `scripts/room.gd` |
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
