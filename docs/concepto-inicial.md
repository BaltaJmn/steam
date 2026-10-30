# Concepto de juego: propuesta inicial

> **Estado:** aparcado. Es demasiado grande para un primer juego "súper simple". La dirección actual está en [`ideas-tidy-up.md`](ideas-tidy-up.md).
> **Nombre provisional:** *Pull the Plug* (alternativas: *Bail Out!*, *Low Tide Co.*, *Achicadores*).
> **Referente principal:** Moon Sweepers (DragDrop Games, octubre de 2026).

---

## 1. Elevator pitch

Una empresa interestelar os contrata a ti y a tus amigos para **vaciar el océano de un planeta**. Empiezas con un **cubo de playa**. Acabas con bombas industriales, kilómetros de tuberías y cohetes cisterna despegando cada minuto.

Según baja el nivel del mar va apareciendo lo que había debajo: arrecifes, peces varados, cementerios de barcos, una ciudad hundida... Y en el fondo de la fosa más profunda hay **un tapón gigante**.

**Objetivo final: tirar del tapón.**

| | |
|---|---|
| Género | Incremental · automatización · coop · progreso AFK |
| Jugadores | 1–8 online (pensado para 2–4) |
| Perspectiva | Primera persona, con una "tablet" de vista cenital para planificar |
| Precio objetivo | 7,99–9,99 € |
| Duración hasta el final | 12–18 h, más rejugabilidad con "nuevos océanos" (prestige) |
| Plataforma | Windows (Steam), con Steam Deck como objetivo de rendimiento |

---

## 2. Por qué funciona Moon Sweepers (y qué nos llevamos)

| Ingrediente | En Moon Sweepers | En nuestra idea |
|---|---|---|
| Premisa absurda con un objetivo enorme y clarísimo | Limpiar la Luna entera con un cepillo de dientes | Vaciar un océano con un cubo de playa |
| El progreso se ve en el mundo | El polvo desaparece del mapa | El nivel del mar baja **para todos** y descubre el fondo |
| Bucle manual táctil → mejora → más rápido | Cepillo → escobas → herramientas mejores | Cubo → bidón → mochila de succión... |
| Paso de lo manual a lo automático | Packager, robots aspiradora, cadenas de Moon Sand / Moonstone | Bombas, tuberías, drones, cadenas de producción |
| Coop caótico y barato | Hasta 16 jugadores, ~9 $ | 1–8 jugadores, 8–10 € |
| Equipo pequeño | 2 desarrolladores | Alcance técnico pensado para 1–3 personas |

**Lo que falló según las reseñas y los parches**, y que conviene evitar desde el principio:

- Cuelgues, problemas de rendimiento y bugs de multijugador en el lanzamiento.
- Equilibrado de la progresión y de la automatización, que además se queda corta para quien busca profundidad de juego de fábricas.
- Las mejoras no se compartían entre la tripulación y hubo que arreglarlo con un parche (1.0.3).
- En solitario es muy pesado ("hay que estar loco para hacerlo solo").

