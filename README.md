# FalOS

Un sistema operativo escrito desde cero en [Fal](https://github.com/NissanBoss/Fal),
un lenguaje de programación en español. Se construye en público, un día cada
vez: cada día, un paso que se pueda ver, subido aquí y contado en
[TikTok](https://www.tiktok.com/@fal.lang).

![Copiado de la consola y pegado en cambiazo: la barra dice cuánto le queda y dónde lo pegaste](capturas/dia-13.png)

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
`disco`, `lee`, `deja`, `niega`, `olvida`, `registro`, `cerrojo`, `bloquea`,
`sin cerrojo`, `portapapeles`, `cuelga`, `rompe` y `reinicia`. Lo que escribes se corrige
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

`notas` es un bloc de notas que guarda cifrado con tu contraseña. La clave sale
de la contraseña con [Argon2id](https://www.rfc-editor.org/rfc/rfc9106), el que
ganó el concurso de 2015 para guardar contraseñas: cada intento llena 2 MB de
memoria tres veces, así que probar contraseñas a ciegas cuesta tiempo y memoria,
también con una tarjeta gráfica. Con esa clave, la nota se cifra con ChaCha20 y
se firma con BLAKE2b: si alguien cambia un solo bit en el disco, `notas` no la
abre y te dice que la han tocado, que no es lo mismo que equivocarte de
contraseña. La sal y el número que no se repite salen del generador de azar del
procesador (RDRAND), no del reloj. Todo está escrito en Fal, en
[comun/cifrado.fal](comun/cifrado.fal), y da byte a byte lo mismo que la
biblioteca de referencia de Argon2. Al disco solo llega ruido: `lee notas.dat` lo
enseña. Y cada vez que un programa lee o escribe en el disco, el núcleo lo pinta
en la barra de arriba, con el color de su caja, donde ninguna ventana lo puede
tapar.

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

`cerrojo` le pone contraseña a la pantalla. FalOS no la guarda: guarda su huella,
hecha con el mismo Argon2id, y una sal al azar. Desde entonces arranca bloqueado,
`bloquea` lo bloquea en el acto, y se bloquea solo si pasan 5 minutos sin que
toques el teclado ni el ratón. Bloqueado, los programas siguen corriendo, pero no
les llega ni una tecla ni un clic, lo que pintan no sale en la pantalla y no se
puede escribir ninguna orden. Lo que escribes ahí solo lo ve el núcleo. Al abrir,
te dice cuántas contraseñas malas probó alguien mientras no estabas, y el
registro apunta a qué hora.

```
cerrojo
bloquea
registro
sin cerrojo
```

Y lo que copias solo lo ves tú. En Windows o en Linux con X11, cualquier programa
puede leer el portapapeles cuando quiera, y también cambiarlo: hay programas que
esperan a que copies la dirección de un monedero para poner la suya. En FalOS no
hay ninguna llamada para leerlo ni para escribirlo. Arrastrando el ratón sobre un
texto, en una ventana o en la consola, lo marcas; Ctrl+C lo copia y Ctrl+V lo
pega. Esas dos teclas las atiende el núcleo, como Esc, y no le llegan a ningún
programa. Lo que pegas le llega al que tiene el teclado como si lo escribieras
tú, letra a letra, y nunca pulsa Intro: pegar en la consola no ejecuta nada. La
barra dice cuántos segundos le quedan, y la barra y el registro dicen dónde lo
pegaste. A los 30 segundos, o al bloquear la pantalla, se llena de ceros.
`portapapeles` dice cuánto hay y de dónde, sin enseñarlo. `cambiazo` busca cómo
leerlo o cambiarlo, e intenta pulsar Ctrl+V por ti, y no encuentra nada.

```
lanza cambiazo
portapapeles
teclado 1
registro
olvida portapapeles
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
que donde estaba el archivo solo quedan ceros. Escribe una nota con `notas`, saca
la clave con la biblioteca de referencia de Argon2, la descifra con un ChaCha20
escrito aparte en Python, que antes pasa la prueba del RFC 8439, y comprueba la
firma, que el texto no está en el disco y que una contraseña equivocada no abre
nada. Después le cambia un bit a la nota y mira que `notas` no la abre. Pone
contraseña a la pantalla, comprueba la huella con Argon2 y mira que la contraseña
no está en el disco; arranca bloqueado y mira que una orden escrita entonces no
llega a la consola, espera 5 minutos para verlo bloquearse solo, y con un
programa esperando tu permiso, escribe `deja 1` y mira que no se lo ha dado.
Marca con el ratón una orden de la consola, la copia y la pega en la consola y
en `cambiazo`: mira que en la consola no se ha ejecutado, que a `cambiazo` le
han llegado esas 14 teclas y ni una más, que sus 49 intentos se han rechazado,
que a los 30 segundos no queda nada que pegar y que al bloquear se borra. Da un
permiso para siempre, reinicia y mira que no
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
  FalOS. Es el día 13.
- **Aún no es un micronúcleo.** El teclado, el disco y la pantalla ya salieron,
  pero la consola, el cargador y el vigilante que los reinicia siguen dentro del
  núcleo, y un fallo ahí para todo. El núcleo no adelgaza: tiene unas 4.650
  líneas, y además el cifrado. La pantalla de bloqueo y el portapapeles viven en
  él.
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
- **Cada programa guarda 127 teclas.** Si no las lee, las siguientes se pierden,
  también las de un pegado.
- **El portapapeles es de 100 letras, sin colores ni saltos de línea.** Las
  líneas que marcas se juntan con un espacio, y por eso pegar no puede pulsar
  Intro. Si no cabe, `portapapeles` lo dice.
- **Solo se marca con el ratón.** Ni Mayús con las flechas ni doble clic.
- **30 segundos, siempre.** No se puede alargar para quien copia despacio ni
  acortar para una contraseña.
- **El núcleo sí lo ve.** Mientras dura, está sin cifrar en su memoria, como lo
  que sale en la pantalla. Al borrarse se llena de ceros.
- **Un programa puede pedirte que le pegues algo.** Lo pegado va a la ventana que
  tiene el teclado, y esa la eliges tú: si `disfraz` te pide que pegues tu
  contraseña y se la pegas, la tiene. El título de la ventana dice quién es.
- **Solo ratón PS/2.** Es el que trae QEMU. Al hacer clic en su ventana, QEMU se
  queda con el ratón, y lo suelta con la combinación que pone en su título. Ni
  USB ni pantallas táctiles.
- **Los gráficos son los de la tarjeta de QEMU.** Con otra tarjeta, FalOS se queda
  en modo de texto. En un portátil de verdad haría falta otro camino.
- **La letra tiene 125 caracteres.** El español, las líneas de las cajas y poco más.
- **El programa del teclado ve todo lo que escribes**, y ahora también cómo
  mueves el ratón. Está en su caja y no puede hacer nada más, pero si alguien lo
  cambiara por otro, lo leería todo, y podría pulsar Ctrl+V por ti.
- **El disco es el IDE de siempre.** Es el que trae QEMU, no el de un portátil
  de ahora, y el formato es uno de texto propio: ni FAT, ni nada que escriba
  otro sistema.
- **El índice del disco cabe en dos sectores.** Son 1.024 bytes, y hoy quedan
  unos 480 libres. Si no cabe, el programa recibe un error y el disco no se toca.
- **Un hueco del disco no se reutiliza.** Si el sitio de antes no vale, o se ha
  borrado con `olvida`, lo siguiente se escribe al final.
- **Argon2id con 2 MB, no con 19.** [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
  pide al menos 19 MiB y dos pasadas. FalOS usa 2 MB y tres, porque es lo que un
  programa puede pedir hoy de una vez, y en QEMU sin aceleración ya tarda unos 3
  segundos. Es mucho más caro de atacar que las 20.000 vueltas de ayer, pero
  menos que lo que recomiendan. Y una contraseña corta se adivina igual.
- **El cifrado no lo ha revisado nadie.** BLAKE2b, Argon2id y ChaCha20 dan lo
  mismo que las bibliotecas de referencia en todas las pruebas, pero están
  escritos a mano en Fal. Que coincidan no demuestra que no haya un fallo en un
  caso que no se ha probado.
- **Una contraseña mala y un comprobante tocado se ven igual.** `notas` mira
  primero un comprobante hecho con la clave, y luego la firma. Si alguien cambia
  el comprobante, te dirá que la contraseña no es esa, aunque lo sea.
- **Lo que se ve en la ventana está sin cifrar.** El núcleo pone las letras de la
  nota en la ventana y el programa de la pantalla las dibuja: los dos las ven.
  Cifrar protege el disco, no la memoria.
- **El azar es el del procesador.** RDRAND lo traen los procesadores de Intel
  desde 2012 y los de AMD desde 2015, pero el procesador que QEMU pone si no le
  dices otra cosa no lo tiene: hace falta `-cpu max`. Sin él, `notas` lo avisa y
  saca el azar del reloj y de cuándo pulsas las teclas. Para la sal y el número
  de cada guardado basta con que no se repitan, pero eso es más fácil de
  predecir. Y quien no se fíe del generador de Intel tampoco tiene aquí otro.
- **El bloqueo protege la pantalla, no el disco.** El disco no va cifrado: quien
  se lo lleve lee todo lo que no es una nota, y si borra `cerrojo.sis`, FalOS
  arranca sin contraseña. Si lo encuentra roto, lo dice al arrancar.
- **Entre intento e intento solo espera Argon2.** No hay un tope de intentos ni
  una espera que crezca. En QEMU son unos segundos por intento; en un ordenador de
  verdad, mucho menos.
- **Los programas siguen corriendo bloqueado.** No ven teclas ni ratón y no se
  ven, pero siguen haciendo lo suyo, como pedir guardar. El permiso espera a que
  vuelvas.
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
  y Linux, y de él salen los bordes de colores y la idea del portapapeles: entre
  dos cajas, lo copiado solo pasa con Ctrl+Mayús+C y Ctrl+Mayús+V. FalOS busca
  ese aislamiento en el diseño del propio núcleo, sin máquinas virtuales.

## Licencia

MIT.
