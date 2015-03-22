#Práctica 2
##Clonar la información de un sitio web

### Copia mediante ssh

Para transferir directorios de una máquina a otra puede ser de utilidad enviarlos como archivos empaquetados. Esto se puede conseguir usando la siguiente órden:

```
tar czf - /home/alejandro/dir/ | ssh alejandro@172.168.1.102 'cat > ~/tar.gz'
```

Así, conseguimos empquetar el directorio /home/alejandro/dir/ de la máquina local y enviar el paquete tar generado a la sálida estándar (con el parámetro `-`). La salida estándar la redirigimos a ssh, de manera que el comando que se la pasa, `cat > ~/tar.gz` lee 
el paquete del pipe y lo escribe en el fichero ~/tar.gz del usuario `alejandro` en la máquina `172.168.1.102`

### Utilidad rsync
La utilidad `rsync` ya estaba instalada en el sistema, así que para probarla sólo ha sido necesario ejecutar la órden descrita en el guión:

```
rsync -avz -e ssh root@172.168.1.101:/var/www/ /var/www/
```
Las diferentes opciones utilizadas son las siguientes:

* **-a** Modo de archivo
* **-v** Genera una salida más descriptiva
* **-z** Permite la compresión de los archivos durante la transferencia
* **-e** Permite especificar la shell remota que se usará, en este caso ssh
* **root@172.168.1.101:/var/www/** Indica el origen del directorio remoto a copiar, indicado como _usuario_@_maquina-origen_:_directorio-origen_
* **/var/www/** Directorio local donde se guardarán los datos copiados.

Al ejecutar este comando es necesario introducir la contraseña del usuario root de la máquina remota. Al hacerlo, puede ocurrir que se deniegue el acceso. La forma de arreglarlo es editar, en la máquina remota, el archivo de configuración de ssh,  
`/etc/ssh/sshd_config`, modificando la línea 
```
PermitRootLogin without-password
```
a lo siguiente:
```
PermitRootLogin yes
```

Tras reiniciar ssh con `sudo service ssh restart` y una vez que se ejecuta la órden, la salida es algo parecido a esto:

```
receiving incremental file list

sent 21 bytes  received 119 bytes  31.11 bytes/sec
total size is 11,557  speedup is 82.55
```

Podemos comprobar que todo ha ido bien inspeccionando el directorio /var/www/ de la máquina donde se ha hecho la copia. Ejecutando la órden `ls -laR /var/www/` observamos que el contenido es igual al de la máquina origen:

```
/var/www/:
total 12
drwxr-xr-x  3 root root 4096 mar 21 02:00 .
drwxr-xr-x 13 root root 4096 mar 21 01:19 ..
drwxr-xr-x  2 root root 4096 mar 21 02:00 html

/var/www/html:
total 24
drwxr-xr-x 2 root root  4096 mar 21 02:00 .
drwxr-xr-x 3 root root  4096 mar 21 02:00 ..
-rw-r--r-- 1 root root    47 mar 21 01:42 hola.html
-rw-r--r-- 1 root root 11510 mar 21 01:19 index.html
```

La utilidad rsync tiene una amplia funcionalidad. Por ejemplo:

* Podemos excluir de la copia ciertos directorios con la opción `--exclude=_directorio-a-excluir`
* Podemos indicar que la copia sea exacta, incluso archivos que hayan sido borrados desde el último clonado, con la opción `--delete`

### Acceso sin contraseña

Para poder hacer cualquier tipo de operación a través de ssh sin necesidad de introducir la contraseña cada vez, es necesario configurar un par de claves ssh. Para generar este par, en la máquina secundaria ejecutamos

```
ssh-keygen -t dsa
```

Tras pedir el nombre del par de claves y el directorio donde se guardará, pide configurar una contraseña, que podemos dejar en blanco si queremos ejecutar los comandos ssh sin tener que usar contraseñas. Cuando se ha introducido toda esta información, la salida 
es como 
la siguiente:

```
Generating public/private dsa key pair.
Your identification has been saved in /root/.ssh/id_dsa.
Your public key has been saved in /root/.ssh/id_dsa.pub.
The key fingerprint is:
34:c1:93:dc:c9:ae:d3:1c:a8:72:93:6a:50:66:a6:e4 root@ubuntuServer2
The key's randomart image is:
+--[ DSA 1024]----+
|       o.+ .     |
|        =.+      |
|        o+       |
|  . =  ...o      |
| o *   oS+ .     |
|  E . = o o      |
|   . + . .       |
|    o            |
|   .             |
+-----------------+
```

En este caso, dejando todos los valores por defecto, se generan dos archivos en el directori `~/.ssh/`:
* **id_dsa.pub** Clave pública, que se enviará a la máquina remota
* **id_dsa** Clave privada, que sólo conoce la máquina local

Para enviar la clave pública a la máquina remota, se puede hacer con un comando propio de ssh, de la siguiente forma:

```
ssh-copy-id -i .ssh/id_dsa.pub root@172.168.1.101
```

cuya salida es la siguiente:

```
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@172.168.1.101'"
and check to make sure that only the key(s) you wanted were added.

/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new kets
root@172.168.1.101's password:
```

Tras ingresar la contraseña root de la máquina remota, podemos comprobar que todo ha salido bien conectándonos por ssh y viendo que no nos pide la contraseña. Lo hacemos con el siguiente comando, con el que especificamos el usuario con el que conectarnos a través 
de la opción -l

```
ssh 172.168.1.101 -l root
```

### Crontab

Para programar tareas con un intervalo muy concreto, podemos especificarlas directamente en el archivo /etc/crontab con la sintaxis

```
MINUTO HORA DIA-MES MES DIA-SEMANA USUARIO COMANDO
```

De esta manera tendremos control absoluto de la programación temporal de la tarea.
Si queremos algo más general, como tareas que se ejecuten cada hora, cada día, cada semana o cada mes, podemos simplemente crear un script en uno de los siguientes directorios:

* `/etc/cron.hourly/`
* `/etc/cron.daily/`
* `/etc/cron.weekly/`
* `/etc/cron.monthly/`

Por ejemplo, para establecer que cron ejecute cada hora la sincronización de la carpeta /var/www entre las dos máquinas, podemos crear un script llamado `sync-www` en el directorio `/etc/cron.hourly` con el siguiente contenido:

```bash
#!/bin/bash

rsync -avz -e ssh root@172.168.1.101:/var/www/ /var/www/
```

Una vez creado, es necesario darle permisos de ejecución con el comando

```
chmod +x /etc/cron.hourly/sync-www
```

Así, tendremos programada la sincronización cada hora. Como, además, hemos configurado las claves ssh, no será necesario introducir la contraseña y la tarea se realizará automáticamente sin necesidad de interacción con el administrador.


----
Alejandro García Montoro.
