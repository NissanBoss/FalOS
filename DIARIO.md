# Diario de FalOS

Un día, un paso. Lo más nuevo, arriba.

## Día 6: los programas salen del disco, y FalOS dibuja su propia letra

![FalOS en modo gráfico](capturas/dia-6.png)

**Lo que hay.** Se acabó la pantalla de 1981. FalOS ya pinta píxeles: 960 por 600,
con 32 bits por píxel, y una letra que no viene de ningún sitio. Cada carácter
está dibujado a mano en [un archivo de texto](controladores/letra.txt), con puntos
y almohadillas, en una rejilla de 6 por 12. Son 119. Al arrancar, FalOS los agranda
al doble y redondea las esquinas.

Quien pinta tampoco va dentro del núcleo. Es el tercer programa sin permisos,
como el teclado y el disco. Con `cuelga pantalla`, la imagen se congela un segundo
y vuelve. Nada de lo escrito se pierde, porque lo que hay que pintar lo guarda el
núcleo en una página que ese programa solo puede leer.

![La pantalla se cuelga, se rompe y vuelve](capturas/dia-6-pantalla.png)

Y los programas ya no van metidos en FalOS. Están en el disco, como archivos.
`lanza cuenta` los busca, los trae y les monta su caja. Lo único que FalOS lleva
dentro son los tres controladores que necesita para ver, oír y leer.

![Lo que hay en el disco](capturas/dia-6-disco.png)

**Lo que se aprende.** Hasta hoy, FalOS se fiaba de lo que ejecutaba, porque lo
llevaba compilado dentro. Un archivo de un disco es otra cosa: lo ha podido escribir
cualquiera. Y lo primero que se lee de un programa es su cabecera, cuatro números
en los que el propio programa dice cuánto ocupa, cuánta memoria quiere y por dónde
empieza. Es decir, le estás preguntando al desconocido quién es.

Un cargador que se lo cree es uno de los fallos más viejos que hay. Por eso `haz_disco`
mete en el disco cinco archivos hechos para engañar a FalOS:

![FalOS se niega a cargar cinco archivos](capturas/dia-6-mentiras.png)

`gigante` dice que necesita un terabyte. `fuera` dice que empieza dentro del núcleo.
`corto` está a medias. `carta` ni siquiera es un programa. Y `desborda` es el bueno:
dice que ocupa 9.223.372.036.854.775.807 bytes, el número más grande que cabe. Si
FalOS sumara algo a ese número para calcular cuántas páginas hacen falta, la cuenta
se saldría, y Fal pararía el sistema entero. Un archivo tumbaría el núcleo sin
ejecutar ni una instrucción. Por eso primero se compara con el tope y solo después
se hace ninguna cuenta.

**La seguridad.** Hay un detalle que no se ve. La cabecera llega por una página que
FalOS comparte con el programa del disco, y ese programa no es de fiar: podría
cambiar los números justo después de que FalOS los mire. Por eso FalOS los copia una
vez y ya solo usa su copia. Es un fallo con nombre propio, se lee en un momento y se
usa en otro, y lo que lo evita es una línea aburrida.

Al programa de la pantalla se le da lo justo: los puertos para encender los gráficos
y la imagen. No toca el bus PCI, que le daría poder sobre todos los aparatos: esa
dirección la busca el núcleo al arrancar y se la deja puesta. Y la página con el
texto que hay que pintar la tiene de solo lectura.

Después de cargar y cerrar programas y de rechazar los cinco archivos, FalOS sigue
usando la misma memoria prestada que al arrancar: 760 KB.

**Lo que costó.** La pantalla salió negra, y el programa que la pinta se reiniciaba
cientos de veces sin decir por qué. Era la misma trampa del día 2: en Fal las
mayúsculas no importan, así que `SUBIDAS` y `subidas` eran la misma variable. Una
variable nueva tapaba la constante, y el programa reventaba al primer pintado. FalOS
lo relanzaba, y reventaba otra vez.

