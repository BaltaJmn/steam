# Kobold Keepers: prototipo (Godot 4.7)

Prototipo *greybox* para comprobar si el bucle es divertido: palear, darle a la manivela, apilar, colocar tesoros y no hacer ruido. Todo el arte es provisional y se genera por código.

> ⚠️ Este proyecto se ha escrito sin poder abrir Godot (el entorno donde se creó no permitía ejecutarlo). Ha pasado una revisión estática de sintaxis y estructura, pero **la primera vez que lo abras puede salir algún error** en el panel *Output*/*Debugger*. Copia el mensaje tal cual y se arregla rápido.

## Cómo abrirlo

1. Descarga **Godot 4.7** (versión estándar, no la .NET) desde <https://godotengine.org/download>.
2. Abre Godot → **Import** → selecciona `game/project.godot`.
3. Pulsa **F5** (o el botón ▶). Se abre el menú: **Jugar solo**.

## Probar el coop en tu propio PC

1. En Godot: menú **Debug → Customize Run Instances...** → activa *Enable Multiple Instances* y pon **2** (o hasta 4).
2. Pulsa **F5**: se abren dos ventanas.
3. En una: **Crear partida (host)**. En la otra: **Unirse** con `127.0.0.1`.

Para jugar con un amigo por internet en el prototipo, el host tiene que abrir el puerto **7777 (UDP)** en su router y pasarle su IP pública. Esto desaparece al pasar a Steam (ver *Siguientes pasos*).

## Controles

| Tecla | Acción |
|---|---|
| WASD | Moverse |
| Ratón | Mirar |
| Shift | Correr (**hace ruido**) |
| Espacio | Saltar (caer de golpe también hace ruido) |
| E / clic izquierdo | Interactuar (mantener pulsado en la montaña y en la manivela) |
| Q | Soltar lo que llevas (las monedas vuelven a su sitio) |
| Esc | Pausa / cerrar menús |

## El bucle

```
Montaña ──[E palear]──► saco de monedas mezcladas
   ──► tolva de la clasificadora ──[mantener E en la manivela]──► cubetas de cobre / plata / oro
   ──[E coger bolsa]──► torre de su tipo en la cámara acorazada ──► paga
Tesoros por el suelo ──[E coger]──► su hueco con silueta en las estanterías ──► paga
Paga ──► tablón de MEJORAS (compartidas): pala, saco, manivela, botas, kobolds, rueda, tobogán
```

**Ruido:** correr, saltar, vaciar sacos o tirar tesoros llena la barra de ruido de todo el grupo. Si llega al máximo, el dragón resopla en sueños y **sale volando el kobold que más ruido ha hecho** (no se pierde nada).

**Objetivo:** las 6.000 monedas en sus torres y los 12 tesoros en su sitio.

## Dónde tocar cada cosa

| Quiero cambiar... | Archivo |
|---|---|
| Números (monedas, precios, ruido, velocidad de los kobolds) | `scripts/balance.gd` |
| Dónde está cada cosa del mapa (montaña, máquina, estanterías, tesoros) | `scenes/world.tscn` (ábrelo en el editor y mueve los nodos) |
| Añadir un tesoro | Duplica un nodo `Item` en `world.tscn`, dale un `item_id` nuevo y un `type_key`, y añade su hueco en una estantería (`slot_types`) |
| Colores y materiales | `scripts/visuals.gd` |
| La cueva (paredes, luces, niebla) | `scripts/cave.gd` |
| Textos de la interfaz | `scripts/hud.gd` y `scripts/menu.gd` |

## Cómo está hecho (resumen)

- **`Game` (autoload)** guarda todo el estado de la partida. **Solo el host lo cambia**: los jugadores piden cosas con `Game.request("_srv_algo", [...])`, el host valida, aplica y reenvía a todos lo que ha cambiado. En solitario funciona igual, sin red. Así no hay trampas ni desincronizaciones, y se evita el tipo de bugs de multijugador que tuvo Moon Sweepers.
- **`Network` (autoload)** crea la conexión. Hoy usa ENet (IP directa).
- **Cada objeto del mundo** (montaña, clasificadora, torres, tesoros, huecos) escucha `Game.changed` y se redibuja. Si implementa `get_prompt()` e `interact()`, el jugador puede usarlo.
- **Arte provisional:** los scripts con `@tool` generan sus formas también en el editor, así que ves el mapa al abrir `world.tscn`. Para poner arte de verdad se sustituyen esas formas por modelos sin tocar la lógica.

## Siguientes pasos

1. **Jugarlo y apuntar qué es divertido y qué no.** Es el objetivo del prototipo.
2. Ajustar `balance.gd`. Una simulación rápida de la economía da **unos 11–12 min en solitario jugando de forma óptima** (con una mejora cada 30–60 s en los primeros minutos). Jugando de verdad saldrá algo más, del orden de 15–25 min. Si se queda corto, sube `PILE_START` o los precios.
3. **Steam:** instalar **GodotSteam** (Asset Library → "GodotSteam GDExtension") y cambiar en `scripts/autoload/network.gd` el `ENetMultiplayerPeer` por `SteamMultiplayerPeer` + lobbies de Steam. El resto del juego no cambia.
4. Arte: kobold, dragón, tesoros y cueva (low-poly) y sonido (monedas, ronquidos, resoplido).
