# Cómo se guarda en el pendrive

Para quien quiera leerlo con su propio programa, o romperlo. La prueba automática
lo abre desde fuera con un Python que no usa nada de FalOS:
[arranca.yml](.github/workflows/arranca.yml), en el paso "Guardar en el pendrive".

## Dónde

En la imagen hay un archivo, `/boot/guardado.img`, de 36.864 bytes. FalOS lo busca
por su nombre en el sistema de archivos ISO 9660 del pendrive, y mira que empiece
por `FALPENDRIVE1` y un salto de línea. No escribe fuera de él.

| Desde | Mide | Qué es |
|---|---|---|
| 0 | 4.096 | La marca, y ceros. No se escribe nunca. |
| 4.096 | 16.384 | Una copia. |
| 20.480 | 16.384 | La otra. |

Y solo usa el pendrive del que arrancó: compara los 4.096 primeros bytes de
`/boot/disco.img` con los que GRUB dejó en la memoria.

## Una copia

| Desde | Mide | Qué es |
|---|---|---|
| 0 | 8 | `FALPEN01` |
| 8 | 4 | El número de copia, del byte bajo al alto. Vale la mayor que cuadre. |
| 12 | 4 | `CER3` |
| 16 | 16 | La sal de Argon2id, al azar. |
| 32 | 32 | La primera mitad de la huella, para saber si la contraseña es esa. |
| 64 | 32 | La llave, en XOR con la segunda mitad de la huella. |
| 96 | 12 | El número que no se repite de ChaCha20, al azar en cada copia. |
| 108 | 32 | La firma. |
| 140 | 372 | Ceros. |
| 512 | 15.872 | Lo guardado, cifrado. |

La huella son 64 bytes de Argon2id versión 1.3: 19.456 bloques de 1 KiB, 2
pasadas, 1 hilo. La llave tiene 32 bytes, salió del azar y no cambia con la
contraseña.

De la llave salen dos claves: BLAKE2b de 64 bytes, con la llave como clave y el
texto `pendrive:`. Los 32 primeros bytes cifran con ChaCha20 (RFC 8439, empezando
a contar en 1), y los 32 últimos firman. La firma es BLAKE2b de 32 bytes de los
16.384 de la copia, con el hueco de la firma a cero, así que cubre también la
cabecera.

## Lo guardado, ya sin cifrar

28 huecos de 552 bytes, y ceros hasta el final. En cada uno:

| Desde | Mide | Qué es |
|---|---|---|
| 0 | 32 | El nombre del archivo. Si empieza por cero, el hueco está libre. |
| 32 | 2 | Lo que mide, del byte alto al bajo. |
| 34 | 6 | Ceros. |
| 40 | 512 | El archivo. Los de los programas ya vienen cifrados con su propia clave. |

## Escribir

Siempre encima de la copia más vieja. Primero lo cifrado, luego se le pide al
pendrive que lo asiente (SYNCHRONIZE CACHE), después la primera página, con la
cabecera y la firma, y se le pide otra vez. Al final FalOS lo lee entero y lo
compara. Si algo se corta a medias, esa copia no cuadra y queda la otra.

La primera vez que escribe después de enchufarlo, FalOS lee la copia que cree la
última y mira que la firma y el número sean los suyos. Si no lo son, no escribe.
Entre medias, mientras no se desenchufe, se fía de él.
