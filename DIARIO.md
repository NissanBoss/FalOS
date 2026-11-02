# Diario de FalOS

Un día, un paso. Lo más nuevo, arriba.

## Día 1: arrancar y escribir en la pantalla

![FalOS el día 1](capturas/dia-1.png)

**Lo que hay.** FalOS arranca en un ordenador virtual, pasa al modo de 64
bits y escribe en la pantalla. Con colores, con tildes, con ñ, con ¿ y ¡, y
sin reventar cuando llega abajo: todo sube una fila, como en una terminal.

**Lo que se aprende.** En modo texto la pantalla no es un aparato al que se
le piden cosas: es memoria. Desde la dirección `0xB8000` hay 80 por 25
casillas de dos bytes, la letra y su color. Lo que se escribe ahí sale en el
monitor. El cursor que parpadea, en cambio, no es una casilla: lo dibuja la
tarjeta, y se le dice dónde ponerlo por dos puertos.

**Lo que costó.** Las tildes. Fal guarda los textos en UTF-8, donde una "á"
ocupa dos bytes, y la pantalla habla la página de códigos 437 de IBM, de
1981, donde ocupa uno. Hay que traducir letra a letra. Y la 437 no tiene
mayúsculas con tilde salvo la É: la Á sale sin ella.

**Lo que viene.** Leer el teclado.
