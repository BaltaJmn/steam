# Ideas "Tidy Up": juegos súper simples, con coop y casi sin coste

> **Estado:** dirección elegida (el dragón). Las decisiones tomadas están en la [sección 0](#0-decisiones-tomadas) y el prototipo jugable en [`/game`](../game/README.md). Sustituye en alcance a [`concepto-inicial.md`](concepto-inicial.md), que se queda aparcado.
> **Objetivo:** un juego muy simple, con un coop divertido y un coste de desarrollo mínimo.

---

## 0. Decisiones tomadas

| Tema | Decisión | Por qué |
|---|---|---|
| Idea | **El tesoro del dragón** (sección 4) | Elegida por el autor |
| Equipo | 1 persona | — |
| Motor | **Godot 4.7** (Forward+) | Ver abajo |
| Progreso offline | **No.** El juego no avanza con el juego cerrado | Los ayudantes son gente contratada que trabaja contigo mientras juegas y acelera el ritmo |
| Nombre (provisional) | ***Kobold Keepers***, sin la coletilla *"Tidy Up the …!"* | Ver [sección 0.2](#02-nombre-y-competencia-directa) |

### 0.1 Por qué Godot y no Unity

Has tocado los dos, así que la decisión depende de qué es más cómodo para **una persona sola** y de que se vea bien.

- **Más cómodo.** Es gratis y sin royalties, se abre en segundos y la iteración es inmediata. GDScript es lo más sencillo de aprender de los dos. Trae el multijugador de serie: la API `multiplayer` y `@rpc`, y para Steam se cambia el *peer* por el de **GodotSteam** sin tocar el resto.
- **Escenas y scripts en texto.** Así puedo escribir y revisar contigo casi cualquier parte del proyecto (escenas incluidas), cosa que con Unity es mucho más difícil.
- **Se ve bien.** Para una cueva cerrada con oro, el renderer Forward+ tiene todo lo necesario: bloom, niebla volumétrica para los haces de luz, SSAO y metales PBR.
- **Lo que gana Unity.** Más tutoriales y assets de coop (muchos coop indie recientes se han hecho en Unity) y una tienda de assets más grande. Para un juego de una sola cueva con pocos modelos no compensa.

### 0.2 Nombre y competencia directa

**Ojo: ya existe *Folded Fables: Tidy Up The Dragon Hoard*** (Codename Entertainment). Salió el 15 de octubre de 2026, cuesta 5,99 $ y tiene coop. Es un juego de ordenar ~5.648 tesoros para un dragón, con estética de papel, habilidades (resaltar, invocar, teletransportar a la estantería) y huevos ocultos. En KeenGamer tiene un 9/10 y dura unas 9 h. Es **la misma premisa**, y además el género se está llenando muy rápido (*Megastore: Tidy Up Together*, *Bunker Tidy Up*, *Deep Sea Sweep*...).

Consecuencias:

1. **El tema por sí solo ya no nos diferencia.** Lo que nos distingue es **la mezcla**, que Folded Fables no tiene:

   | | Folded Fables | Kobold Keepers |
   |---|---|---|
   | Núcleo | Ordenar objetos en estantes | Ordenar objetos **+ montaña de monedas incremental** |
   | Progresión | Habilidades con cooldown | Mejoras de herramientas **+ máquinas + kobolds contratados** |
   | Coop | Ordenar juntos | Roles (palear, manivela, colocar), objetos para dos y **ruido compartido**: si el grupo se pasa, el dragón resopla y sale volando el más ruidoso |
   | Tono | Cuento de papel, cozy | Comedia de kobolds y sigilo |

2. **Nombre: *Kobold Keepers*, sin "Tidy Up the Dragon's Hoard!".** Con dragón, esa coletilla se leería como copia de Folded Fables. El descubrimiento en Steam lo dan las etiquetas (*Cozy*, *Organizing*, *Co-op*, *Incremental*, *Automation*) y la descripción ("un juego de ordenar..."). Lema: *"Ordena el tesoro. No despiertes al dragón."* No he encontrado ningún juego en Steam con ese nombre, pero hay que confirmarlo (y comprobar marcas) antes de crear la página.

3. **Plan B si se quiere esquivar del todo la comparación:** las mismas mecánicas con otra ambientación, porque el prototipo es independiente del tema (el nombre del "durmiente" está en `Balance.SLEEPER_NAME`). La mejor alternativa que veo es **un kraken dormido en un barco hundido con una tripulación de cangrejos**: bajo el agua, la niebla abarata el escenario y queda muy bonito.

---

## 1. La fórmula que comparten los referentes

| | Librarian: Tidy Up the Arcane Library! | Brick by Brick: Tidy Up the Small Town! | Moon Sweepers |
|---|---|---|---|
| Estudio | ArtRising | PaperPixel Games | DragDrop Games (2 personas) |
| Lanzamiento | 30 abr 2026 | 15 oct 2026 | 23 oct 2026 |
| Precio | 5,99 $ | 7,99 $ | 8,99 $ |
| Jugadores | Solo | 1–5 coop | 1–16 coop |
| Un solo escenario | Una biblioteca | Un pueblo pequeño | La Luna |
| Número gigante y cerrado | **3.072 libros** | **18.490 ladrillos** | Toda la superficie |
| Verbo principal | Coger, clasificar y colocar libros | Coger, clasificar y colocar ladrillos según planos | Barrer y recoger polvo |
| Cómo se clasifica | 31 categorías por título y portada, y series en orden | Forma y color | — |
| Mejoras | Hechizos: Insight (resaltar), Assemble (atraer serie), Auto-Shelving (colocar solo); de 10 a 15 libros en brazos | Imán, carretilla, andamios | Herramientas, Upgrade Matrix, robots |
| Progreso visible | Las estanterías se llenan | Los muros suben | El polvo desaparece |
| Reseñas | 93 % de ~16.700 | 87 % de ~680 | 77 % de ~1.900 |

**Lo que tienen en común:**

1. **Un único escenario cerrado.** No hay mundo abierto ni niveles.
2. **Un número enorme y exacto** que se va completando (está en la descripción de la tienda y forma parte del marketing).
3. **Un solo verbo** (coger → clasificar → colocar), sin combate, sin poder perder y sin prisas.
4. **Mejoras que aceleran ese verbo**, y al final algo de automatización ligera.
5. **Progreso visible**: el caos se convierte en orden delante de tus ojos.
6. **Arte barato**: unos pocos modelos con muchas variaciones de color o textura (un libro, un ladrillo...).
7. **Precio de impulso** (6–9 $) y tono cozy.
8. **Los juegos del género se apoyan entre sí:** Brick by Brick se vende en *bundle* con Moon Sweepers y con Deep Blue Sushi. Al lanzar, conviene buscar bundles con juegos parecidos.

---

## 2. Reglas para que el desarrollo cueste casi nada

1. **Un mapa interior.** Una sala grande con 2 o 3 salas anexas. Nada de terreno exterior, LODs ni ciclo día/noche.
2. **Pocos modelos y muchas variaciones.** Cada objeto es un modelo base al que se le cambia color, material o patrón por shader. Con 12 modelos se pueden sacar cientos de objetos distintos.
3. **Assets gratis o baratos.** Packs CC0 (Kenney, Quaternius, Poly Pizza) o packs low-poly de pago en oferta. Para los avatares coop, personajes estilizados con animaciones de Mixamo.
4. **Datos, no física.** Cada objeto es un registro (`id`, `categoría`, `estado`). Por red se envían cambios de estado, no simulaciones físicas. Solo tiene física el objeto que llevas en la mano. Al colocarlo **encaja en un hueco**, así que no hay que pelearse con la física.
5. **Huecos con silueta fantasma** (como los planos de Brick by Brick). El objetivo queda claro sin tutorial y colocar es trivial.
6. **Casi sin texto.** Una carta de introducción, nombres de categorías y una interfaz mínima. Así traducir a 20 o 30 idiomas sale casi gratis.
7. **Sin NPCs complejos ni historia.** Como mucho, una carta al principio y una escena final corta.
8. **Coop pequeño y estable.** De 1 a 4 jugadores por P2P de Steam con host autoritativo, sin servidores.

---

## 3. Ideas candidatas

| # | Idea | En una frase | Gancho | Coop | Coste | Riesgo |
|---|---|---|---|---|---|---|
| 1 | **Coin by Coin: Tidy Up the Dragon's Hoard!** ⭐ | Sois kobolds ordenando la montaña de oro de un dragón dormido | ⭐⭐⭐ | ⭐⭐⭐ | Muy bajo | Bajo |
| 2 | **Pair by Pair: Tidy Up the Lost Sock Dimension!** | La dimensión a la que van los calcetines perdidos: lavar, emparejar y guardar 12.000 | ⭐⭐⭐ | ⭐⭐⭐ | **Mínimo** | Escenario menos vistoso |
| 3 | Star by Star: Tidy Up the Night Sky! | Las estrellas se han caído: clasificarlas y lanzarlas a sus constelaciones | ⭐⭐ | ⭐⭐ | Bajo (la noche oculta detalle) | Apuntar complica las cosas |
| 4 | Bone by Bone: Rebuild the Museum! | Un terremoto ha desmontado los dinosaurios del museo | ⭐⭐ | ⭐⭐⭐ (huesos para dos) | Medio (esqueletos) | Más arte |
| 5 | Ball by Ball: Tidy Up the Ball Pit! | 50.000 bolas por toda la zona infantil: llenar tubos que forman murales | ⭐⭐ | ⭐⭐⭐ (caos) | Mínimo | Miles de esferas pesan; clasificar solo por color es poco |
| 6 | Return to Sender: Tidy Up the Post Office! | Cartas y paquetes perdidos, tubos neumáticos | ⭐ | ⭐⭐ | Bajo | **Demasiado parecido a Librarian** |

**Recomendada: la 1. Alternativa clara: la 2.**

---

## 4. Elegida: *Kobold Keepers* (antes *Coin by Coin: Tidy Up the Dragon's Hoard!*)

### 4.1 Pitch

> Un dragón se ha echado a dormir sobre su tesoro, que es un desastre: montañas de monedas mezcladas, coronas tiradas, gemas por todas partes. Tú y tus amigos sois kobolds de la limpieza, contratados para dejarlo todo perfecto **antes de que despierte**. Y sin hacer ruido.

**1.000.000 de monedas · 4.096 tesoros · 20 objetos perdidos.**

- **Por qué funciona:** la miniatura con una montaña de oro brillando en una cueva vende sola, y el oro queda espectacular con muy poco esfuerzo (material metálico + bloom).
- **Por qué es barata:** una cueva, monedas, gemas, unos 12 modelos de tesoro y un dragón que solo respira.
- **Por qué encaja con lo que te gusta:** las monedas son literalmente el contador incremental, hay automatización ligera y puedes contratar kobolds que trabajan contigo para avanzar más rápido.

### 4.2 Dos bucles: uno incremental y otro de ordenar

**Bucle de monedas (incremental y automatizable):**
```
Montaña de monedas ──pala──► Saco (mezcla)
     ──► Clasificadora con manivela ──► Bolsas de cobre / plata / oro
     ──► Torres de monedas en la cámara acorazada  (contador: 412.380 / 1.000.000)
```

**Bucle de tesoros (el "Librarian" del juego):**
```
Tesoro tirado ──coger──► En brazos (3, luego 5)
     ──► Su hueco con silueta fantasma en vitrinas, armeros y expositores
```

Las monedas dan la sensación de *número que sube* y se pueden automatizar. Los tesoros dan el placer de ordenar y encajar cada pieza en su sitio.

### 4.3 Qué se ordena

| Tipo | Cantidad | Variedad (barata) | Destino |
|---|---|---|---|
| Monedas | 1.000.000 (a granel) | Cobre, plata y oro, más 3 reinos más adelante. Es una textura | Torres de monedas instanciadas en la cámara acorazada |
| Gemas | ~1.000 | 6 colores × 2 tallas | Cofres y vitrinas por color |
| Tesoros | ~3.000 | 12 modelos (corona, cáliz, espada, escudo, yelmo, collar, cetro, candelabro, jarrón, anillo, armadura, cuadro) × material (oro/plata/bronce) × decoración | Huecos con silueta en expositores |
| Objetos perdidos del dragón | 20 | Únicos (diario, foto, peluche...) | Coleccionables escondidos, como las llaves de Librarian |

> Las monedas **no** son 1.000.000 de objetos físicos. Cada montaña es un modelo que encoge según lo que queda, y las torres usan *instancing*. En pantalla solo hay unos cientos de monedas decorativas.

### 4.4 Mejoras

La moneda de compra es **la paga del dragón**: 1 moneda por cada 100 ordenadas.

| Mejora | Efecto |
|---|---|
| Pala grande → pala de dragón | Más monedas por palada |
| Saco → carretilla → vagoneta | Más capacidad |
| Brazos de kobold | Más tesoros a la vez (de 3 a 5 a 8) |
| Botas de silencio | Haces menos ruido (ver 4.6) |
| **Ojo de urraca** (habilidad) | Resalta todos los tesoros de una categoría durante unos segundos |
| **Silbido de gema** (habilidad) | Las gemas de un color cercanas saltan a tus manos |
| Clasificadora: manivela → rueda de hámster → engranajes | Clasifica más rápido |
| Raíles de vagoneta | Las bolsas van solas a la cámara acorazada |
| **Kobolds ayudantes** | Palean y le dan a la manivela por ti (automatización y AFK) |

### 4.5 Automatización y ayudantes (ligeros)

- La **clasificadora** es la única "fábrica": entra mezcla y salen bolsas separadas.
- **Mejoras de automatización:** la *rueda de hámster* hace girar la clasificadora sola y el *tobogán* lleva las cubetas a las torres.
- Los **kobolds contratados** son gente que trabaja contigo: palean de la montaña a la tolva mientras haces otras cosas. Son una máquina de estados muy simple (ir a la montaña, ir a la tolva) y la lleva el host.
- **Sin progreso offline:** con el juego cerrado no avanza nada. Si lo dejas abierto, los kobolds siguen trabajando porque están en la partida, igual que las máquinas.
- Los tesoros siempre se colocan a mano, porque ese es el placer del género.

### 4.6 Coop (1–4 jugadores)

1. **Roles naturales:** uno palea, otro le da a la manivela y otro coloca tesoros. Sale solo, sin clases.
2. **Objetos para dos:** los cofres grandes y la corona gigante del dragón se cargan entre dos kobolds.
3. **Medidor de ruido compartido:** correr, tirar cosas o chocar hace ruido. Si el grupo se pasa, el dragón resopla en sueños y **sale volando el kobold más ruidoso** (sin perder nada). Es caos gratis, da clips para streamers y permite "trolear" a los amigos.
4. **Lanzar** sacos o tesoros a un compañero.
5. **Marcar objetos** ("¡aquí hay un cáliz de plata!").
6. **Entrar y salir en cualquier momento**, con todo compartido: dinero, mejoras y progreso.

### 4.7 Final

Al llegar al 100 % el dragón se despierta, mira su tesoro perfectamente ordenado... y busca algo. El último objeto perdido, escondido en el fondo de la montaña, es **su peluche de la infancia**. Lo abraza, se vuelve a dormir y salen los créditos.

### 4.8 Alcance total

| Cosa | Cantidad |
|---|---|
| Mapas | 1 cueva + 3 cámaras (cámara acorazada, sala de exposición, nido) |
| Modelos de tesoro | ~12, más gemas y monedas |
| Personajes | 1 kobold (con colores y gorros para distinguir jugadores) + 1 dragón que solo respira y resopla |
| Máquinas | Clasificadora (3 niveles), vagoneta y raíles |
| Mejoras | ~15 |
| Texto | Carta inicial, nombres de categorías e interfaz |
| Música | 2–3 pistas tranquilas + efectos de sonido (monedas, ronquidos, resoplidos) |

**Duración objetivo:** 6–10 h en solitario y 3–5 h con 4 jugadores. **Precio:** 5,99–7,99 €.
**Contenido futuro barato:** otros dragones (de hielo, con tesoro congelado; de pantano...), reutilizando los mismos sistemas, como actualización gratuita o DLC.

---

## 5. Alternativa: *Pair by Pair: Tidy Up the Lost Sock Dimension!*

> ¿A dónde van los calcetines perdidos? Aquí. Una lavandería en el más allá con **12.000 calcetines desparejados**.

- **Bucle:** recoger calcetines sucios → lavadora → secadora → emparejar (200 diseños × 60 calcetines, y valen dos cualesquiera del mismo diseño) → doblar → cajoneras. Al llenarlas, los colores de los cajones forman **murales en píxel art**.
- **Coop:** buscar parejas obliga a hablar ("¿alguien tiene uno de rayas verdes?"), puedes lanzar calcetines y cada máquina es un puesto.
- **Automatización:** lavadoras con temporizador (encaja con el AFK), cintas transportadoras y un robot emparejador.
- **Coste:** **el más bajo de todos**, porque un calcetín es un único modelo con patrones generados por shader.
- **Contras:** el escenario es menos espectacular que una cueva de oro y es menos power fantasy.

---

## 6. Plan

| Fase | Contenido | Pregunta que responde |
|---|---|---|
| **0. Prototipo** ✅ montado en [`/game`](../game/README.md) | Cueva en *greybox*, montaña, pala, clasificadora con manivela, 3 torres, 12 tesoros con hueco, 7 mejoras, kobolds contratados, medidor de ruido y **coop de hasta 4 jugadores en red** | ¿Es satisfactorio palear, darle a la manivela y colocar? ¿Hace gracia el coop? |
| **1. Vertical slice** | Arte final de una sala, mejoras, medidor de ruido, guardado | ¿Engancha durante una hora? |
| **2. Página de Steam** | En cuanto haya un GIF bueno (la montaña de oro convirtiéndose en torres ordenadas) | ¿Hay wishlists? |
| **3. Demo + Steam Next Fest** | La primera sala completa | ¿La demo convierte? |
| **4. Lanzamiento** | Todo, logros, traducciones | — |
| **5. Post-lanzamiento** | Nuevos dragones y *bundles* con juegos del género | Larga vida del juego |

### Stack técnico

- **Motor:** **Godot 4.7** (decidido, ver 0.1), con **GodotSteam** para Steam más adelante.
- **Red:** en el prototipo se usa ENet por IP para probar en local. En el juego final, lobbies y P2P de Steam. En los dos casos el host es autoritativo y se sincronizan **cambios de estado** (no física).
- **Guardado:** lista de estados de objetos + contadores, en JSON con Steam Cloud.

---

## 7. Presupuesto orientativo (dinero, no tiempo)

| Concepto | Coste aproximado |
|---|---|
| Alta de la app en Steam (Steam Direct) | 100 $ (se recupera cuando el juego factura 1.000 $) |
| Motor | 0 € (Godot / Unity Personal) |
| Modelos 3D | 0–150 € (CC0 o packs low-poly en oferta) |
| Música y efectos de sonido | 0–200 € (librerías libres de derechos o packs) |
| **Cápsula de Steam e imagen principal** | 200–800 € (encargo a un ilustrador) |
| Traducción | ~0 € (poco texto: traducción automática + revisión de la comunidad) |
| **Total** | **~300–1.300 €** |

Las cifras son estimaciones. **El gasto que más merece la pena es la cápsula**: en Steam es lo que decide si alguien hace clic. El coste real del proyecto es vuestro tiempo.

---

## 8. ¿Y la idea del océano?

[*Pull the Plug*](concepto-inicial.md) sigue siendo buena, pero es un proyecto **más grande** (7 zonas, cadenas de producción, prestige). No encaja con lo de "súper simple y coste ínfimo". Propuesta: dejarla como **segundo juego**, cuando ya tengáis la base técnica (coop, guardado, Steam) del primero.

---

## 9. Preguntas abiertas

Resueltas: dragón, Godot, nombre provisional y sin progreso offline (sección 0).

1. **¿Dragón pese a Folded Fables, o las mismas mecánicas con otro tema** (p. ej. kraken y cangrejos)? Ver 0.2.
2. **Jugadores:** el prototipo admite 4. ¿Subir a 5 como Brick by Brick?
3. **Tras probar el prototipo:** ¿qué parte es divertida y cuál sobra?

---

## Referencias

- [Librarian: Tidy Up the Arcane Library! en Steam](https://store.steampowered.com/app/4197610/Librarian_Tidy_Up_the_Arcane_Library)
- [Análisis de Librarian (KeenGamer)](https://www.keengamer.com/articles/reviews/pc-reviews/librarian-tidy-up-the-arcane-library-review-simply-spellbinding/)
- [Brick by Brick: Tidy Up the Small Town! en Steam](https://store.steampowered.com/app/5228920/Brick_by_Brick_Tidy_Up_the_Small_Town/)
- [Brick by Brick llega a 40.000 wishlists en 3 días (Inven Global)](https://www.invenglobal.com/articles/27061/brick-by-brick-reaches-40000-wishlists-in-3-days)
- [Brick by Brick sale en Steam el 15 de octubre (Inven Global)](https://www.invenglobal.com/articles/27186/brick-by-brick-set-to-launch-on-steam-on-october-15)
- [Análisis de Folded Fables: Tidy Up the Dragon Hoard (KeenGamer)](https://www.keengamer.com/articles/reviews/pc-reviews/folded-fables-tidy-up-the-dragon-hoard-review-doesnt-fall-flat/)
- [Bundle Shelve the Potions! × Folded Fables (Deku Deals)](https://www.dekudeals.com/items/shelve-the-potions-x-folded-fables-tidy-up-the-dragon-hoard-bundle)
- Referencias de Moon Sweepers en [`concepto-inicial.md`](concepto-inicial.md#referencias)
