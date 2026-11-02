# The Floor Is Bricks (nombre provisional)

> **Estado:** propuesta para validar. Sustituye a *Couch Crew* como dirección (el prototipo de `/game` se reaprovecha casi entero).
> **Lema:** *"Todo el mundo sabe lo que pasa cuando pisas una."*

---

## 1. La idea

El suelo del cuarto de un niño está **cubierto de piezas de construcción** de seis cajas distintas, todas mezcladas. Hay que **recogerlas, clasificarlas y montar los 6 sets**. Cada set terminado **cobra vida y se pone a trabajar contigo**: el volquete acarrea piezas, la clasificadora clasifica sola, el tren recorre el cuarto...

### Premisa (la gracia)

Son las 23:00. Mateo, de 8 años, ha volcado sus seis cajas de bloques en el suelo y se ha dormido. **A las 7:00 papá entrará descalzo a despertarle.** Sois las figuritas de esos sets: si papá pisa una pieza, el grito se oirá en todo el barrio. Tenéis una noche para recoger el suelo y montar vuestros sets... **sin despertar a nadie.**

---

## 2. Ojo: el género ya tiene juegos muy parecidos

| Juego | Qué es | Estado |
|---|---|---|
| [*Brick by Brick: Tidy Up the Small Town!*](https://store.steampowered.com/app/5228920/Brick_by_Brick_Tidy_Up_the_Small_Town/) | Clasificar 18.490 ladrillos por forma y color y colocarlos según planos para reconstruir un pueblo. Coop de 5 | Salió el 15 oct 2026 (7,99 $) |
| [*Tidy Up: Bricks n Blocks*](https://store.steampowered.com/app/5516980) | Piezas tiradas por el suelo de habitaciones: se clasifican en estanterías por forma y en cubos por color. Fichas para comprar mejoras. 13 habitaciones. Un jugador | Sale el 17 nov 2026 |
| [*Toy Keeper*](https://store.steampowered.com/app/4867330) | Ordenar juguetes en una juguetería | Acceso anticipado |

**"Recoger piezas del suelo y construir con ellas" por sí solo sería un clon.** Lo que propongo para que no lo sea:

| | Ellos | Nosotros |
|---|---|---|
| Qué construyes | Edificios o estanterías que se quedan quietos | **Sets que funcionan**: cada uno automatiza una parte del trabajo (incremental de verdad) |
| Clasificar | A mano, pieza a pieza | Las piezas pequeñas **a granel con máquinas** (números que suben). Las piezas especiales, a mano |
| Tensión | Ninguna (cozy puro) | **Ruido**: si os pasáis, papá entra descalzo y su pie gigante va a por el más ruidoso |
| Escala | Tamaño persona | **Sois figuritas**: el cuarto es enorme, la cama es una montaña y una pieza grande se carga entre dos |
| Tono | Relajado | Comedia nocturna |

---

## 3. Cómo funciona

### 3.1 El bucle

```
Suelo lleno de piezas ──[recoger]──► saco de piezas mezcladas
   ──► tolva de la clasificadora ──[manivela]──► cubetas por COLOR
   ──[llevar]──► obra del set activo ──► el set se monta solo, pieza a pieza
Piezas especiales (ruedas, ventanas, banderas, timón...) ──[buscar por la forma]──► su hueco en el set
Set terminado ──► cobra vida y automatiza algo ──► siguiente set (más grande)
```

- **Piezas pequeñas a granel:** el suelo está cubierto de miles de piezas pequeñas de todos los colores. Las recoges en el saco y la máquina las separa **por color**. Es la parte incremental: los números suben, las máquinas aceleran.
- **Piezas especiales a mano:** ruedas, ventanas, timones, banderas, la cabina del cohete... Son únicas y tienen **su silueta** en el set, como los objetos del prototipo. Es la parte de "buscar y encajar" del género. Las más grandes **se cargan entre dos**.
- **Construir es visible:** cada set tiene su zona con el libro de instrucciones abierto. Al entregar piezas del color que pide, **el set va apareciendo pieza a pieza, capa a capa**. Es lo más satisfactorio de ver y lo más "streameable".

### 3.2 Los 6 sets (de pequeño a grande)

| # | Set | Colores | Al terminarlo... |
|---|---|---|---|
| 1 | 🚚 **Volquete** | amarillo, negro | Acarrea solo las piezas de las cubetas a la obra activa (adiós a los viajes) |
| 2 | ⚙️ **Clasificadora motorizada** | gris, rojo | La clasificadora ya no necesita manivela |
| 3 | 🚂 **Tren de mercancías** | azul, rojo, negro | Pone vías alrededor del cuarto: recoge piezas de los montones lejanos y las trae a la tolva |
| 4 | 🏗️ **Grúa** | amarillo, gris | Hace falta para las capas altas de los sets grandes. Además coloca las piezas especiales grandes |
| 5 | 🏴‍☠️ **Barco pirata** | marrón, negro, blanco | Su cañón **dispara piezas** clasificadas a la otra punta del cuarto (automatización absurda) |
| 6 | 🚀 **Cohete** | blanco, azul, rojo | Necesita piezas de todo. Es el final |

Cada set necesita entre ~300 y ~1.500 piezas pequeñas más 4–10 especiales. En total, unas **5.000 piezas pequeñas y ~40 especiales**.

### 3.3 Mejoras

- **Moneda: pegatinas.** Salen al clasificar piezas y al terminar sets.
- **Se compran en la caja de herramientas de Mateo:**
  - saco más grande: calcetín → mochila → caja de zapatos;
  - recogida más rápida;
  - zapatillas silenciosas;
  - más figuritas ayudantes.
- **Los sets terminados** son la automatización grande, y no se compran: se construyen.

### 3.4 Papá descalzo (el ruido)

Es la misma mecánica que ya funciona en el prototipo, cambiando la mano por el pie:
- **Barra de ruido compartida:** correr, saltar, tirar piezas y vaciar sacos llenan la barra.
- **Mucho ruido:** Mateo se revuelve en la cama y la luz del pasillo parpadea bajo la puerta.
- **Ruido al máximo:** la puerta se abre, **papá entra descalzo y su pie gigante va a por el más ruidoso**. Corriendo se esquiva. Si te pisa, sales volando.
- **El chiste:** si su pie cae sobre un montón de piezas que aún no habéis recogido... **"¡¡AAAAY!!"**. Papá sale a la pata coja y el juego te da un logro.

### 3.5 Coop (1–4)

- **Roles naturales:** recoger, operar la clasificadora, construir y buscar piezas especiales.
- **Piezas especiales grandes para dos:** la cabina del cohete, el timón del barco.
- **Comedia:** "trolear" a un compañero haciendo ruido para que papá le pise, y montar en el tren (idea para más adelante).
- **Todo compartido:** progreso, pegatinas y mejoras.

### 3.6 Final

Despega el cohete, Mateo se despierta y ve los seis sets montados en el suelo impecable. Papá entra descalzo, cruza el cuarto tan tranquilo... y pisa **la única pieza que se os había escapado**. *"¡¡AAAAY!!"* Créditos.

---

## 4. Personajes: figuritas propias (cuidado con la marca)

- No usar el nombre **LEGO** ni su logo en nada: el juego habla de "piezas" o "bloques de construcción".
- **La forma de la minifigura de LEGO está registrada como marca** (el Tribunal General de la UE lo confirmó en 2015). Nuestras figuritas tienen que tener **diseño propio**: por ejemplo, muñecos de madera tipo *peg doll* o figuras rechonchas con cabeza de bloque. Cada jugador es la figurita de uno de los sets: conductor, mecánica, maquinista, gruista, pirata y astronauta.
- Las piezas con "pivotes" (studs) son genéricas (las patentes caducaron hace décadas), pero conviene darles un toque propio (proporciones, pivotes con forma de estrella...).

---

## 5. Por qué este tema arregla el "arte cutre"

En los temas anteriores todo eran formas sueltas generadas por código y se notaba. Aquí **el mundo entero está hecho de piezas**, y eso sí se puede generar bien por código:

- **Una pieza** = un bloque con pivotes, generado por código y con plástico brillante. Queda bien sin artista.
- **Miles de piezas por el suelo** se dibujan de golpe con `MultiMesh`. Según recoges, desaparecen de verdad del suelo.
- **Los sets** se definen como "maquetas" de piezas (datos) y se montan solos pieza a pieza. Arte gratis y muy satisfactorio de ver.
- Solo hacen falta modelos para: las figuritas, la cama, los muebles del borde del cuarto y el pie de papá.

---

## 6. Qué se reaprovecha del prototipo actual

| Ya hecho | En este juego |
|---|---|
| Red coop, estado compartido, guardado de partida | Igual |
| Montaña → tolva → manivela → cubetas | Piezas mezcladas → clasificadora por color |
| Cuencos que se llenan | Obras de los sets que se montan pieza a pieza |
| Objetos y huecos con silueta | Piezas especiales y su sitio en el set |
| Mejoras compartidas, hormigas ayudantes | Pegatinas, figuritas ayudantes |
| Ruido y mano de papá que se esquiva | Ruido y pie de papá |
| Interfaz y menú | Igual |

**Trabajo nuevo:** el generador de piezas, el suelo con miles de piezas (MultiMesh), el montaje de sets a partir de datos, los 6 sets con su función y el pie de papá.

**Orden propuesto:**
1. Suelo de piezas y clasificación por color.
2. Montaje de sets con los 2 primeros (volquete y clasificadora motorizada).
3. El pie de papá.
4. El resto de sets.

---

## 7. Decisiones abiertas

1. **Escala:** ¿figuritas en un cuarto gigante (recomendado) o tamaño persona, como Brick by Brick?
2. **Ruido y papá descalzo:** ¿se mantiene?
3. **Los 6 sets:** ¿te valen estos o prefieres otros (casa, granja, castillo...)?
4. **Nombre:** *The Floor Is Bricks* (no he encontrado ningún juego con ese nombre).
