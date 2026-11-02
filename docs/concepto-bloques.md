# The Floor Is Bricks (nombre provisional)

> **Estado:** dirección elegida. El prototipo de [`/game`](../game/README.md) la implementa: habitación con 10 mesas, piezas por el suelo y estilo creamy y lofi.
> **Lema:** *"Todo el mundo sabe lo que pasa cuando pisas una."*

---

## 1. La idea

Una habitación tranquila al atardecer, con **10 mesas**. El suelo está **lleno de piezas de construcción** de colores, mezcladas y repartidas en grupitos por todas partes (también debajo de las mesas). Hay que **buscarlas, clasificarlas por color y montar en cada mesa una figura muy sencilla**: pato, gato, casita, árbol, barco, cohete, seta, flor, pez y taza.

**Estilo: creamy, lofi y minimalista.**
- Colores crema y pastel apagados, luz cálida de atardecer entrando por la ventana y lámparas colgantes.
- Plantas, una estantería, un tocadiscos.
- Un filtro suave de grano y viñeta.
- Todo son bloques y formas geométricas simples, sin texturas, sin contornos y sin amenazas.

---

## 2. Cómo funciona

```
Grupitos de piezas por el suelo ──[buscar y recoger]──► cesta de piezas mezcladas
   ──► tolva de la clasificadora ──[manivela]──► 6 cubetas, una por color
   ──[coger un color]──► mesa de una figura ──► los bloques aparecen en su sitio
Piezas especiales (ojos, puerta, manzana, bandera, ventanilla), escondidas y con un brillito
   ──[encontrar]──► con la pieza en la mano, mira su mesa y E
Figura terminada ──► confeti y pegatinas extra ──► mejoras
```

- **Suelo:** unos 40 grupitos con exactamente las piezas que hacen falta (280). Los reparte una semilla fija, así que todos los jugadores los ven en el mismo sitio. Algunos están debajo de las mesas.
- **Clasificar:** la máquina del centro separa por **color**, y cada cubeta es de un color.
- **Construir:** cada mesa enseña la silueta de su figura. Al llevarle piezas de un color, los bloques de ese color aparecen en su sitio, de abajo arriba. Si llevas de más, el resto se queda en la cesta. Mirar una mesa con las manos vacías te dice qué le falta.
- **Mejoras (con pegatinas):**
  - cesta más grande;
  - recoger a puñados;
  - manivela engrasada;
  - ayudantes (muñequitos de cuerda que traen piezas a la tolva);
  - motorcito (la clasificadora gira sola);
  - cinta transportadora (las piezas clasificadas van solas a las mesas).
- **Coop (1–4):** todo es compartido. Unos buscan y recogen, otros clasifican y otros montan.

### Las 10 figuras

| Figura | Colores | Bloques | Pieza especial |
|---|---|---|---|
| Pato | amarillo, rosa | 27 | 2 ojos |
| Gato | azul, crema | 32 | 2 ojos |
| Casita | crema, rosa, azul | 41 | puerta |
| Árbol | verde, marrón | 21 | manzana |
| Barco | marrón, crema | 22 | bandera |
| Cohete | crema, rosa | 25 | ventanilla |
| Seta | rosa, crema | 20 | — |
| Flor | amarillo, verde, rosa | 32 | — |
| Pez | azul | 22 | ojo |
| Taza | crema, marrón | 38 | — |

Entre 20 y 41 piezas por figura: cada una se termina en pocos minutos y hay variedad. Las maquetas están en `game/scripts/figure_data.gd` como capas de caracteres. Se pueden cambiar o añadir figuras (y mesas en `world.tscn`) sin tocar código, y las piezas del suelo se recalculan solas.

---

## 3. Competencia y en qué nos diferenciamos

| Juego | Qué es |
|---|---|
| [*Brick by Brick: Tidy Up the Small Town!*](https://store.steampowered.com/app/5228920/Brick_by_Brick_Tidy_Up_the_Small_Town/) | Clasificar ladrillos por forma y color y colocarlos según planos para reconstruir un pueblo. Coop de 5. Salió el 15 oct 2026 |
| [*Tidy Up: Bricks n Blocks*](https://store.steampowered.com/app/5516980) | Piezas por el suelo de habitaciones que se colocan en estanterías por forma y en cubos por color. Un jugador. Sale el 17 nov 2026 |

Lo nuestro:
- **Clasificación a granel con máquinas** y automatización incremental (ayudantes, motorcito, cinta).
- **Figuras que se montan solas** pieza a pieza al entregar colores.
- **Buscar por la habitación**, con piezas especiales escondidas.
- **Estética creamy y lofi** muy reconocible.

**Ideas para diferenciarse más** (aparcadas para no complicar el prototipo):
- **Figuras que cobran vida y ayudan** al terminarlas: el barco reparte piezas, el cohete despega al final...
- **Una amenaza suave y cómica**, como papá entrando descalzo de noche. El sistema de ruido sigue en el código, apagado con `Balance.NOISE_ENABLED`.

---

## 4. Marca registrada

- No usar el nombre **LEGO** ni su logo: el juego habla de "piezas" o "bloques".
- La forma de la **minifigura** de LEGO está registrada como marca en la UE. Nuestros personajes son muñecos de madera simples (cuerpo, cabeza y ojos), con diseño propio.
- Los bloques con pivotes son genéricos (las patentes caducaron hace décadas).

---

## 5. Pendiente de decidir

1. ¿Añadimos que las figuras terminadas cobren vida y ayuden?
2. ¿Queremos alguna tensión suave (papá descalzo) o se queda 100 % cozy?
3. Para el juego completo: ¿más habitaciones (cada una con sus mesas y su ambiente) en vez de figuras más grandes?
4. ¿Te vale *The Floor Is Bricks* como nombre? No he encontrado ningún juego que se llame así.
