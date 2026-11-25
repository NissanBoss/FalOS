# FalOS

Un sistema operativo escrito desde cero en [Fal](https://github.com/NissanBoss/Fal),
un lenguaje de programación en español. Se construye en público, un día cada
vez: cada día, un paso que se pueda ver, subido aquí y contado en
[TikTok](https://www.tiktok.com/@fal.lang).

![busca pide permiso para preguntar al DNS, y con deja 1 le llegan las direcciones de fal-lang.org](capturas/dia-16.png)

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

### En un ordenador de verdad

FalOS arranca desde un pendrive con GRUB, por BIOS y por UEFI, y no se instala:
su disco va entero en la memoria y no toca ningún disco del ordenador. Lo que
guardes se borra al apagar, salvo que le pongas contraseña: entonces se queda en
el pendrive, cifrado ([cómo](#lo-que-guardas-en-el-pendrive)). Se ha probado en un
ThinkPad L450 de 2015, por los dos caminos, pero lo de guardar en el pendrive
solo en QEMU.

La imagen la hace GitHub cada vez que se sube algo (en Actions, el artefacto
`falos-pendrive`), o tú con GRUB y xorriso instalados:

```bash
fal --nucleo sistema.fal
```

```bash
fal haz_disco.fal
```

```bash
sh usb/haz_usb.sh
```

Grábala con [Rufus](https://rufus.ie) en **modo Imagen DD** (en modo ISO, Rufus
cambia el arranque de GRUB) o con `dd`. Borra el pendrive entero, también lo que
FalOS hubiera guardado en él. Luego enciende
el ordenador con el pendrive puesto y elige el pendrive en el menú de arranque
(F12 en un ThinkPad, F9 en muchos HP, F11 o F8 en muchas placas). Si no sale:

- **Quita Secure Boot.** GRUB va sin firmar, y con Secure Boot el ordenador no
  lo arranca. Se vuelve a poner después.
- **Si no arranca por UEFI, prueba por BIOS.** En la BIOS se llama CSM, Legacy o
  "Both". La misma imagen vale para los dos.
- **Si se queda parado al arrancar,** elige en el menú "FalOS sin IOMMU". Encender
  el IOMMU solo se ha probado en QEMU, y cada ordenador es un mundo.
- **Si arranca pero no puedes escribir,** mira el teclado. Los de los portátiles
  casi siempre son PS/2 por dentro y van solos. Uno USB va si el ordenador tiene
  IOMMU y está encendido en la BIOS (VT-d en Intel), o si tiene "USB Legacy
  Support", que lo hace pasar por PS/2. Si no hay nada de eso, FalOS lo dice en
  rojo al arrancar.

Dónde ha arrancado ya:

| Ordenador | Año | Por BIOS | Por UEFI | Teclado | Pantalla |
|---|---|---|---|---|---|
| ThinkPad L450 | 2015 | sí, día 17 | sí, día 19 | sí | sí |

Si lo pruebas en el tuyo, salga bien o mal, cuéntalo con la plantilla
[arranca en mi ordenador](https://github.com/NissanBoss/FalOS/issues/new?template=arranca.yml):
el modelo, cómo arrancó y una foto. Cada ordenador que aparezca aquí es uno que
alguien ha probado de verdad.

### Descargarlo, y romperlo

En [Releases](https://github.com/NissanBoss/FalOS/releases/latest) está la imagen
para el pendrive, el núcleo y el disco para QEMU, y el compilador de Fal con el
que se hizo, para Linux, Windows y Mac. La hace GitHub desde el commit de la
etiqueta, y solo la publica si pasan todas las pruebas.

Y si crees que puedes hacer que un programa se salga de lo que FalOS le deja,
[RETO.md](RETO.md) dice qué hay que conseguir, qué tiene un programa a mano y
cómo avisar. Dentro de FalOS, `reto` lo resume.

El núcleo está en [sistema.fal](sistema.fal), y los cuatro programas que necesita
para ver, oír, leer y salir a la red, en [controladores/](controladores). Lo que se va añadiendo
cada día está en el [diario](DIARIO.md).

Hoy FalOS arranca, pasa al modo de 64 bits, escribe en la pantalla con
colores y tildes, lee el teclado español con AltGr y entiende unas pocas
órdenes: `ayuda`, `limpia`, `hora`, `colores`, `encendido`, `memoria`,
`programas`, `lanza`, `tareas`, `para`, `teclado`, `tablas`, `permisos`, `permite`, `prohibe`,
`disco`, `lee`, `deja`, `niega`, `olvida`, `registro`, `cerrojo`, `bloquea`,
`sin cerrojo`, `portapapeles`, `ping`, `red`, `dma`, `usb`, `pendrive`, `cuelga`, `rompe`, `reto` y `reinicia`. Lo que escribes se corrige
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

Y en sus tablas no está el núcleo. Hasta el día 19 estaba entero, marcado como
prohibido, y eso no basta: en muchos Intel de antes de 2019, como el del
ThinkPad L450, un programa puede leer por especulación lo prohibido. Es
[Meltdown](https://meltdownattack.com). Ahora cada programa solo lleva siete
páginas del núcleo, las justas para entrar y volver: el código de la puerta,
la tabla de interrupciones y su propia pila de entrada. Al entrar, FalOS
cambia a sus tablas, y al volver, a las del programa. Es lo que Linux llama
[KPTI](https://docs.kernel.org/arch/x86/pti.html). `tablas N` cuenta lo que ve
la tarea N, y la prueba automática comprueba que son menos de 16, cuando antes
eran 196.607.

Y los aparatos tampoco tocan la memoria por su cuenta. Una tarjeta de red, un
disco o un controlador USB escriben en la memoria directamente (es el DMA), sin
pasar por el procesador ni por sus tablas, así que nada de lo de arriba los
para. Si el ordenador tiene IOMMU, que Intel llama
[VT-d](https://docs.kernel.org/arch/x86/iommu.html),
FalOS lo enciende al arrancar con todas las puertas cerradas: ningún aparato de
los que vigila lee ni escribe nada que no se le haya dado, ni puede fingir una
interrupción. `dma` lo prueba con el aparato de
prueba de QEMU: lo deja copiar dentro de su página, le pide leer el código del
núcleo y escribir en una página ajena, y cuenta lo que el IOMMU ha parado y
dónde. La prueba automática lo hace con IOMMU y sin él, para que se vea que
el aparato de verdad lee cuando nadie lo para: sin IOMMU, se trae `02 B0 AD 1B`,
la firma con la que empieza FalOS.

```bash
qemu-system-x86_64 -machine q35 -device intel-iommu -device edu -kernel sistema.bin
```

El teclado USB es el primer aparato de verdad que vive ahí dentro. Su controlador
es un programa del anillo 3 que solo tiene los registros del aparato y 64 páginas,
y el aparato ve esas 64 y ninguna más. `rompe usb` le hace pedir al aparato que
lea el núcleo, y el IOMMU lo para. Sin IOMMU, FalOS no lo enciende.

El teclado que está al arrancar vale. El que se enchufa después no escribe nada
hasta que se teclea en él el código de 6 cifras que sale en la pantalla, porque
un pendrive trucado puede hacerse pasar por teclado y escribir órdenes por ti
(es el [BadUSB](https://srlabs.de/blog/usb-peripherals-turn)). `usb` dice qué hay
enchufado y a qué le hace caso.

```bash
qemu-system-x86_64 -machine q35,i8042=off -device intel-iommu,intremap=on -device qemu-xhci -device usb-kbd -kernel sistema.bin
```

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

Un programa puede guardar hasta 464 bytes en el disco, pero solo en un archivo:
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

Y lo que guarda va cifrado, sin que el programa haga nada ni lo pueda evitar.
FalOS tiene una llave de 32 bytes al azar, del generador del procesador o, si
no lo trae, del instante exacto en que pulsas cada tecla, y de ella saca una
clave distinta para cada programa, con BLAKE2b y su nombre: lo que guarda `veces` no lo abre la
clave de `serpiente`, aunque alguien le copie el archivo. Cada guardado se cifra
con ChaCha20 y un número que no se repite, y se firma. Si alguien cambia un bit
en el disco, el programa no recibe nada y el registro lo apunta en rojo. Si el
archivo no va cifrado, tampoco: alguien lo ha puesto ahí a mano. El cifrado lo
hace el núcleo en una página suya, así que ni el programa del disco ve nunca lo
que guarda un programa.

`invitado`, o Intro sin escribir nada en la pantalla de bloqueo, entra en modo
invitado: cierra los programas, olvida la llave, el registro y el portapapeles,
y desde ese momento no se escribe nada en el disco. Lo que guarden los programas
vive en la memoria del núcleo hasta que reinicies, y al reiniciar se llena de
ceros. Lo tuyo sigue en el disco, cifrado, y sin la contraseña no se abre. La
prueba automática compara el disco byte a byte antes y después de una sesión de
invitado: es idéntico.

```
invitado
lanza veces
deja 1
registro
```

#### Lo que guardas en el pendrive

Si arrancas desde un pendrive, FalOS no escribe nada en él hasta que le pones
contraseña con `cerrojo`. Desde entonces, lo que guardan tus programas y los
permisos que das para siempre van al pendrive, cifrados. La próxima vez, al
escribir la contraseña, está todo. Quien se lo lleve ve que hay algo guardado y
cuántas veces se ha escrito, pero no qué, ni cuánto, ni los nombres de los
archivos: las dos copias miden siempre lo mismo.

La llave solo está en el pendrive envuelta con tu contraseña, por Argon2id con 19
MiB y dos pasadas, lo que [pide OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
Todo va cifrado con ChaCha20 y firmado con BLAKE2b, y hay siempre dos copias: la
nueva se escribe encima de la vieja, se le pide al pendrive que la asiente y se
lee para comparar. Si quitas el pendrive a medias, o alguien cambia un bit, FalOS
abre la otra y te lo dice. Si ninguna cuadra, no abre nada ni escribe encima.
Byte a byte está en [PENDRIVE.md](PENDRIVE.md).

Solo usa el pendrive del que arrancó. A cualquier otro que enchufes no le pide
más que mirar si es el suyo. Si lo quitas, lo siguiente que guardes se queda en la
memoria y se escribe cuando vuelva. Y si el que vuelve es una copia vieja del
tuyo, no la toca. El invitado no escribe en él.

`pendrive` dice qué hay, y `pendrive borra` llena de ceros las dos copias.

```
cerrojo
lanza veces
deja siempre 1
pendrive
reinicia
```

Para probarlo en QEMU con la imagen de la release:

```bash
qemu-system-x86_64 -m 512 -machine q35 -device intel-iommu,intremap=on -device qemu-xhci -drive if=none,id=lapiz,format=raw,file=falos.iso -device usb-storage,drive=lapiz
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
hecha con el mismo Argon2id, y una sal al azar. Argon2id da 64 bytes: con la
mitad se comprueba la contraseña, y con la otra se envuelve la llave que cifra lo
que guardan los programas, así que sin la contraseña no hay llave. Desde entonces arranca bloqueado,
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

Y a la red solo se sale cuando tú lo pides. FalOS sabe usar dos tarjetas, y el
controlador de cada una es otro programa del anillo 3. A la NE2000 de QEMU la
mueve byte a byte por sus 32 puertos, los únicos que el procesador le deja tocar.
La Intel de los portátiles de 2013 a 2015 (I217 e I218, y la 82574 que imita QEMU)
lee y escribe la memoria por su cuenta, así que al controlador le da 4 páginas de
registros y 21 de memoria, y a la tarjeta solo esas 21, por el IOMMU: donde deja lo
que llega no puede leer, y de donde coge lo que sale no puede escribir. Sin IOMMU no
la enciende. Con `rompe red`, el controlador le pide a la tarjeta que mande el
núcleo por el cable, y no sale.

FalOS no envía nada al arrancar: ni DHCP, ni anuncios, ni una sola trama. La
dirección de fábrica de la Intel no la usa nunca: se inventa una en cada arranque, y
otra si mueves el cable. Cuando haces `ping`, o dejas a un programa conectarse, le
pide una dirección a la red por DHCP diciendo lo mínimo, sin nombre ni marca
([RFC 7844](https://www.rfc-editor.org/rfc/rfc7844)), y desconfía de lo que le
contesten. [Tails](https://tails.net/contribute/design/MAC_address/) y
[Qubes](https://www.qubes-os.org/doc/anonymizing-your-mac-address/) también
cambian esa dirección, sobre Linux; aquí, además, no sale nada hasta que lo pides,
y la tarjeta está encerrada.

Después sale lo que pide `ping`: una pregunta ARP para saber quién tiene esa
dirección y cuatro ecos ICMP, uno por segundo, que llevan dentro `FalOS: solo
sale si tu lo pides.` La barra dice a quién haces ping mientras dura, el registro
lo apunta, y `red` dice cuántas tramas han salido desde que arrancó. `escucha`
busca otra forma de usar la red, no la encuentra, y cuando toca la tarjeta él
mismo, el procesador lo para. Para probarlo hay que darle la tarjeta a QEMU, que
`fal --arranca` no lo hace:

```bash
fal --nucleo sistema.fal
```

```bash
qemu-system-x86_64 -cpu max -kernel sistema.bin -drive file=disco.img,format=raw,if=ide -nic user,model=ne2k_pci
```

Y con la Intel y el IOMMU:

```bash
qemu-system-x86_64 -m 512 -machine q35 -cpu max -device intel-iommu,intremap=on -kernel sistema.bin -initrd disco.img -nic user,model=e1000e
```

```
ping
ping 10.0.2.99
lanza escucha
red
registro
```

Un programa también puede hablar con alguien de fuera, pero no sin preguntarte.
Lo pide con una llamada: una dirección, un puerto y lo que quiere mandar, un
mensaje UDP. El programa se queda esperando, y FalOS te dice quién quiere
conectarse, a qué dirección y puerto, y cuántos bytes mandaría. Con `deja N` sale
ese mensaje y la respuesta le llega solo a él; con `niega N` no sale nada, y si lo
vuelve a intentar con el mismo sitio, ni te pregunta. El permiso vale para esa
dirección y nada más: si el programa quiere hablar con otra, te vuelve a
preguntar. Mientras habla, la barra dice quién y con quién, y el registro apunta
lo que dejaste, lo que negaste y cuántos bytes volvieron. `busca` le pregunta al
DNS de la red dónde está fal-lang.org y te enseña sus direcciones, sin llegar a saber
qué DNS es; `chivato` quiere
contarle a un servidor de fuera qué programas usas.

```
lanza busca
deja 1
lanza chivato
niega 2
registro
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

El teclado, el disco, la pantalla y la red ya no van dentro del núcleo. Son programas
del anillo 3, y el procesador solo les deja tocar lo suyo: `teclado`, el puerto
96, por el que llega también el ratón; `disco`, del 496 al 503; `red`, los 32 de la tarjeta, o los registros de la Intel; y `pantalla`, los puertos de la tarjeta gráfica y su
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
todo vuelve. Le da una tarjeta de red y lo graba todo: con `escucha`, `fisgon` y el
controlador colgado y roto, mira que de FalOS no ha salido ni una trama; con
`ping`, que han salido una pregunta ARP y cuatro ecos con las sumas de control
bien, en orden y con su texto, y que han vuelto cuatro respuestas. Deja a `busca`
preguntar al DNS y niega dos veces a `chivato`: mira que ha salido un solo mensaje
UDP, a 10.0.2.3, con las sumas de control bien, y que hacia los servidores de
`chivato` no ha salido ni una pregunta ARP. Con la Intel hace lo mismo, y además
mira que la dirección de fábrica no aparece en ninguna trama, que quitar el cable
le cambia la cara, que sin IOMMU no se enciende y que `rompe red` no saca el núcleo.
Y le pone delante una red falsa que le miente de 39 maneras. Le da archivos que mienten sobre lo que son, y le conecta discos
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
que FalOS la tira entera en vez de creérsela. Rompe la consola, la cuelga y la
para, y mira que cada vez FalOS lanza otra y la orden siguiente funciona; y lanza
`mandon`, que finge ser la consola, y mira que sus tres órdenes se rechazan.
Arranca desde la imagen del pendrive por BIOS y mira que sin contraseña no cambia
ni un byte. Se la pone, guarda, comprueba que solo ha cambiado el sitio reservado
y que ahí no se lee ni un nombre de archivo, y lo abre desde fuera con la
biblioteca de referencia de Argon2. Después arranca la misma imagen por UEFI,
falla la contraseña, acierta, y mira que está todo. Quita el pendrive, lo vuelve a
poner, rompe el controlador, le cambia un bit a una copia y luego a las dos,
entra de invitado y prueba con un pendrive de solo lectura.

La idea a la que se quiere llegar es un **micronúcleo con capacidades**, como
[seL4](https://sel4.systems): un núcleo pequeño que casi no hace nada, y cada
programa y cada controlador en su propia caja, sin poder tocar lo que no se le
ha dado expresamente. Los mensajes y las capacidades ya están, y cuatro
controladores y la consola ya viven fuera del núcleo. Falta sacar lo que todavía
vive en él.

## Lo que no cubre

- **Casi todo, de momento.** De la red solo sabe hacer `ping`, y que un programa
  mande un mensaje y espere su respuesta. Un programa solo escribe su propio
  archivo, de 464 bytes como mucho: no se puede escribir un programa dentro de
  FalOS. Es el día 19.
- **Aún no es un micronúcleo.** El teclado, el disco, la pantalla, la red y la
  consola ya salieron, pero el cargador y el vigilante que los reinicia siguen
  dentro del núcleo, y un fallo ahí para todo. La consola entiende lo que
  escribes, pero lo que hace cada orden (lanzar un programa, enseñarte las
  tareas) lo sigue haciendo el núcleo. Por eso apenas adelgaza: tiene unas 9.600
  líneas, con el cifrado. La pantalla de bloqueo y el portapapeles viven en
  él.
- **La consola puede dar permisos.** Es lo que tiene que poder hacer: cuando
  escribes `deja`, es ella quien se lo pide al núcleo. La separa de los demás que
  es la única con esa llamada, que FalOS la lanza desde su propia imagen y no del
  disco, y que lo único que le llega es lo que tecleas tú.
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
- **Solo ratón PS/2.** Es el que trae QEMU, y el TrackPoint y el touchpad de
  muchos portátiles. Al hacer clic en su ventana, QEMU se queda con el ratón, y
  lo suelta con la combinación que pone en su título. Ni ratones USB ni
  pantallas táctiles.
- **Del USB, solo teclados y el pendrive de FalOS, y con IOMMU.** Ni otros
  pendrives, ni ratones, ni nada que vaya por un hub, y como mucho 4 aparatos a la
  vez, de ellos un solo pendrive. Solo controladores xHCI, los de USB 3. Las luces
  del teclado no se encienden. Y solo se ha probado en QEMU.
- **Guardar en el pendrive pide muchas cosas.** Un IOMMU encendido, un puerto USB
  sin hub, un pendrive de sectores de 512 bytes y que esté puesto al arrancar. Si
  falta algo, FalOS lo dice y lo que guardes se borra al apagar. Caben 28 archivos
  de 512 bytes: son los de los programas de FalOS, no los tuyos de otro sistema.
- **No está probado en ningún pendrive de verdad.** Solo en el de QEMU, por USB 2
  y USB 3, con dos controladores. Los de verdad tienen sus manías.
- **El FalOS del pendrive no se comprueba.** Quien lo tenga un rato puede cambiarlo
  por otro que se apunte tu contraseña, y devolvértelo. El cifrado protege de
  quien se lo lleva, no de quien te lo devuelve. Y si un día tu FalOS no te pide
  la contraseña, alguien ha borrado lo que guardaste.
- **Una copia vieja entera no se nota.** Si alguien clona el pendrive y otro día te
  pone el clon mientras FalOS está apagado, FalOS abre lo de aquel día. Va firmado
  y es tuyo, solo que de antes. No tiene dónde apuntar cuál era la última.
- **Borrar un pendrive no borra su memoria flash.** El pendrive puede guardar
  copias de lo que se sobrescribe donde FalOS no llega. Van cifradas, pero con la
  contraseña de entonces: si la cambias porque alguien la sabe, esas copias
  siguen abriéndose con la vieja, y la llave de dentro es la misma.
- **Si olvidas la contraseña, se acabó.** No hay otra forma de abrirlo. Y quien se
  lo lleve puede probar contraseñas sin parar, en otro ordenador más rápido:
  Argon2id lo hace caro, pero una corta cae.
- **El código del teclado nuevo para a un aparato, no a una persona.** Quien está
  delante lo lee en la pantalla igual que tú. El que ya está enchufado al arrancar
  no pasa por ahí, así que un aparato trucado que lleve puesto desde antes
  escribe. Y en un procesador sin generador de azar, recién arrancado y sin haber
  tecleado nada, el código sale de poco más que la hora.
- **En un ordenador de verdad, la pantalla es la de 1024x768 que da GRUB.**
  FalOS pinta su cuadro de 960x600 en el centro, y una pantalla más ancha lo
  estira. Si la tarjeta no tiene ese modo a 32 bits, la pantalla se queda en
  negro. Y si FalOS revienta, el aviso rojo no se ve: lo escribe en el modo de
  texto, que ahí no está.
- **La letra tiene 125 caracteres.** El español, las líneas de las cajas y poco más.
- **El programa del teclado ve todo lo que escribes**, y ahora también cómo
  mueves el ratón. Está en su caja y no puede hacer nada más, pero si alguien lo
  cambiara por otro, lo leería todo, y podría pulsar Ctrl+V por ti.
- **El disco es el IDE de siempre, o la memoria.** El IDE es el que trae QEMU, no
  el de un portátil de ahora, y el formato es uno de texto propio: ni FAT, ni
  nada que escriba otro sistema. Desde el pendrive, el disco va en la memoria, y
  sin contraseña lo que guardes se pierde al apagar.
- **El índice del disco cabe en dos sectores.** Son 1.024 bytes, y hoy quedan
  unos 480 libres. Si no cabe, el programa recibe un error y el disco no se toca.
- **Un hueco del disco no se reutiliza.** Si el sitio de antes no vale, o se ha
  borrado con `olvida`, lo siguiente se escribe al final.
- **En el disco y en `notas`, Argon2id va con 2 MB, no con 19.** [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
  pide al menos 19 MiB y dos pasadas. FalOS usa 2 MB y tres, porque es lo que un
  programa puede pedir hoy de una vez, y en QEMU sin aceleración ya tarda unos 3
  segundos. Es mucho más caro de atacar que las 20.000 vueltas de antes, pero
  menos que lo que recomiendan. En el pendrive sí son 19 MiB, porque de él depende
  todo, y en QEMU sin aceleración cada intento tarda unos 20 segundos. Y una
  contraseña corta se adivina igual.
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
- **Sin RDRAND, el azar sale de tus teclas.** RDRAND lo traen los procesadores
  de Intel desde 2012 y los de AMD desde 2015, pero el que QEMU pone si no le
  dices otra cosa no lo tiene: hace falta `-cpu max`. Hasta el día 18, sin él la
  llave salía de la hora, y se adivinaba en 3 segundos mirando cuándo cambió el
  archivo. Desde el día 19, el núcleo lee el reloj del ordenador, que cuenta a
  1,19 MHz, en cada tecla y en cada movimiento del ratón, y encadena esas medidas
  con BLAKE2b. Es menos que RDRAND: si un programa guarda nada más arrancar, la
  llave sale de unas decenas de medidas (cada tecla da dos: al pulsarla y al
  soltarla), y con menos de 16 FalOS no la crea. La portada lo avisa. Un disco
  del día 18 o antes que se usó sin `-cpu max` sigue con la llave de entonces:
  empieza con uno nuevo. Y quien no se fíe del generador de Intel tampoco tiene
  aquí otro.
- **El disco no va cifrado entero.** Lo que guardan los programas sí, pero los
  nombres de los archivos, lo que ocupa cada uno, los programas y `permisos.sis`
  se leen tal cual. Y si alguien borra `cerrojo.sis`, FalOS arranca sin
  contraseña: lo guardado sigue sin abrirse, porque la llave se va con él, pero
  la pantalla ya no pide nada. Si lo encuentra roto, lo dice al arrancar.
- **Sin contraseña, la llave está en el disco.** Sin `cerrojo`, la llave va en
  `llave.sis` tal cual. Así un programa no abre lo de otro, pero quien se lleve
  el disco lo abre todo. Al quitar la contraseña, FalOS lo avisa.
- **Cambiar la contraseña no cambia la llave.** Se envuelve la misma con la
  nueva. Quien guardara una copia del disco y supiera la contraseña de entonces
  saca la llave, y con ella abre también lo que se guarde después.
- **Bloqueado, la llave sigue en memoria.** Los programas siguen corriendo y
  pueden pedir guardar, así que el núcleo no la olvida al bloquear. Solo al
  entrar como invitado y al reiniciar.
- **Lo guardado antes del día 14 no se abre.** Iba sin cifrar, y FalOS no puede
  distinguir un archivo viejo de uno que alguien ha puesto ahí a mano. Y una
  contraseña de antes abre la pantalla, pero no tiene llave: hasta que la vuelvas
  a poner con `cerrojo`, los programas no pueden guardar.
- **El invitado ve qué hay.** Puede lanzar los programas del disco, ver los
  nombres de los archivos con `disco` y leerlos con `lee`: ruido, pero sabe cuánto
  ocupa cada uno. Y lo de sus programas cabe en 8 huecos de 464 bytes.
- **Del modo invitado se sale reiniciando.** No hay otra forma de volver a lo tuyo,
  a propósito: así no queda nada a medias. Si en vez de `reinicia` cortas la luz,
  lo que guardaron sus programas no se llena de ceros: se queda en la memoria
  hasta que se borre sola.
- **Entre intento e intento solo espera Argon2.** No hay un tope de intentos ni
  una espera que crezca. En QEMU son unos segundos por intento; en un ordenador de
  verdad, mucho menos.
- **Los programas siguen corriendo bloqueado.** No ven teclas ni ratón y no se
  ven, pero siguen haciendo lo suyo, como pedir guardar. El permiso espera a que
  vuelvas.
- **Los ceros de `olvida` valen en este disco.** En un SSD, el propio disco puede
  guardar copias de un sector en otro sitio sin decírselo a nadie, y escribir
  ceros encima no las alcanza. Lo que guardan los programas va cifrado, así que
  esas copias son ruido; el índice, con los nombres, no.
- **El permiso para siempre va por el nombre.** Se apunta que `veces` puede
  guardar, no qué `veces`: si alguien cambia `veces.prg` por otro programa con el
  mismo nombre, el nuevo lo hereda. Y quien pueda tocar el disco puede escribir
  `permisos.sis` a mano. Ningún programa de dentro puede.
- **Si el controlador de la red es otro, puede enviar lo que quiera.** El núcleo
  le da la tarjeta, no mira cada trama. Quien cambie `controladores/red.fal` o `controladores/intel.fal` y
  vuelva a compilar el núcleo, o lo cambie dentro de la imagen, puede sacar
  tramas sin que nadie haga ping. Lo que hoy lo impide es que el que hay no lo
  hace, y que la prueba automática graba todo lo que sale y mira que no hay nada.
- **La red vive en el núcleo.** ARP, IP, ICMP y UDP los arma el núcleo, no un programa.
  Es poco código, pero es más núcleo.
- **La Intel solo se ha probado en QEMU.** Es la 82574 que imita QEMU, con su red de
  usuario y con una falsa. La I217 y la I218, que son otras por dentro, están
  escritas pero sin probar en ningún ordenador. No hay wifi, ni la I219 de los
  portátiles de 2016 en adelante, ni ninguna de otra marca. Y la NE2000 sigue con
  la dirección fija de QEMU.
- **El chip de la Intel puede hablar sin FalOS.** En los portátiles de empresa lo
  comparte con el procesador de gestión de Intel (AMT), que usa la red por su cuenta
  y con la dirección de fábrica si está encendido. Se apaga en la BIOS.
- **La dirección inventada no te hace invisible.** Hasta que reinicias o mueves el
  cable es siempre la misma, hay redes que solo dejan entrar a direcciones
  apuntadas, y la forma de hablar de FalOS no se parece a la de ningún otro.
- **La red miente si quiere.** FalOS comprueba que la dirección que le dan tiene
  sentido, no que quien la da sea quien manda. Quien esté en tu red puede mandarte
  a su salida y a su DNS.
- **Poca red.** `ping` quiere números: FalOS no usa el DNS él solo. No hay TCP ni
  IPv6. Un programa manda un mensaje UDP y espera una sola respuesta, 3 segundos
  como mucho. Mientras espera, la consola también, y pedir dirección donde nadie
  contesta tarda hasta medio minuto.
- **El permiso va por dirección, no por lo que se manda.** FalOS te dice cuántos
  bytes salen, pero no qué llevan. Un programa al que dejas hablar con una
  dirección puede mandarle lo que quiera hasta que se cierre.
- **Una dirección es solo un número.** FalOS no sabe de quién es. 10.0.2.3 es el
  DNS de QEMU, que a su vez pregunta al de tu ordenador: dejar a `busca` es dejar
  que esa pregunta llegue a tu proveedor.
- **Un programa puede preguntar mucho.** Si le niegas una dirección, con esa ya no
  te pregunta, pero puede pedir otra, y otra. No hay tope.
- **El tiempo de `ping` va de 10 en 10 ms.** Lo mide con el reloj de los turnos,
  así que una respuesta de 1 ms dice 10 o 20.
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
- **Parar Meltdown cuesta, y se paga siempre.** Sin PCID, cada cambio de
  tablas tira lo que el procesador tenía traducido. Con `lanza mide`, en una
  máquina virtual con aceleración, una llamada al sistema pasa de 0,2 a 0,44 µs:
  de 5,1 millones por segundo a 2,3. En QEMU sin aceleración es peor, de 1,1
  millones a 0,14, porque QEMU tira toda su caché en cada cambio. Linux lo
  abarata marcando cada juego de tablas con un número para no tirarlo, y FalOS
  aún no. Y lo paga también un procesador que no lo necesita, como un AMD o un
  Intel moderno: FalOS no pregunta.
- **Las siete páginas se pueden leer.** Son el código de la puerta, que está en
  este repositorio, las tablas que el procesador necesita para entrar y la pila
  de entrada del propio programa, con sus registros. Nada de otro programa ni
  del núcleo, pero sí dicen dónde están sus tablas, y en FalOS nada cambia de
  sitio entre un arranque y otro.
- **Meltdown no se ha lanzado contra FalOS.** Lo que se comprueba es que el
  núcleo no está en las tablas: la prueba cuenta las páginas, y `espia` ya no
  choca con un permiso sino con una página que no existe. En QEMU sin KVM el
  ataque no se reproduce, y en el portátil no lo he intentado.
- **Spectre es otra cosa.** Engaña a la predicción de saltos para que el
  propio núcleo, u otro programa, lea por adelantado lo que su código no
  leería. Pide otros arreglos, y FalOS no tiene ninguno.
- **Dos programas pueden hablarse a escondidas.** El núcleo no guarda los
  registros del x87 de cada programa, así que dos hechos a mano pueden pasarse
  datos por ahí, y también midiendo el tiempo. Uno sin red se lo puede contar a
  otro que sí la tenga. No es una fuga del núcleo: Fal no usa el x87, y el núcleo
  no deja nada en él.
- **No es seguro todavía.** Está diseñado para el aislamiento, que no es lo
  mismo. Un sistema es seguro cuando alguien de fuera intenta romperlo y no
  puede, y eso aquí aún no ha pasado: para eso está el [reto](RETO.md). No lo
  uses para nada que importe.
- **Pocos ordenadores de verdad.** Los de la tabla de arriba, y nada más. En
  otro puede fallar el teclado, el reloj o la pantalla, y la red solo está
  escrita para las Intel I217 e I218, sin probar.
- **El IOMMU solo se ha probado en QEMU.** Por BIOS y por UEFI, pero nunca en un
  ordenador de verdad.
- **Lo que pide la BIOS se da sin mirar.** Algunos aparatos, como el USB que
  imita un teclado PS/2, usan trozos de memoria que la BIOS se reserva (RMRR).
  FalOS se los da tal cual, salvo al USB, al que se los quita cuando lo coge, y
  si pide algo que no sabe dar, no enciende el IOMMU. Ese camino no se ha probado: QEMU no pide ninguno.
- **Una sola unidad de IOMMU.** Un ordenador puede tener varias. FalOS
  enciende la primera que no sea la de la gráfica integrada. Esa la deja
  apagada, porque la pantalla se lee de la memoria por su cuenta, y cerrarle
  la puerta la dejaría en negro. Si hay más, `dma` lo dice, y lo que vigilan
  sigue sin vigilar.
- **Las interrupciones, solo si el IOMMU sabe.** Si no trae remapeo de
  interrupciones, o al encenderlo FalOS deja de oír su propio reloj, lo apaga, y
  entonces un aparato puede fingir una. `dma` lo dice.
- **Solo x86-64**, arrancado por multiboot: con QEMU o con GRUB. Ni ARM ni
  Secure Boot.

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
  También encierra el USB, en una máquina virtual aparte, y
  [puede preguntarte](https://doc.qubes-os.org/en/latest/user/how-to-guides/how-to-use-usb-devices.html)
  antes de hacer caso a un teclado nuevo.
- [USBGuard](https://usbguard.github.io) deja elegir qué aparatos USB acepta
  Linux, con una lista hecha de lo que cada uno dice ser, y un aparato puede
  mentir en eso. El código de FalOS no pregunta al aparato quién es: comprueba
  que quien teclea está viendo la pantalla.
- [Tails](https://tails.net) arranca sin tocar el disco del ordenador y lo olvida
  todo al apagar. El modo invitado de FalOS es esa idea dentro del sistema de
  siempre: entras sin contraseña, usas lo que hay, y no se escribe nada. Y su
  [almacenamiento persistente](https://tails.net/doc/persistent_storage/index.en.html)
  guarda en el pendrive, cifrado, lo que tú elijas. Es una partición entera con
  LUKS, caben todos tus archivos y lleva años en uso: para guardar algo
  importante, usa ese. En FalOS cabe muy poco, pero todo va cifrado y firmado, y
  el controlador del pendrive corre sin permisos y con el IOMMU vigilándolo.
- [OpenSnitch](https://github.com/evilsocket/opensnitch) y
  [Little Snitch](https://www.obdev.at/products/littlesnitch) avisan cuando un
  programa quiere conectarse, pero viven encima de un sistema que se lo deja
  hacer a cualquiera. En FalOS el aviso no es un añadido: la única forma de
  salir es pedírtelo, y el permiso vale para una sola dirección.

## Licencia

MIT.