Luego el aviso rojo. Si el núcleo se para con los gráficos puestos, tiene que volver al
modo de texto para contarlo, o verías una pantalla congelada. Apagar los gráficos
no basta: al encenderlos, la tarjeta había cambiado una docena de registros y
no los devuelve. Además, la letra del modo de texto vive en la misma memoria que
la imagen, y pintar encima la borraba. Por eso FalOS deja libres las primeras 70
filas de esa memoria.

Fal también ha crecido hoy: sabe hablar de 16 y de 32 bits con los aparatos, copiar
memoria de golpe sin saltarse las comprobaciones, meter un archivo en un programa
y compilar programas desde otro programa de Fal, que es lo que hace `haz_disco`.

## Día 5: el teclado sale del núcleo, y si se cuelga, vuelve

![FalOS lanza otro teclado después de que el suyo se cuelgue](capturas/dia-5.png)

**Lo que hay.** El teclado ya no va dentro del núcleo. Es un programa normal, en
el anillo 3, sin permisos, y traduce las teclas él solo: la ñ, las tildes, AltGr.
El núcleo solo le avisa de que ha llegado algo, y recibe la letra ya hecha.

Con `cuelga teclado` se queda dando vueltas a propósito. Dejas de poder escribir,
pero `cuenta` sigue contando abajo. Al segundo, FalOS se da cuenta, lo cierra y
lanza otro en menos de 10 ms. Lo que habías escrito mientras tanto aparece solo.

Con `rompe teclado`, intenta apagar el ordenador. No puede: el procesador solo le
deja tocar el puerto 96, y apagar es el 100, justo al lado. Se cierra, se lanza
otro, y sigues escribiendo.

![El teclado intenta apagar el ordenador y el procesador lo para](capturas/dia-5-permisos.png)

Y FalOS ya lee un disco. `disco` enseña lo que hay, y `lee carta.txt` saca un
archivo. Eso también lo hace un programa sin permisos, que solo toca los ocho
puertos del disco.

![Una carta leída del disco](capturas/dia-5-disco.png)

Dos programas nuevos lo intentan por las malas. `fisgon` quiere leer el teclado,
como haría un programa que te roba las contraseñas, y dura lo que tarda en tocar
el puerto. `impostor` quiere escribir `reinicia` haciéndose pasar por ti: lleva
decenas de intentos y no ha entrado ni una letra.

![fisgon e impostor](capturas/dia-5-espias.png)

**Lo que se aprende.** Un controlador es un programa que habla con un aparato, y
en casi todos los sistemas va dentro del núcleo, con todos los permisos. Por eso
un fallo en el de la tarjeta gráfica te da una pantalla azul. En un micronúcleo
va fuera, y un fallo ahí se queda ahí.

Y hay una pregunta que parece tonta: ¿cómo sabes que un programa se ha colgado?
No lo sabes, solo puedes decidir cuánto esperar. FalOS mira cuánto lleva
despierto sin volver a pedir trabajo, y a partir de 1 s lo da por muerto.

**La seguridad.** Desde el día 3, un programa no podía tocar ningún puerto, porque
le quitamos el mapa al procesador. Ahora ese mapa existe, con 65.536 bits, uno por
puerto, y nace todo cerrado. Es uno solo para todos, así que FalOS lo cambia cada
vez que cambia de programa. Lo que abre para el teclado solo vale mientras corre
el teclado.

El disco es lo más peligroso de hoy, porque lo que hay dentro lo puede haber
escrito cualquiera. Leerlo es exactamente cómo se cuelan muchos ataques. Por eso
quien lo lee no es el núcleo: si un disco trae un archivo con un tamaño absurdo,
el que se lo traga es un programa sin permisos. El núcleo solo recibe un número
que comprueba y una página que no puede desbordar. Lo probé con discos hechos
para romperlo: números gigantes, nombres sin fin, un índice sin saltos de línea,
ruido puro. Ninguno pasó de ahí.

**Lo que costó.** Lo mejor de hoy son los dos fallos que encontré, porque eran
míos y llevaban días ahí.

Si escribías 17 órdenes distintas, FalOS se paraba. Era del día 2. En Fal, las
mayúsculas no importan, así que `HISTORIAL`, el tope, y `historial`, donde se
guardan, eran la misma variable. El tope no existió nunca.