La respuesta a cada punto está en la [sección 5](#5-lecciones-aplicadas).

---

## 3. Tres conceptos candidatos

### A. *Pull the Plug*: vaciar un océano (recomendado)
Cubo → bombas → tuberías → cohetes cisterna. El nivel del mar es una barra de progreso gigante y compartida, y cada metro que baja descubre fondo marino nuevo. Al final hay un tapón.

### B. *Deshielo*: descongelar un planeta
La Tierra está congelada y empiezas con un secador de pelo. El hielo se derrite en agua, el agua se calienta en vapor, el vapor mueve turbinas y la electricidad alimenta más calefactores. Debajo del hielo aparecen ciudades congeladas.
- ✅ La cadena termodinámica se retroalimenta sola, lo cual es muy incremental.
- ❌ Derretir hielo obliga a deformar la geometría (vóxeles / marching cubes), y eso es caro de programar y de sincronizar en red.

### C. *Reverdecer*: devolver la vida a un planeta muerto
Empiezas con una regadera. La vegetación se expande sola, y luego llegan aspersores, drones sembradores y compostadoras. Objetivo: planeta 100 % verde.
- ✅ Muy cozy, y el AFK encaja de forma natural.
- ❌ El gancho tiene menos de meme, la propagación de vegetación en red cuesta más y la terraformación ya está muy explorada (Terra Nil, The Planet Crafter).

### Comparativa

| | A. Océano | B. Deshielo | C. Reverdecer |
|---|---|---|---|
| Gancho / meme | ⭐⭐⭐ (cubo contra océano, el tapón) | ⭐⭐⭐ | ⭐⭐ |
| Encaje con la automatización | ⭐⭐⭐ (bombas y tuberías son automatización "de verdad") | ⭐⭐⭐ | ⭐⭐ |
| Encaje con el coop | ⭐⭐⭐ (cadena de cubos) | ⭐⭐ | ⭐⭐ |
| Coste técnico | **Bajo** (el estado del mundo es un número) | Alto | Medio |
| Riesgo de parecer un clon | Medio | Bajo | Medio-alto |

**Recomendación: A.** Es la que mejor reproduce lo que gusta de Moon Sweepers, tiene un final que se vende solo en un tráiler y es la más barata técnicamente para un equipo pequeño (ver [sección 6](#6-alcance-técnico)).

---

## 4. Concepto recomendado: *Pull the Plug*

### 4.1 Premisa y tono

La galaxia sufre una crisis de agua. **Secado Galáctico S.L.** ha comprado los derechos de *Oceánida-9*, un planeta cubierto entero de agua, y os ha contratado para vaciarlo. El presupuesto es ridículo y el equipo inicial, un cubo de playa.

Cada cubo que llega al depósito de la orilla se vende. Cada cierto tiempo despega un cohete cisterna lleno de agua, y ese despegue es vuestro "día de cobro".

**Tono:** humor absurdo y burocrático (mensajes de la empresa, evaluaciones de rendimiento, "empleado del mes"), con un punto de misterio: ¿quién construyó este océano y por qué tiene tapón?

### 4.2 Pilares de diseño

1. **Un número gigante que baja para todos.** El nivel del mar es la barra de progreso, se ve desde cualquier punto del mapa y nunca sube.
2. **Del cubo a la megabomba.** El juego es pasar de hacerlo tú a montar el sistema que lo hace por ti.
3. **Cada metro revela algo.** Bajar el nivel siempre descubre algo: un pez, un cofre, un barco, una zona nueva.
4. **Mejor con amigos, posible en solitario.** Coop en todas las mecánicas, con escalado para quien juega solo.
5. **Nunca se pierde progreso.** Ningún evento deshace lo conseguido, y el juego avanza mientras no estás.

### 4.3 Bucles de juego

| Escala | Qué hace el jugador | Recompensa |
|---|---|---|
| **30 segundos** | Llenar el cubo (mantener clic, sonido de *glug*), cargarlo hasta la orilla y vaciarlo en el depósito | Créditos (número flotante), el nivel baja un pelín |
| **10 minutos** | Comprar una mejora, construir una bomba, alargar una tubería | El nivel baja lo bastante para revelar algo nuevo |
| **Sesión (1–2 h)** | Llegar a una zona nueva, desbloquear una cadena de producción o una fuente de energía | Lanzamiento de un cohete grande, una reliquia, un trozo de historia |
| **Meta** | `Nivel del mar: -347 m / -2.000 m` | Llegar al tapón, y después prestige con "nuevos océanos" |

### 4.4 El mundo: zonas por profundidad

El fondo marino es un terreno fijo diseñado a mano. Lo que cambia es la altura del agua, así que cada zona "aparece" cuando el nivel baja lo suficiente.

| Zona | Profundidad | Tiempo objetivo (2–4 jugadores) | Se desbloquea | Recursos nuevos |
|---|---|---|---|---|
| La Charca (tutorial) | 0 a -1 m | 5 min | Cubo, depósito, primera venta | Agua |
| La Laguna | -1 a -5 m | 45 min | Bomba manual, tuberías, cadena de cubos | Peces varados (colección) |
| El Arrecife | -5 a -30 m | 2 h | Bombas de motor, drones cubo | Algas → biocombustible |
| Cementerio de Barcos | -30 a -120 m | 3 h | Estaciones de rebombeo, primer tesoro | Chatarra → metal |
| La Ciudad Hundida | -120 a -400 m | 4 h | Red eléctrica, energía solar, historia | Arena → vidrio → paneles |
| Llanura Abisal | -400 a -1.500 m | 4 h | Iluminación, megabombas, criaturas gigantes (inofensivas) | Cristales abisales |
| La Fosa | hasta el fondo | 1–2 h | **El Tapón** | — |

### 4.5 Herramientas manuales (gear)

| Nivel | Herramienta | Capacidad aprox. | Notas |
|---|---|---|---|
| 1 | Cubo de playa | 5 L | Con su pala y su rastrillo de plástico |
| 2 | Cubo de fregona | 12 L | |
| 3 | Bidón con ruedas | 50 L | Más lento cuesta arriba |
| 4 | Mochila tanque + manguera de succión | 200 L | Succión continua, se acabó el "llenar" |
| 5 | Hidroaspiradora industrial | 1 m³ | Necesita combustible |
| 6 | Agujero negro de bolsillo | ∞ (con límite de caudal) | Herramienta final, puro power fantasy |

Cada herramienta tiene mejoras de **capacidad**, **velocidad de llenado** y **peso** (cuánto te ralentiza). Equipo personal adicional: botas antibarro, aletas, linterna y botella de oxígeno para bucear en zonas aún sumergidas y sacar tesoros antes de drenarlas.

### 4.6 Automatización

| Nivel | Sistema | Qué resuelve |
|---|---|---|
| 0 | **Cadena de cubos** (coop) | Pasarse el cubo entre jugadores es más rápido que caminar |
| 1 | Bomba manual | Alguien le da a la manivela, o un "becario robot" |
| 2 | Bomba de motor + tuberías | Necesita biocombustible. Primer "ya no cargo cubos" |
| 3 | Drones cubo | Recogen de charcos sueltos y llevan al depósito más cercano (el equivalente a los robots aspiradora) |
| 4 | Estaciones de rebombeo | Superan la altura máxima de cada bomba (ver 4.8) |
| 5 | Bombas eléctricas + red | Paneles solares y generadores |
| 6 | Evaporadores solares | Pasivos y lentos, pero producen sal |
| 7 | Megasifón orbital | Tubería al espacio que sustituye a los cohetes |

**Logística:** el depósito principal está en la orilla original. Según baja el agua puedes montar **puestos avanzados** (depósitos intermedios) más abajo, conectados por tubería.

### 4.7 Recursos y cadenas de producción

```
Agua salada ──► Desalinizadora ──► Agua dulce (se vende más cara) + Sal
Algas       ──► Prensa         ──► Biocombustible ──► Bombas de motor / generadores
Chatarra    ──► Fundición      ──► Metal          ──► Bombas, tuberías, drones
Arena       ──► Horno          ──► Vidrio         ──► Paneles solares
Reliquias   ──► Museo de la empresa ──► Mejoras permanentes (sobreviven al prestige)
Peces       ──► Acuario        ──► Colección, logros y pequeños bonus pasivos
```

La regla es que **la cadena básica (agua → dinero) basta para terminar el juego**. Las cadenas avanzadas aceleran y dan profundidad opcional a quien le gusta optimizar: accesible, pero con techo alto.

### 4.8 La mecánica que lo hace distinto: la altura de bombeo

> **Cuanto más baja el mar, más alto hay que subir el agua.**

Cada bomba tiene una **altura máxima** que puede vencer. Una bomba de nivel 1 sube 10 m, así que al pasar de -10 m necesitas una bomba mejor o una **estación de rebombeo** a mitad de camino. Los cubos también se notan, porque la caminata hasta la orilla es cada vez más larga y más empinada.

Esto da una **curva de dificultad que se justifica dentro del mundo**: el juego se complica porque la física lo pide, no porque el coste de una mejora se multiplique por 1,15. Los muros de progreso se resuelven con ingeniería, no con grindeo.

Contrapeso de diseño: el fondo tiene forma de cuenco, así que **cada metro más abajo tiene menos volumen**. La forma del terreno es la palanca para equilibrar el ritmo.

### 4.9 Coop

- **Mundo, dinero y mejoras de empresa compartidos desde el día 1** (la lección del parche 1.0.3 de Moon Sweepers).
- **Cadena de cubos:** pasarse el cubo de mano en mano es más rápido que caminar, y con 4 o más jugadores en cadena hay bonus y un emote de celebración. Es la mecánica coop más física y graciosa, y da clips buenos para streamers.
- **Roles emergentes sin clases:** buzo (tesoros en zonas sumergidas), fontanero (tuberías), transportista, ingeniero (energía).
- **Entrar y salir en cualquier momento**, sobre la partida del host.
- **Escalado en solitario:** con menos jugadores las herramientas y bombas rinden más (multiplicador oculto), y jugando solo te acompaña un **robot becario** desde el minuto 10.
- **Límite de 8 jugadores.** Cuantos más jugadores, más coste de red y más bugs. Mejor 8 estables que 16 con problemas.

### 4.10 AFK y progreso offline

- **Las bombas siguen funcionando con el juego cerrado.** Al volver se simula el tiempo transcurrido (máximo 12 h) usando el mismo código de la simulación normal en pasos grandes.
- Ese progreso está **limitado por combustible, almacenamiento y capacidad de los cohetes**, así que preparar la noche es parte del juego: "¿tenemos biocombustible para 8 horas?".
- **Modo pecera (opcional, stretch goal):** una ventana pequeña siempre visible con el planeta y el contador bajando, para tenerlo abierto mientras trabajas, al estilo de los idle de escritorio tipo Rusty's Retirement.
- Ninguna mecánica castiga estar fuera: no hay tormentas que rellenen el mar ni cosas que se rompan.

### 4.11 Final y post-juego

- **El Tapón:** evento final cooperativo. Hay que montar las megabombas, despejar la fosa y tirar todos a la vez de una cadena gigante.
- **Propuesta de giro (abierta):** el planeta era la **bañera de un ser cósmico**. Justo cuando quitáis el tapón, una mano gigante aparece con un patito de goma y una toalla... Funciona como remate cómico y como gancho de tráiler.
- **Prestige "Nuevos océanos":** cada planeta tiene un líquido distinto con sus propias reglas, y las reliquias se conservan.
  - **Sopa:** caliente, con fideos como recurso.
  - **Miel:** viscosa, así que las herramientas son lentas y las tuberías se atascan.
  - **Refresco:** con gas, la presión se acumula en las tuberías.
  - **Lava:** necesita equipo térmico.

  Es un **pipeline de contenido barato** para actualizaciones gratuitas (o DLC), porque reutiliza todos los sistemas.

### 4.12 Precio y monetización

- 7,99–9,99 €, con un 10–15 % de descuento de lanzamiento.
- Sin microtransacciones. Como mucho, un *supporter pack* cosmético opcional.
- Actualizaciones gratuitas con océanos nuevos para alargar la vida del juego.
- Localización desde el lanzamiento en ES/EN, y después DE, FR, PT-BR, RU, ZH-CN y JA (Moon Sweepers tuvo mucha tracción en prensa alemana y rusa).

---

## 5. Lecciones aplicadas

| Problema visto en Moon Sweepers | Respuesta en el diseño |
|---|---|
| Cuelgues y rendimiento | Arte low-poly estilizado, agua = un plano por cuenca (sin simulación de fluidos), objetivo Steam Deck |
| Bugs de multijugador | Red desde el **prototipo**, no "más adelante". Host autoritativo y estado mínimo que sincronizar |
| Equilibrado de progresión | Simular la economía (hoja de cálculo o script) **antes** de construir, con tiempos objetivo por zona (4.4) |
| Automatización poco profunda | Cadenas opcionales con techo alto y altura de bombeo como puzle de ingeniería |
| Mejoras no compartidas | Compartidas desde el día 1 |
| Solitario pesado | Escalado por número de jugadores y robot becario |

---

## 6. Alcance técnico

**La gran ventaja de este concepto: el estado principal del mundo es un número por cuenca.**

- **Agua:** cada cuenca es un plano a una altura `h`. A partir del heightmap del fondo se precalcula una tabla `Volumen(h)`. Sacar agua resta volumen y se recalcula `h`. Por red se envía **un `float` por cuenca**, nada más.
- **Fondo marino:** terreno estático hecho a mano. "Revelar" es solo bajar el plano de agua, sin vóxeles ni deformación de terreno.
- **Shader de mojado:** el terreno recién descubierto se ve húmedo y se seca poco a poco. Es barato y muy satisfactorio. Espuma en la línea de costa con depth fade.
- **Tuberías:** colocación por segmentos con *snap* en el MVP (las splines quedan para más adelante).
- **Simulación de automatización:** por *ticks*, determinista y en el host. El mismo código sirve para el progreso offline.
- **Motor:** el que ya conozcáis. Si no conocéis ninguno:
  - **Godot 4 + GodotSteam:** gratis, ligero, buena integración con Steam.
  - **Unity + Steamworks.NET / Facepunch.Steamworks:** más ejemplos y assets de coop.
- **Red:** lobbies y P2P de Steam, con host autoritativo. Sin servidores dedicados, así que coste de servidores cero.
- **Guardado:** partida del host en JSON, con Steam Cloud.

---

## 7. Plan: del prototipo a Steam

| Fase | Contenido | Pregunta que responde |
|---|---|---|
| **0. Prototipo** | Una laguna, cubo, depósito, dinero, 3 mejoras, 1 bomba, nivel bajando, **2 jugadores en red** | ¿Es satisfactorio llenar un cubo y ver bajar el agua? |
| **1. Vertical slice** | Charca + Laguna + Arrecife, cadena de algas, drones, coop a 4, guardado, progreso offline | ¿Engancha la transición de manual a automático? |
| **2. Página de Steam** | En cuanto haya un GIF bueno (el agua bajando y descubriendo un barco) | ¿Interesa? (wishlists) |
| **3. Demo** | Las 2–3 primeras zonas, para un Steam Next Fest | ¿Convierte la demo en wishlists? |
| **4. Lanzamiento 1.0** | Todas las zonas, el Tapón, logros, localización | — |
| **5. Post-lanzamiento** | Nuevos océanos (sopa, miel...) | Larga vida del juego |

Los plazos dependen de cuántos seáis y de vuestra experiencia (ver preguntas abiertas).

---

## 8. Riesgos

1. **Ola de clones de Moon Sweepers.** Es un éxito reciente y saldrán muchos parecidos. Nos diferenciamos con la altura de bombeo, el descubrimiento del fondo, el tapón y los líquidos. Aun así, el juego tiene que sostenerse solo, porque cuando salga la moda puede haber cambiado.
2. **Monotonía al principio.** La primera automatización tiene que llegar en menos de 15 minutos.
3. **Ritmo lento en profundidad.** Hay que poner hitos cada pocos metros, y el fondo en forma de cuenco ayuda.
4. **Netcode.** Se mitiga con red desde el prototipo y un estado mínimo.
5. **Scope creep.** La lista del MVP tiene que ser estricta. Los líquidos alternativos y el modo pecera son post-lanzamiento.

---

## 9. Preguntas abiertas

1. **Equipo:** ¿cuántos sois, qué experiencia tenéis y con qué motor?
2. **Perspectiva:** ¿primera persona (táctil, caótica, buena para streamers) o tercera persona / isométrica (mejor para planear la automatización y arte más barato)? *Recomendación: primera persona con una tablet de vista cenital para construir.*
3. **Profundidad de la automatización:** ¿ligera como Moon Sweepers o un "Satisfactory-lite"? *Recomendación: accesible, con optimización opcional.*
4. **Tono:** ¿absurdo y cómico, o más cozy y contemplativo?
5. **Nombre:** hay que comprobar disponibilidad en Steam y marcas.

---

## Referencias

- [Moon Sweepers: guía de multijugador (co-op, crossplay)](https://gamerblurb.com/guides/moon-sweepers-multiplayer-guide-co-op-crossplay-playing-with-friends)
- [Moon Sweepers: walkthrough de herramientas, Packager y automatización](https://www.keengamer.com/articles/guides/moon-sweepers-complete-walkthrough-tools-packager-automation/)
- [Notas del parche: mejoras compartidas de la tripulación](https://jeu.video/en/article/moon-sweepers-patch-notes-shared-crew-upgrades)
- [Is Moon Sweepers worth it?](https://games.gg/news/is-moon-sweepers-worth-it-for/)
- [Dos desarrolladores hicieron Moon Sweepers y superó a juegos AAA en Steam](https://ixbt.games/en/news/2026/10/28/dva-razrabotcika-sdelali-igru-pro-uborku-luny-moon-sweepers-ona-obosla-aaa-xity-v-steam.amp.html)
- [Mein-MMO: 50.000 jugadores limpiando la Luna con un cepillo de dientes](https://mein-mmo.de/steam-moon-sweepers-hit/)
