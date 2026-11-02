# The Floor Is Bricks (nombre provisional)

> **Estado:** dirección elegida. El prototipo de [`/game`](../game/README.md) ya la implementa.
> **Lema:** *"Todo el mundo sabe lo que pasa cuando pisas una."*

---

## 1. La idea

El suelo del cuarto de un niño está **cubierto de piezas de construcción** de colores, todas mezcladas. Sois figuritas: hay que **recogerlas, clasificarlas por color y montar 6 figuras muy sencillas** (pato, gato, casita, árbol, barco y cohete). Cuando todo está montado, el suelo queda impecable y mañana nadie pisará una pieza.

**Estilo: cozy y minimalista.** Todo son bloques y formas geométricas simples, con colores pastel planos, luz cálida de tarde y sombras suaves, como un diorama. Sin texturas, sin contornos y sin amenazas.

---

## 2. Cómo funciona

```
Piezas por el suelo ──[recoger]──► cesta de piezas mezcladas
   ──► tolva de la clasificadora ──[manivela]──► 6 cubetas, una por color
   ──[coger un color]──► obra de una figura ──► los bloques aparecen en su sitio
Piezas especiales (ojos, puerta, manzana, bandera, ventanilla) ──[buscar]──► su hueco en la figura
Figura terminada ──► confeti y pegatinas extra ──► mejoras
```

- **Suelo:** 6 montones con exactamente las piezas que hacen falta (310 en el prototipo). Se ven todas y desaparecen según se recogen.
- **Clasificar:** la máquina separa por **color**, y cada cubeta es de un color.
- **Construir:** cada figura enseña su silueta transparente. Al entregar piezas de un color, los bloques de ese color aparecen en su sitio, de abajo arriba. Si llevas más de las que faltan, el resto se queda en tu cesta para otra figura.
- **Toque final:** cada figura tiene 1 o 2 piezas especiales escondidas por el cuarto. Con una en la mano, miras la figura y pulsas E.
- **Mejoras (con pegatinas):**
  - cesta más grande;
  - recoger a puñados;
  - manivela engrasada;
  - ayudantes que llevan piezas del suelo a la tolva;
  - motorcito (la clasificadora gira sola);
  - cinta transportadora (las piezas clasificadas van solas a las figuras).
- **Coop (1–4):** todo es compartido. Los roles salen solos: unos recogen, otros clasifican y otros construyen o buscan las piezas especiales.

### Las 6 figuras

| Figura | Colores | Bloques | Pieza especial |
|---|---|---|---|
| Pato | amarillo, rojo | 59 | 2 ojos |
| Gato | azul, blanco | 52 | 2 ojos |
| Casita | blanco, rojo, azul | 55 | puerta |
| Árbol | verde, marrón | 42 | manzana |
| Barco | marrón, blanco | 44 | bandera |
| Cohete | blanco, rojo | 58 | ventanilla |

Las maquetas están en `game/scripts/figure_data.gd` como capas de caracteres: se pueden cambiar o añadir figuras sin tocar código.

---

## 3. Competencia y en qué nos diferenciamos

| Juego | Qué es |
|---|---|
| [*Brick by Brick: Tidy Up the Small Town!*](https://store.steampowered.com/app/5228920/Brick_by_Brick_Tidy_Up_the_Small_Town/) | Clasificar ladrillos por forma y color y colocarlos según planos para reconstruir un pueblo. Coop de 5. Salió el 15 oct 2026 |
| [*Tidy Up: Bricks n Blocks*](https://store.steampowered.com/app/5516980) | Piezas por el suelo de habitaciones que se colocan en estanterías por forma y en cubos por color. Un jugador. Sale el 17 nov 2026 |

Lo nuestro:
- **Clasificación a granel con máquinas** y automatización incremental (ayudantes, motorcito, cinta).
- **Figuras que se montan solas** pieza a pieza al entregar colores.
- **Escala de figurita** en un cuarto enorme.
- **Estética de diorama** pastel.

**Ideas para diferenciarse más** (aparcadas para no complicar el prototipo):
- **Figuras que cobran vida y ayudan** al terminarlas: el barco reparte piezas, el cohete despega al final...
- **Una amenaza suave y cómica**, como papá entrando descalzo de noche. El sistema de ruido sigue en el código, apagado con `Balance.NOISE_ENABLED`.

---

## 4. Marca registrada

- No usar el nombre **LEGO** ni su logo: el juego habla de "piezas" o "bloques".
- La forma de la **minifigura** de LEGO está registrada como marca en la UE. Nuestras figuritas son muñecos de madera simples (cuerpo, cabeza y ojos), con diseño propio.
- Los bloques con pivotes son genéricos (las patentes caducaron hace décadas).

---

## 5. Pendiente de decidir

1. ¿Añadimos que las figuras terminadas cobren vida y ayuden?
2. ¿Queremos alguna tensión suave (papá descalzo) o se queda 100 % cozy?
3. ¿Más figuras o más grandes para el juego completo? Ahora son unas 300 piezas, que dan para una partida corta de prototipo.
4. ¿Te vale *The Floor Is Bricks* como nombre? No he encontrado ningún juego que se llame así.