Y cualquier programa podía parar el sistema entero escribiendo una línea larga
en el cuarto renglón. Era del día 3. Un `para cada` que va de 81 a 80 no se
detiene: cuenta hacia atrás. Se salía de la pantalla, y Fal paró el núcleo.

Las dos veces, Fal hizo lo que debe: parar y decir en qué línea, en vez de seguir
escribiendo donde no toca. En C serían dos agujeros. Aquí fueron dos pantallas
rojas. Pero también dos fallos, y el segundo lo podía provocar un programa sin
permisos. Los dos están ahora en la prueba automática. Hasta hoy creía que ningún
programa podía tumbar FalOS, y era porque no lo había probado bien.

Y el teclado no volvía después de colgarse. El aparato avisa una vez, y si nadie
recoge la tecla, no vuelve a avisar: el programa nuevo se quedaba esperando un
aviso que ya había pasado. Ahora FalOS recuerda que quedó una tecla sin leer.

## Día 4: los programas hablan, si tú les dejas

![curioso consigue el secreto de caja](capturas/dia-4.png)

**Lo que hay.** Los programas se pueden mandar mensajes, y para eso necesitan
permiso. Tres programas lo enseñan:

- `caja` guarda un secreto, y lo cuenta si le preguntan.
- `curioso` pregunta cada segundo.
- `ladron` prueba miles de llaves a ver si alguna abre algo.

Al lanzarlos, nadie puede hablar con nadie. `curioso` dice que no tiene permiso,
y `ladron` lleva miles de intentos sin abrir nada.

![Nadie puede hablar con nadie](capturas/dia-4-sin-permiso.png)

Con `permite 2 1`, `curioso` ya puede preguntar a `caja`, y al segundo siguiente
sale el secreto en la pantalla. Con `prohibe 2 1`, deja de poder en el acto, sin
reiniciar nada y sin que el programa pueda hacer nada por evitarlo. Y `permisos`
enseña quién puede qué, y cuántas preguntas le han rechazado a cada uno.

![La orden permisos](capturas/dia-4-permisos.png)

Se hace como en seL4: el que pregunta se queda parado hasta que le contestan, y
el núcleo le pasa el turno directamente al otro. No hay cola de mensajes ni
memoria compartida. Un mensaje es un número de 64 bits y viaja en un registro,
así que el núcleo sigue sin leer nunca la memoria de un programa. Una pregunta y
su respuesta tardan tan poco que caben unas 42.000 por segundo, en un ordenador
emulado.

**Lo que se aprende.** Hay dos maneras de decidir quién puede qué. Una es la
lista de invitados: el portero mira quién eres y si estás en la lista. La usan
Windows y Linux, y la pregunta siempre es "¿quién eres?". Por eso un programa
que lanzas tú puede leer todos tus archivos: es tú.

La otra es la llave. Nadie mira quién eres: si tienes la llave, abres. Eso es
una **capacidad**, y es la idea de seL4. Un programa no tiene nada al nacer, y
nada que no le hayan dado. Lo que no le han dado no es que esté prohibido: es que
no tiene forma de nombrarlo.

**La seguridad.** Las llaves no están en la memoria del programa, sino en la del
núcleo. El programa solo dice "la llave número 1", y ese número solo significa
algo en su propia tabla. Si no hay llave ahí, no hay nada que forzar: `ladron`
prueba los números uno a uno, negativos y gigantes incluidos, y lo único que
consigue es que el contador de rechazos suba.

Y hay una trampa clásica. Si cierras `caja` y lanzas otro programa que cae en su
mismo sitio, una llave vieja abriría al nuevo, que no tiene nada que ver. Por eso
cada programa que arranca lleva un número de generación, y la llave guarda el
suyo: si no coincide, no abre. Lo mismo si el programa ya no existe.

Lo probé con programas hechos para atascarlo: uno que escucha y nunca contesta,
otro que contesta sin que le pregunten, otro que deja a uno esperando y se pone a
escuchar a otro, y dos que se preguntan el uno al otro hasta quedarse los dos
parados para siempre. Eso último no se puede evitar, porque es culpa de ellos,
pero no arrastra a nadie más: `tareas` los enseña esperando, y `para` los cierra.
Al cerrar a quien te tiene esperando, te despiertan con un error, y no te quedas
ahí para siempre.

