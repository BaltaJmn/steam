# Couch Crew: prototipo (Godot 4.7)

> Papá lleva 20 años echándose la siesta en el mismo sofá. Entre los cojines hay ya un ecosistema propio. La familia ha contratado a **MicroLimpiezas Menguantes S.L.**, que encoge a sus becarios con un rayo para limpiar sin despertarle. El encargo: **recuperar el mando de la tele.**

Prototipo *greybox* para comprobar si el bucle es divertido: recoger migas, darle a la manivela, llenar los cuencos, devolver los objetos perdidos y no hacer ruido. Todo el arte es provisional y se genera por código.

> ⚠️ Este proyecto se ha escrito sin poder abrir Godot (el entorno donde se creó no permitía ejecutarlo). Ha pasado una revisión estática de sintaxis y estructura, y una revisión independiente contra el código fuente de Godot 4.7, pero **la primera vez que lo abras puede salir algún error** en el panel *Output*/*Debugger*. Copia el mensaje tal cual y se arregla rápido.

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
| Q | Soltar lo que llevas (las migas vuelven a su sitio) |
| Esc | Pausa / cerrar menús |

## El bucle

```
Montaña de migas ──[E recoger]──► cubo de migas mezcladas
   ──► tolva de la clasificadora ──[mantener E en la manivela]──► cubetas de palomitas / ganchitos / galleta
   ──[E llenar el cubo]──► cuenco de su tipo ──► calderilla (entre las migas aparecen monedas)
Objetos perdidos (botones, bloques de juguete, pendientes, dados) ──[E coger]──► su hueco en las bandejas ──► calderilla
Calderilla ──► tablón de MEJORAS (compartidas): cuchara, cubo, manivela, zapatillas, hormigas, hámster, tobogán de pajita
```

**Ruido:** correr, saltar, vaciar el recipiente o tirar objetos llena la barra de ruido de todo el grupo. Papá está tumbado encima: el cojín de arriba se hunde con su peso y sube y baja al respirar. Con mucho ruido murmura y asoma los dedos por la rendija. Si la barra llega al máximo, **mete la mano por la rendija y va a por el becario que más ruido ha hecho**. Corriendo se puede esquivar (pero correr hace ruido). Si te pilla, sales volando (no se pierde nada). Correr unos 10 s seguidos, o menos si saltas, basta para despertarle a propósito.

**Objetivo:** las 6.000 migas en sus cuencos y los 12 objetos en su sitio. Debajo de la montaña está **el mando de la tele**, que va apareciendo según la vacías.

## Dónde tocar cada cosa

| Quiero cambiar... | Archivo |
|---|---|
| Números (migas, precios, ruido, velocidad de las hormigas) y nombres de mejoras | `scripts/balance.gd` |
| Dónde está cada cosa del mapa (montaña, máquina, cuencos, bandejas, objetos) | `scenes/world.tscn` (ábrelo en el editor y mueve los nodos) |
| Añadir un objeto perdido | Duplica un nodo `Item` en `world.tscn`, dale un `item_id` nuevo y un `type_key` (`forma_color`, p. ej. `dice_red`), y añade su hueco en una bandeja (`slot_types`) |
| Colores, materiales y formas provisionales | `scripts/visuals.gd` |
| El escenario (cojines, pelusas, focos, luz de la tele) | `scripts/cave.gd` |
| Papá (cojín hundido, la mano que baja por la rendija, frases que murmura) | `scripts/sleeper.gd` y `Balance.DAD_MUMBLES` |
| Textos de la interfaz | `scripts/hud.gd` y `scripts/menu.gd` |

## Cómo está hecho (resumen)

- **`Game` (autoload)** guarda todo el estado de la partida. **Solo el host lo cambia**: los jugadores piden cosas con `Game.request("_srv_algo", [...])`, el host valida, aplica y reenvía a todos lo que ha cambiado. En solitario funciona igual, sin red. Así no hay trampas ni desincronizaciones, y se evita el tipo de bugs de multijugador que tuvo Moon Sweepers.
- **`Network` (autoload)** crea la conexión. Hoy usa ENet (IP directa).
- **Cada objeto del mundo** (montaña, clasificadora, cuencos, objetos, huecos) escucha `Game.changed` y se redibuja. Si implementa `get_prompt()` e `interact()`, el jugador puede usarlo.
- **Arte provisional:** los scripts con `@tool` generan sus formas también en el editor, así que ves el mapa al abrir `world.tscn`. Para poner arte de verdad se sustituyen esas formas por modelos sin tocar la lógica.

## Siguientes pasos

1. **Jugarlo y apuntar qué es divertido y qué no.** Es el objetivo del prototipo.
2. Ajustar `balance.gd`. Una simulación rápida de la economía da **unos 11–12 min en solitario jugando de forma óptima** (con una mejora cada 30–60 s en los primeros minutos). Jugando de verdad saldrá algo más, del orden de 15–25 min. Si se queda corto, sube `PILE_START` o los precios.
3. **Steam:** instalar **GodotSteam** (Asset Library → "GodotSteam GDExtension") y cambiar en `scripts/autoload/network.gd` el `ENetMultiplayerPeer` por el peer multijugador de Steam + lobbies. El resto del juego no cambia.
4. Arte: becarios, papá, cojines, migas y objetos (low-poly) y sonido (ronquidos, crujido de migas, la tele de fondo).
