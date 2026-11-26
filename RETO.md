# El reto

FalOS promete que ningún programa sale a la red, guarda en el disco ni ve tus
teclas sin que tú lo digas, y que cada uno vive en su caja. Una promesa así no
vale nada hasta que alguien intenta romperla y no puede. Este es el sitio para
intentarlo.

Si lo consigues, tu nombre va abajo del todo, en el [diario](DIARIO.md) el día
que lo arregle y en el vídeo de ese día.

## Qué hay que conseguir

Un programa que corra en FalOS y consiga una de estas cosas:

1. **Leer lo que no es suyo.** Lo que guardó otro programa, aunque esté cifrado, o
   las teclas que escribes en otra ventana.
2. **Salir a la red sin permiso.** Mandar una sola trama sin que escribas `deja`, o
   hablar con una dirección distinta de la que le dejaste.
3. **Guardar sin permiso.** Escribir en el disco sin tu `deja`, o pisar lo que
   guardó otro programa.
4. **Leer el portapapeles.** Ver lo que copiaste con Ctrl+C sin que tú se lo pegues.
5. **Salirse de su caja y seguir vivo.** Tocar memoria que no es suya, o un aparato
   (un puerto, la pantalla, el disco), sin que FalOS lo cierre.
6. **Tirar FalOS entero.** Que se cuelgue o reviente todo, no solo tu programa.
   Que la consola deje de hacerte caso también cuenta.
7. **Saltarse el cerrojo.** Con la pantalla bloqueada, ver una tecla, el
   portapapeles o lo que había en la pantalla, o quitar el bloqueo sin la contraseña.
8. **Abrir el pendrive.** Sacar algo de lo que FalOS guardó en un pendrive sin su
   contraseña, o cambiarlo sin que se entere. Este no necesita un programa: vale
   con los bytes del pendrive, en tu ordenador. Qué hay en cada byte lo cuenta
   [PENDRIVE.md](PENDRIVE.md).

Y una más, que vale igual: **que FalOS te mienta.** Que la pregunta de permiso
diga otro programa, otro sitio u otra cantidad de bytes de lo que de verdad pasa,
o que el registro no apunte algo que pasó.

## Lo que no vale

- **Cambiar FalOS.** Ni [sistema.fal](sistema.fal), ni
  [controladores/](controladores), ni lo que hace
  [haz_disco.fal](haz_disco.fal) con los demás programas. Tu programa entra en
  [programas/](programas) como uno más.
- **Hacerlo desde fuera.** El monitor de QEMU, un depurador, leer `disco.img` desde
  tu ordenador o abrir el portátil. FalOS no puede defenderse de quien tiene la
  máquina en la mano, y no lo promete. La única excepción es el punto 8. Y ahí no
  vale probar contraseñas de una lista hasta acertar una corta, ni cambiar el
  FalOS del pendrive y esperar a que el dueño teclee la suya.
- **Que le dejes tú.** Si escribes `deja`, o le pegas tu contraseña a un programa
  que te la pide, se la has dado. Lo que sí vale es engañarte para que creas que
  dejas otra cosa.