**Lo que costó.** `pregunta` es una palabra de Fal, la que lee del teclado, así
que mi primera versión no compilaba. Cuando alguien escucha dos veces seguidas,
el que esperaba del primer mensaje se quedaba colgado para siempre. Lo vi
pensando qué haría un servidor malo: ahora le llega un error. Y el núcleo ha
crecido a más de 2.000 líneas: en un micronúcleo de verdad, todo lo que se pueda
tiene que salir de ahí. Es lo siguiente.

## Día 3: varias cosas a la vez, y programas sin permisos

![apaga intenta apagar el ordenador](capturas/dia-3.png)

**Lo que hay.** FalOS corre programas, varios a la vez, y sigue atendiéndote
mientras tanto. `lanza cuenta` y `lanza primos` se ponen a trabajar abajo, cada
uno en su línea, y tú sigues escribiendo arriba.

Y esos programas no tienen permisos. `apaga` tiene exactamente esta línea:

```
pon_en_puerto con 100 y 254
```

Es la misma que usa la orden `reinicia`. Cuando la escribe FalOS, el ordenador
se reinicia. Cuando la intenta `apaga`, el procesador la para antes de
ejecutarla, FalOS cierra el programa y todo lo demás sigue en marcha. `espia`
intenta leer la memoria de FalOS, y le pasa lo mismo.

Las órdenes nuevas:

- `programas`: los que lleva dentro.
- `lanza X`: pone a correr X.
- `tareas`: lo que está corriendo, en qué estado y cuánto procesador lleva.
- `para N`: cierra la tarea N.

**Lo que se aprende.** Un procesador tiene una sola mano: hacer dos cosas a la
vez es un truco. Cien veces por segundo, el reloj lo interrumpe. FalOS guarda
los registros del programa que corría, deja los de otro y sigue. El programa
no se entera. Y si un programa no suelta el procesador nunca, da igual: nadie
le pide permiso para quitárselo. `bucle` es un `mientras verdadero` vacío, y
puedes seguir escribiendo como si nada.

![bucle no suelta el procesador, y da igual](capturas/dia-3-bucle.png)

El procesador tiene cuatro anillos de permisos, y casi nadie usa más de dos: el
núcleo en el 0, los programas en el 3. Desde el 3 no se puede tocar un aparato,
cerrar las interrupciones, parar la máquina ni cambiar las tablas de páginas.
La única salida es una puerta: una instrucción que salta a un sitio fijo del
núcleo. Eso es una llamada al sistema, y hay cinco: salir, escribir una letra,
ceder el turno, preguntar la hora y dormir.

**La seguridad.** Cada programa tiene sus propias tablas de páginas, así que
ve su memoria y nada más. Su código es de solo lectura, y sus datos no se
pueden ejecutar. La página que el procesador usa para entrar en el núcleo es
aparte, y al cerrarlo, todo lo suyo vuelve al repartidor, que lo entrega en
blanco.

![espia intenta leer la memoria de FalOS](capturas/dia-3-espia.png)

Y lo más importante no es lo que hace el programa, sino lo que hace el núcleo
con lo que le llega. Todo lo que entra por una llamada al sistema es hostil.
En Fal, una cuenta que se sale para el sistema entero: si `dormir` sumara sin
mirar el número que le pasan, un programa podría tumbar a FalOS con solo pedir
dormir un número gigantesco. Ahora se mira cada dato antes de usarlo, y las letras van de
una en una para que el núcleo no tenga que leer nunca la memoria de un programa.

Lo probé con programas hechos para romperlo: pintar en la pantalla directamente,
leer el teclado, cambiar las tablas de páginas, reescribir su propio código,
desbordar su pila y pasar números absurdos en cada llamada. Ninguno tumbó nada.

