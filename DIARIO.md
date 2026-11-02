# Diario de FalOS

Un día, un paso. Lo más nuevo, arriba.

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