- **Lo que ya está contado.** El [README](README.md#lo-que-no-cubre) dice lo que
  FalOS no cubre, como que el programa del teclado ve todo lo que escribes. Si
  consigues más de lo que dice ahí, eso sí vale.

## Cómo empezar

En [Releases](https://github.com/NissanBoss/FalOS/releases/latest) está la imagen
que hace GitHub después de pasar todas las pruebas, y el compilador de Fal con el
que se hizo, para Linux, Windows y Mac. No hace falta Go.

```bash
git clone https://github.com/NissanBoss/FalOS
cd FalOS
```

Escribe tu programa en `programas/`, por ejemplo `programas/mio.fal`, y haz el
disco con él dentro:

```bash
fal haz_disco.fal
```

```bash
qemu-system-x86_64 -cpu max -kernel sistema.bin -drive file=disco.img,format=raw,if=ide -nic user,model=ne2k_pci
```

`sistema.bin` es el de la release, o el tuyo con `fal --nucleo sistema.fal`.
Dentro de FalOS, `lanza mio`. En Mac, el compilador no va firmado: quítale la
cuarentena con `xattr -d com.apple.quarantine fal-mac`.

También vale hacer el programa byte a byte, sin compilador. FalOS mira la
cabecera antes de creérsela: [haz_disco.fal](haz_disco.fal) fabrica así
`gigante.prg`, `desborda.prg`, `fuera.prg` y `corto.prg`, y ninguno pasa.

## Lo que tiene un programa

Corre en el anillo 3, con su memoria y nada más. En sus tablas están sus
páginas y siete del núcleo, las justas para entrar y volver, y `tablas N` te
las cuenta. Lo que escribe con `escribe` sale en su ventana. Para lo demás tiene una mesa de 4.096 bytes que comparte con
el núcleo:

```
mesa es region con 807395328 y 4096
```

Y pide cosas con `llama_al_sistema con N y a y b`, que devuelve un número. Si el
núcleo se lo niega, el número es negativo.

| N | Qué pide |
|---|---|
| 0 | Cerrarse, con el código `a`. |
| 1 | Escribir la letra `a` en su ventana. |
| 2 | Dejar su turno. |
| 3 | Los tics de 10 ms desde que arrancó FalOS. |
| 4 | Dormir `a` tics. |
| 5 | Mandar el número `b` al programa de la llave `a` y esperar la respuesta. La llave solo abre si escribiste `permite`. |
| 6 | Esperar a que alguien le pregunte. |
| 7 | Contestar `a` a quien le preguntó. |
| 8, 9 y 10 | Solo para los controladores. A cualquier otro se le niega. |
| 11 | La siguiente tecla que le ha llegado, o 0. |
| 12 | Cambiar su ventana a `a` columnas y `b` renglones. |
| 13 | Pintar en su ventana: `a` es renglón por 256 más columna, `b` es color por 256 más letra. |
| 14 | Guardar en su archivo `b` bytes de la mesa, desde el `a`. Hasta 464. Espera a tu `deja`. |
| 15 | Leer su archivo en la mesa, desde el `a`. |
| 16 | Dos megas más de memoria, una vez. |
| 17 | Mandar un mensaje UDP: en la mesa, desde el `a`, la IP en 4 bytes, el puerto en 2 y los datos. La IP 0.0.0.0 con el puerto 53 es el DNS de la red en la que estés. Espera a tu `deja`, y la respuesta vuelve al mismo sitio, desde el `a`. |
| 18 | Solo la consola: pedirle una orden a FalOS. A cualquier otro se le niega. |
| 19 | Solo el controlador USB: decir en qué puerto hay un teclado. A cualquier otro se le niega. |
| 20 | Solo el controlador USB: decir en qué puerto hay un pendrive y cuánto cabe en él. A cualquier otro se le niega. |
| 21 | Añadir `b` bytes de la mesa, desde el `a`, al programa que está preparando. Hasta 64 KB en total. |
| 22 | Estrenar lo preparado con el nombre que hay en la mesa, desde el `a`, de `b` letras: minúsculas sin tilde, cifras, `-` y `_`, hasta 16. No vale el nombre de uno del disco ni el de uno que estrenó otro. Vive en memoria, nace sin permisos, y 14 y 15 se le niegan. |

Del 23 en adelante no hay nada, y pedirlo cuenta como rechazado.

Lo más rápido es empezar por los que ya lo intentan y FalOS para: `espia`,
`ladron`, `fisgon`, `curioso`, `cambiazo`, `escucha`, `chivato`, `disfraz`,
`impostor`, `tumba`, `trampa`, `mandon` y `falsario`, todos en [programas/](programas).

## Cómo avisar

Abre un [aviso con la plantilla del reto](https://github.com/NissanBoss/FalOS/issues/new?template=reto.yml):
el programa, cómo lo arrancaste y qué pasó. Es público a propósito: que se vea
qué se rompe y cómo se arregla.

## Quién lo ha roto

Nadie de fuera todavía. Los primeros los encontré yo, el día 18, mirando FalOS
como lo miraría quien quiere romperlo, y los arreglé el día 19:

- **Tirar FalOS entero, con una llamada.** Guardar, leer o conectar desde el
  final de la memoria hacía una suma que no cabía, y el núcleo se paraba
  entero. `tumba` lo intenta.
- **Que FalOS mienta.** Una ventana podía tapar la pregunta de permiso y pintar
  otra encima, con otro programa y otro sitio. Ahora las ventanas se esconden
  mientras FalOS pregunta, y el teclado vuelve a la consola. `trampa` lo intenta.
- **Leer lo que no es suyo, sin RDRAND.** La llave salía de la hora, y se
  adivinaba en 3 segundos con un disco copiado. Ahora sale de cuándo pulsas
  cada tecla.
- **Un nombre repetido en el disco** heredaba la clave y los permisos del de
  verdad. Ahora `haz_disco` no lo deja, y FalOS no abre ninguno de los dos.