**Lo que costó.** Cada interrupción se atiende en una pila aparte, una sola
para todo el sistema, igual que en seL4, y Fal ha tenido que aprender a saltar
de una a otra. La comprobación de "te has quedado sin pila" era una constante;
ahora depende de en cuál estés.

Hay dos trampas que no avisan. El procesador mira un mapa para saber qué puertos
puede tocar un programa, y si no le dices dónde está, cree que empieza en el
byte 0 de una tabla llena de ceros, y un cero significa "permitido". Quité esa
línea para comprobarlo, y `apaga` reinició el ordenador de verdad. Y un
programa puede poner al revés una bandera del procesador que el núcleo da por
hecho: al borrar su memoria, el núcleo iría hacia atrás, pisando lo que el
programa quisiera.

El primer intento reinició la máquina sin decir nada. Era una errata mía: le
había puesto el programa en el segundo giga en vez de en el primero. El registro
de QEMU lo dijo en un minuto: fallo de página, luego fallo doble, luego fallo
triple. El tercero es el que reinicia.

Y Fal no distingue mayúsculas: la constante `MARCO` y la variable `marco` eran
la misma, y el compilador me lo dijo con otra pareja que había escrito igual.

## Día 2: la memoria, y escribir como en una terminal de verdad

![La orden memoria](capturas/dia-2.png)

**Lo que hay.** FalOS sabe cuánta memoria tiene y quién la usa. La orden
`memoria` lo enseña: de 127 MB, todo FalOS (su código, su pila y sus tablas)
ocupa 524 KB. Y la reparte: quien necesita memoria pide una página de 4 KB,
y cuando acaba, la devuelve.

Y ya se escribe como en cualquier terminal: las flechas mueven el cursor
por lo que has escrito, Inicio y Fin te llevan a los extremos, Supr borra
hacia delante, y las flechas de arriba y abajo traen las órdenes de antes.

**Lo que se aprende.** Un sistema operativo no sabe al arrancar cuánta
memoria tiene. Se lo dice quien lo carga: deja en un registro del procesador
la dirección de una lista con los trozos de memoria y de qué es cada uno.
Hay agujeros: entre los 640 KB y el primer mega no hay memoria, sino la
pantalla y la BIOS. Es una herencia del primer PC de IBM, de 1981, que dejó 640 KB
para los programas y puso todo lo demás justo encima.

**La seguridad.** Cada página que FalOS presta, la entrega borrada. Si no,
el siguiente que la pidiera podría leer lo que dejó el anterior: contraseñas,
claves, lo que fuera. La orden `memoria` lo comprueba cada vez: presta una
página, escribe en ella, la recupera, se la presta a otro y mira que llega en
blanco. Y devolver dos veces la misma página para el sistema en seco, con la
pantalla roja: en C, ese descuido es uno de los agujeros de seguridad más
conocidos.

**Y el procesador vigila.** Al final del día, una cosa más: FalOS monta sus
propias tablas de páginas, la lista que el procesador consulta en cada acceso
a memoria para saber qué se puede hacer con cada página. Con ellas:

- su propio código es de solo lectura, y nadie lo puede cambiar mientras
  corre, ni siquiera FalOS;
- los datos no se pueden ejecutar, que es la defensa contra el truco clásico
  de colar código en la memoria y saltar a él;
- la dirección 0 no existe.

![Escribir encima del código](capturas/dia-2-solo-lectura.png)

No es una comprobación de FalOS: la hace el procesador, en cada acceso, sin
coste. Es lo mismo que hacen Windows y Linux.

**Lo que costó.** El dato de dónde está esa lista llega en un registro, y el
arranque lo pisaba antes de mirarlo: Fal ha tenido que aprender a guardarlo.
La pantalla roja de los errores ponía "p?gina": no sabía escribir tildes.
Y para que el procesador haga cumplir el "solo lectura" al propio núcleo hay
que encenderle un bit aparte; sin él, el núcleo se lo salta.

## Día 1: arrancar, escribir en la pantalla, leer el teclado y dormir

![FalOS al arrancar](capturas/dia-1.png)

**Lo que hay.** FalOS arranca en un ordenador virtual, pasa al modo de 64
bits y escribe en la pantalla. Con colores, con tildes, con ñ, con ¿ y ¡, y
sin reventar cuando llega abajo: todo sube una fila, como en una terminal.

