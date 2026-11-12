# FalOS

Un sistema operativo escrito desde cero en [Fal](https://github.com/NissanBoss/Fal),
un lenguaje de programación en español. Se construye en público, un día cada
vez: cada día, un paso que se pueda ver, subido aquí y contado en
[TikTok](https://www.tiktok.com/@fal.lang).

![El registro de FalOS: qué programa ha leído o guardado qué, cuándo, y qué decidiste tú](capturas/dia-11.png)

## Por qué

Casi todo el código que corre debajo de tus programas está escrito en C, y C
deja leer y escribir la memoria fuera de donde toca. De ahí sale la mayoría de
los agujeros graves: Microsoft calcula que [cerca del 70 %](https://msrc.microsoft.com/blog/2019/07/a-proactive-approach-to-more-secure-code/)
de las vulnerabilidades que corrige son de este tipo, y Chromium da [la misma
cifra](https://www.chromium.org/Home/chromium-security/memory-safety/) para las
suyas.

Y entender cómo funciona un sistema operativo por dentro pasa casi siempre por
leer C y leer inglés. FalOS intenta las dos cosas a la vez: un sistema escrito
en un idioma que entiendes, en un lenguaje donde salirse de la memoria no es
un descuido posible, sino un error que para el sistema y dice en qué línea.

## Cómo

Hace falta el `fal` de la rama `main`, que es el que sabe compilar para
arrancar sin sistema debajo ([cómo funciona](https://github.com/NissanBoss/Fal/blob/main/NUCLEO.md)),
y [QEMU](https://www.qemu.org) para tener un ordenador virtual:

```bash
git clone https://github.com/NissanBoss/Fal
cd Fal && go build -o fal .
```

```bash
fal haz_disco.fal
```

```bash
fal --arranca sistema.fal
```

`haz_disco.fal` compila lo que hay en [programas/](programas), lo junta con los
textos de [disco/](disco) y hace un `disco.img`, y `fal --arranca` lo conecta
solo.

El núcleo está en [sistema.fal](sistema.fal), y los tres programas que necesita
para ver, oír y leer, en [controladores/](controladores). Lo que se va añadiendo
cada día está en el [diario](DIARIO.md).

Hoy FalOS arranca, pasa al modo de 64 bits, escribe en la pantalla con
colores y tildes, lee el teclado español con AltGr y entiende unas pocas
órdenes: `ayuda`, `limpia`, `hora`, `colores`, `encendido`, `memoria`,
`programas`, `lanza`, `tareas`, `para`, `teclado`, `permisos`, `permite`, `prohibe`,
`disco`, `lee`, `deja`, `niega`, `olvida`, `registro`, `cuelga`, `rompe` y
`reinicia`. Lo que escribes se corrige
con las flechas, y las de arriba y abajo traen las órdenes de antes.

Sabe cuánta memoria tiene y la reparte en páginas de 4 KB, que entrega
siempre borradas, y que borra otra vez cuando un programa las devuelve. Monta sus propias tablas de páginas: su código es de solo
lectura, los datos no se pueden ejecutar y la dirección 0 no existe, y eso
lo hace cumplir el procesador.

El reloj y el teclado avisan por interrupciones, así que mientras espera, el
procesador duerme.

Y corre programas, varios a la vez, cada uno con 10 ms de procesador por turno.
Salen del disco, y FalOS no se cree lo que dicen: mira su cabecera antes de hacer
una sola cuenta con ella, y si miente, no los carga. Van en el anillo 3, sin permisos, cada uno con sus propias tablas de páginas:
no ven la memoria de nadie. Para hacer algo, tienen que pedírselo al sistema.
Si intentan tocar un aparato o leer memoria ajena, el procesador los para y
FalOS los cierra sin que caiga nada más.

```
lanza cuenta
lanza primos
lanza apaga
lanza espia
tareas
```

```
lanza gigante
lanza desborda
lanza fuera
lanza corto
lanza carta
```

Cada programa sale en su ventana, con el borde y el título del color de su
caja, como en [Qubes OS](https://www.qubes-os.org). Ese borde lo pinta el
núcleo: un programa solo le manda letras, y no puede salir de su rectángulo ni
cambiar su título. Con el ratón, las ventanas se arrastran por el título, se
traen delante con un clic y se cierran con la x, que cierra también el programa.
`disfraz` dice que es FalOS y te pide la contraseña, pero su ventana dice quién es:

```
lanza cuenta
lanza primos
lanza disfraz
```

Lo que escribes va a la consola, salvo que tú le des el teclado a un programa:
con un clic en su ventana o con `teclado N`. Mientras lo tiene, su título lo
dice, y Esc lo devuelve siempre a la consola, porque esa tecla no le llega a
ningún programa. Un programa no puede pedir el teclado ni quitárselo a otro.
En el disco hay un juego para probarlo, escrito en Fal: una serpiente que crece.
Guarda tu récord en el disco, y sigue ahí aunque apagues.

```
lanza serpiente
teclado 1
```

Un programa puede guardar hasta 512 bytes en el disco, pero solo en un archivo:
el suyo. Lo pide con una llamada, y es el núcleo quien pone el nombre, con el
del programa: `serpiente` escribe en `serpiente.dat` y en nada más. El que
escribe de verdad es el programa del disco, y no pisa lo que no entiende: si el
índice está roto, o el sitio de ese archivo cae encima de otro, no escribe ahí.
Primero escribe los datos y luego el índice, así que un apagón a medias no deja
el índice señalando a medio archivo. `veces` es el ejemplo más corto: cuenta
cuántas veces lo has lanzado.

Y ningún programa guarda nada sin preguntarte. La primera vez que lo intenta,
FalOS te dice cuántos bytes y en qué archivo, y el programa espera hasta que
contestes. `olvida` borra lo que guardó un programa de verdad: llena de ceros el
sitio donde estaba antes de quitarlo del índice.

```
lanza veces
deja 1
disco
lee veces.dat
olvida veces
```

`notas` es un bloc de notas que guarda cifrado con tu contraseña. El cifrado es
ChaCha20, escrito en Fal, y la clave sale de la contraseña después de 20.000
vueltas, para que probar contraseñas a ciegas cueste. Al disco solo llega ruido:
`lee notas.dat` lo enseña. Y cada vez que un programa lee o escribe en el disco,
el núcleo lo pinta en la barra de arriba, con el color de su caja, donde ninguna
ventana lo puede tapar.

```
lanza notas
teclado 1
lee notas.dat
```

`registro` dice qué programa ha leído o guardado qué, y cuándo, y también lo que
decidiste tú: a quién dejaste guardar, a quién le diste el teclado y con cuántas
teclas tuyas se cerró. Ese registro solo vive en memoria: no se escribe en el
disco, se borra al apagar y ningún programa tiene forma de leerlo. La hora sale
del reloj de la placa, y está también en la barra. Y `deja siempre` recuerda un
permiso aunque reinicies: `permisos` dice quién lo tiene, y `niega` con su
nombre se lo quita.

```
lanza veces
deja siempre 1
registro
niega veces
```

Los programas nacen sin ningún permiso, tampoco el de hablar con otro. Se
hablan con mensajes, una pregunta y una respuesta, y solo si tienen una llave:
una capacidad que guarda el núcleo y que un programa no puede fabricar ni
adivinar. Las das y las quitas tú, mientras corren:

```
lanza caja
lanza curioso
lanza ladron
permite 2 1
prohibe 2 1
permisos
```

El teclado, el disco y la pantalla ya no van dentro del núcleo. Son programas
del anillo 3, y el procesador solo les deja tocar lo suyo: `teclado`, el puerto
96, por el que llega también el ratón; `disco`, del 496 al 503; y `pantalla`, los puertos de la tarjeta gráfica y su
imagen, y lee lo que hay que pintar sin poder cambiarlo. Si uno se cuelga o se
rompe, FalOS lo nota, lo cierra y lanza otro sin que caiga nada más. Se puede
probar:

```
lanza cuenta
cuelga teclado
rompe teclado
cuelga pantalla
rompe pantalla
disco
lee carta.txt
lanza fisgon
lanza impostor
```

Cada vez que se sube algo, GitHub lo arranca en QEMU, comprueba que llega a
esperar órdenes sin reventar, lanza `apaga` y `espia` y mira que los dos acaban
cerrados y el sistema sigue. Da un permiso, lo quita y mira que `ladron` no ha
abierto nada. Cuelga y rompe el teclado, el disco y la pantalla, y comprueba que
todo vuelve. Le da archivos que mienten sobre lo que son, y le conecta discos
hechos para romperlo. Abre cuatro ventanas, mira que cada una lleva su color y
cierra dos con el ratón. Juega a la serpiente con `disfraz` abierto al lado, y
mira que a `disfraz` no le ha llegado ni una tecla. Y escribe en el disco: arranca
dos veces, mira que la segunda se acuerda, y le conecta tres discos para que se
equivoque: uno con el índice roto, otro lleno, y otro en el que el archivo de
`veces` cae encima de su propio programa. En los dos primeros comprueba que el
disco sigue igual byte a byte, y en el tercero, que el programa sigue entero.
Le niega el permiso y mira que no se ha guardado nada, y después de `olvida`,
que donde estaba el archivo solo quedan ceros. Escribe una nota con `notas`, la
descifra con un ChaCha20 escrito aparte en Python, que antes pasa la prueba del
RFC 8439, y comprueba que el texto no está en el disco y que una contraseña
equivocada no abre nada. Da un permiso para siempre, reinicia y mira que no
vuelve a preguntar; se lo quita y mira que pregunta. Busca el registro en el
disco y no puede estar, y le mete un byte raro a la lista de permisos para ver
que FalOS la tira entera en vez de creérsela.

La idea a la que se quiere llegar es un **micronúcleo con capacidades**, como
[seL4](https://sel4.systems): un núcleo pequeño que casi no hace nada, y cada
programa y cada controlador en su propia caja, sin poder tocar lo que no se le
ha dado expresamente. Los mensajes, las capacidades y tres controladores ya
están. Falta sacar del núcleo lo que todavía vive en él.

## Lo que no cubre

- **Casi todo, de momento.** No hay red, y un programa solo escribe su propio
  archivo, de 512 bytes como mucho: no se puede escribir un programa dentro de
  FalOS. Es el día 11.
- **Aún no es un micronúcleo.** El teclado, el disco y la pantalla ya salieron,
  pero la consola, el cargador y el vigilante que los reinicia siguen dentro del
  núcleo, y un fallo ahí para todo. El núcleo no adelgaza: tiene unas 3.750
  líneas, más que ayer, porque ahora también lleva el registro.
- **Nadie comprueba quién escribió un programa.** No hay firmas. Quien pueda
  cambiar el disco puede cambiar un programa, y FalOS lo lanzará. Lo que le
  protege es la caja, no saber de dónde viene.
- **La cabecera se mira, el código no.** Un programa que no miente sobre su forma
  se carga aunque sea malo. Hace lo que quiera dentro de su caja.
- **El programa de la pantalla ve todo lo que se pinta, y puede pintar mentiras.**
  No puede cambiar lo que escribe el núcleo, pero sí enseñarte otra cosa. Eso
  vale también para los bordes: el color lo decide el núcleo, pero lo pinta él.
  Los bordes te protegen de los programas, no de ese programa. Aún no hay nada
  en la pantalla de lo que te puedas fiar del todo.
- **Las ventanas son de letras.** Una ventana es un rectángulo de casillas, de 34
  por 6 si el programa no pide otro, y como mucho de 60 por 18. Un programa pone
  letras de colores en ellas, no píxeles, y caben cuatro.
- **Dentro de su ventana, un programa pinta lo que quiera.** También una ventana
  falsa, con el borde de otro color. La de verdad es la de fuera, la que lleva el
  título, y esa es la que hay que mirar.
- **Cada programa guarda 15 teclas.** Si no las lee, las siguientes se pierden.
- **Solo ratón PS/2.** Es el que trae QEMU. Al hacer clic en su ventana, QEMU se
  queda con el ratón, y lo suelta con la combinación que pone en su título. Ni
  USB ni pantallas táctiles.
- **Los gráficos son los de la tarjeta de QEMU.** Con otra tarjeta, FalOS se queda
  en modo de texto. En un portátil de verdad haría falta otro camino.
- **La letra tiene 125 caracteres.** El español, las líneas de las cajas y poco más.
- **El programa del teclado ve todo lo que escribes**, y ahora también cómo
  mueves el ratón. Está en su caja y no puede hacer nada más, pero si alguien lo
  cambiara por otro, lo leería todo.
- **El disco es el IDE de siempre.** Es el que trae QEMU, no el de un portátil
  de ahora, y el formato es uno de texto propio: ni FAT, ni nada que escriba
  otro sistema.
- **El índice del disco cabe en dos sectores.** Son 1.024 bytes, y hoy quedan
  unos 480 libres. Si no cabe, el programa recibe un error y el disco no se toca.
- **Un hueco del disco no se reutiliza.** Si el sitio de antes no vale, o se ha
  borrado con `olvida`, lo siguiente se escribe al final.
- **El cifrado de `notas` no se ha revisado.** ChaCha20 está comprobado con los
  números del RFC, pero la forma de sacar la clave de la contraseña es mía: 20.000
  vueltas de ChaCha20, sin la memoria que pide [Argon2](https://www.rfc-editor.org/rfc/rfc9106),
  así que con una tarjeta gráfica se prueban contraseñas mucho más deprisa. Una
  contraseña corta se adivina igual.
- **Cifrar no impide que cambien la nota.** No hay Poly1305 ni nada que la firme:
  quien pueda tocar el disco no la lee, pero puede estropearla sin que `notas` se
  dé cuenta.
- **Lo que se ve en la ventana está sin cifrar.** El núcleo pone las letras de la
  nota en la ventana y el programa de la pantalla las dibuja: los dos las ven.
  Cifrar protege el disco, no la memoria.
- **No hay azar de verdad.** Los números que hacen distinta cada clave salen del
  reloj y de cuándo pulsas las teclas, no de un generador de azar del
  procesador. Sirven para que no se repitan, no para ser secretos.
- **Los ceros de `olvida` valen en este disco.** En un SSD, el propio disco puede
  guardar copias de un sector en otro sitio sin decírselo a nadie, y escribir
  ceros encima no las alcanza. Ahí haría falta cifrar.
- **El permiso para siempre va por el nombre.** Se apunta que `veces` puede
  guardar, no qué `veces`: si alguien cambia `veces.prg` por otro programa con el
  mismo nombre, el nuevo lo hereda. Y quien pueda tocar el disco puede escribir
  `permisos.sis` a mano. Ningún programa de dentro puede.
- **El registro guarda los 16 últimos.** Si un programa repite lo mismo, se
  junta en una línea con las veces, pero uno que alterne cosas distintas puede
  empujar fuera lo de antes. Y no apunta lo que lees tú con `lee`.
- **La hora es la del reloj de la placa, en UTC.** FalOS no sabe en qué país
  estás, y si ese reloj va mal, el registro también.
- **Escribir un sector no es atómico del todo.** Si se va la luz justo mientras
  se escribe el índice, el disco puede quedar sin índice. No hay diario ni copia.
- **Un controlador que se cae siempre se relanza siempre.** No hay espera ni
  tope, y la pantalla se llena.
- **Un cuelgue tarda 1 s en notarse, o más.** Solo cuenta el tiempo en que el
  controlador pudo contestar y no lo hizo, para que un programa que acapare el
  procesador no lo haga parecer colgado. Con el procesador lleno son varios
  segundos de reloj. Las teclas que caben en la cola del aparato llegan después.
  Las que no, se pierden.
- **No hay prioridades.** Tres programas que gasten todo lo que les dan dejan a
  los controladores con un cuarto del procesador, y todo va más lento.
- **Las capacidades solo cubren hablar con otro programa.** La línea de la
  pantalla, el procesador, la memoria y los puertos se reparten sin ellas. Y las
  das tú desde la consola: un programa no le puede pasar una a otro.
- **seL4 está demostrado matemáticamente, y FalOS no.** Copiar la idea no
  copia la demostración.
- **Solo el teclado español.** Y sin €: todavía no lo he dibujado.
- **Solo el primer giga de memoria.** Si el ordenador tiene más, el resto
  no se usa todavía.
- **No es seguro todavía.** Está diseñado para el aislamiento, que no es lo
  mismo. Un sistema es seguro cuando alguien de fuera intenta romperlo y no
  puede, y eso aquí aún no ha pasado. No lo uses para nada que importe.
- **Solo se ha probado en QEMU.** En un ordenador de verdad debería arrancar
  con GRUB, pero no se ha comprobado.
- **Solo x86-64 y arranque por BIOS** (multiboot). Ni ARM ni UEFI.

## Filosofía

- **Un día, un paso que se vea.** Mejor poco y funcionando que mucho a medias.
- **No se promete lo que no se ha comprobado.** Lo que dice este README lo
  comprueba la prueba automática, o no lo dice.
- **Nadie tiene más permisos de los que necesita.** Tampoco el propio núcleo.
- **Los errores enseñan.** Cuando algo falla, la pantalla dice qué, en qué
  línea y cómo arreglarlo, como en el resto de Fal.
- **En castellano.** El código, los mensajes y el diario.

## Otros que hacen algo parecido

- [SerenityOS](https://github.com/SerenityOS/serenity) también nació en
  público, con vídeos de su autor programándolo. Es C++ y quiere ser un
  escritorio completo; FalOS va a paso de día y pone el aislamiento por
  delante.
- [TempleOS](https://templeos.org) se escribió en un lenguaje propio, HolyC,
  pero sin ninguna protección: todo corre con todos los permisos. FalOS es lo
  contrario.
- [Redox](https://www.redox-os.org) es un micronúcleo en Rust, con la misma
  idea de seguridad de memoria. Está mucho más avanzado; FalOS se construye
  desde cero y a la vista, para que se entienda cada paso.
- [Qubes OS](https://www.qubes-os.org) aísla con máquinas virtuales sobre Xen
  y Linux, y de él salen los bordes de colores. FalOS busca ese aislamiento en
  el diseño del propio núcleo, sin máquinas virtuales.

## Licencia

MIT.