Lee el teclado español entero, con mayúsculas, bloqueo de mayúsculas, la ñ,
la ç y la tecla de la tilde: ´ y después a da á. Y lo que escribes hace algo:

![Las órdenes de FalOS](capturas/dia-1-ordenes.png)

- `ayuda`: lo que sabe hacer.
- `limpia`: deja la pantalla en blanco.
- `hora`: la hora del reloj del ordenador.
- `colores`: los 16 colores de la pantalla.
- `encendido`: cuánto lleva encendido.
- `reinicia`: vuelve a arrancar.

**Lo que se aprende.** En modo texto la pantalla no es un aparato al que se
le piden cosas: es memoria. Desde la dirección `0xB8000` hay 80 por 25
casillas de dos bytes, la letra y su color. Lo que se escribe ahí sale en el
monitor. El cursor que parpadea, en cambio, no es una casilla: lo dibuja la
tarjeta, y se le dice dónde ponerlo por dos puertos.

El teclado tampoco manda letras. Manda el número de la tecla que se ha
movido, uno al pulsarla y otro al soltarla. Qué letra es cada tecla lo decide
el sistema: la tecla que en un teclado inglés es el punto y coma, en el
español es la ñ, y es el mismo número.

La hora sale de un chip que lleva un reloj con pila desde los años ochenta.
Guarda cada número en BCD: el 59 no se guarda como 59 sino como `0x59`, una
cifra en cada mitad del byte.

**Lo que costó.** Las tildes, dos veces. Fal guarda los textos en UTF-8,
donde una "á" ocupa dos bytes, y la pantalla habla la página de códigos 437
de IBM, de 1981, donde ocupa uno. Hay que traducir letra a letra, y la 437
no tiene mayúsculas con tilde salvo la É. Y en el teclado la tilde no es una
letra: es una tecla que no escribe nada y cambia la siguiente.

**Y luego, a dormir.** La primera versión esperaba las teclas preguntando sin
parar si había llegado alguna, y eso tenía un núcleo del procesador al 99 %
sin hacer nada. Ahora el teclado avisa él: una interrupción. FalOS duerme, y
cuando pulsas una tecla el procesador lo despierta, apunta la tecla y vuelve
a dormir. Lo mismo el reloj, cien veces por segundo, que es de donde sale
`encendido`.

Medido con QEMU parado 8 segundos sin tocar nada: **del 99 % al 2 %** de un
núcleo.

Para esto Fal ha tenido que aprender a atender interrupciones: una función
normal de Fal se pone a atender una, y el compilador le añade lo que guarda y
devuelve los registros para que el programa interrumpido no note nada.

**Lo que costó.** Al encender, el controlador de interrupciones manda las de
los aparatos a los números 8 a 15, que son los mismos que usa el procesador
para sus propias excepciones. Si activas las interrupciones sin moverlas, el
primer tic del reloj parece un "fallo doble" del procesador. Hay que
remapearlo antes, a partir del 32. Y otra trampa: entre mirar si hay teclas
y dormirse, puede llegar una justo en medio, y entonces el sistema se queda
dormido con una tecla esperando. Se evita cerrando las interrupciones antes
de mirar y abriéndolas en la misma instrucción que duerme.

**Y AltGr.** Con AltGr salen @, #, |, \, [, ], { y } (y ~ y ¬).

![AltGr en FalOS](capturas/dia-1-altgr.png)

Lo curioso es que AltGr no es una tecla nueva: es el Alt de la derecha, y el
teclado lo distingue del de la izquierda mandando antes un byte de aviso,
`0xE0`, que dice "lo siguiente es de las teclas que se añadieron después".
Las flechas y media teclado numérico llegan igual, y antes FalOS no conocía
ese aviso: leía solo el segundo byte. La / del teclado numérico salía como un
guion, porque comparte número con la tecla del guion. Ahora sale la /, y el
Intro del teclado numérico ejecuta la orden como el otro.

El € no sale: la página de códigos 437 es de antes del euro.
