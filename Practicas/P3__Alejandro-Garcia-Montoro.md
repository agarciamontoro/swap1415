
#Práctica 3

En esta práctica instalaremos dos paquetes para configurar una máquina balanceadora que reparta el tráfico entrante entre los dos servidores que instalamos en la práctica 2.

Por comodidad, instalaremos cada uno de los dos paquetes en dos máquinas virtuales diferentes.

La siguiente tabla indica las diferentes máquinas virtuales instaladas y las IPs que tienen asignadas.

| Máquina             | Hostname           | IP            |
|---------------------|--------------------|---------------|
| Ubuntu Server 1     | ubuntuServer1      | 172.168.1.101 |
| Ubuntu Server 2     | ubuntuServer2      | 172.168.1.102 |
| Balanceador nginx   | balanceadorNginx   | 172.168.1.103 |
| Balanceador haproxy | balanceadorHaproxy | 172.168.1.104 |
| Cliente             | cliente            | 172.168.1.201 |

##Balanceador con nginx

###Instalación

Para instalar el balanceador necesitamos una nueva máquina. Por comodidad, nos basta con clonar una de las máquinas creadas en la práctica 2, asegurándonos de tener marcada la opción "Reinicializar la dirección MAC de todas las tarjetas de red". 

Tras desactivar Apache con la órden `update-rc.d -f apache2 remove` podemos instalar nginx, para lo que debemos realizar unos pasos previos:

**Importar la clave del repositorio**

Ejecutamos las siguientes órdenes:

```
cd /tmp/
wget http://nginx.org/keys/nginx_signing.key
apt-key add /tmp/nginx_signing.key
rm -f /tmp/nginx_signing.key
```

**Añadimos el repositorio al fichero `/etc/apt/sources.list`**

Ejecutamos las siguientes órdenes

```
echo "deb http://nginx.org/packages/ubuntu/ lucid nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/ubuntu/ lucid nginx" >> /etc/apt/sources.list
```

**Instalación del paquete**

Ejecutamos las siguientes órdenes:

```
apt-get update
apt-get install nginx
```

###Configuración

Para configurar nginx, tenemos que editar el archivo `/etc/nginx/conf.d/default.conf`, de manera que quede así:

```
upstream apaches {
	server 172.168.1.101;
	server 172.168.1.102;
}

server{
	listen		80;
	server_name balanceadorNginx;

	access_log /var/log/nginx/balanceadorNginx.access.log;
	error_log /var/log/nginx/balanceadorNginx.error.log;
	root /var/www/;
	
	location /
	{
		proxy_pass http://apaches;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_http_version 1.1;
		proxy_set_header Connection "";
	}
}
```

![Configuración nginx](./IMGs/P3-01-ConfiguracionNginx.png)

### Ejecución

Para que nuestro balanceador empiece a escuchar en el puerto que le hemos indicado, basta con ejecutar la orden `service nginx restart`

Podemos ya probar el funcionamiento de nuestro balanceador. Una manera sencilla de hacerlo es ejecutar repetidamente la orden `curl http://172.168.1.103/hola.html` desde una cuarta máquina cliente. Con esta orden, lo que hacemos es solicitar la página `hola.html` al balanceador (cuya ip es `172.168.1.103`) y vemos que nos muestra alternativamente la de una u otra máquina servidora.

![Round robin nginx](./IMGs/P3-02-RoundRobin.png)

Podemos probar distintas configuraciones. Por ejemplo, podemos dar más importancia a una máquina que à otra, modificando las líneas del upstream del archivo `/etc/nginx/conf.d/default.conf` de manera que queden así:

```
upstream apaches {
	server 172.16.168.130 weight=1;
	server 172.16.168.131 weight=2;
} 
```

Tras ejecutar `service nginx restart` podemos volver a ejecutar nuestro sencillo test con `curl` desde una máquina cliente:

![Roun robin peso nginc](./IMGs/P3-03-RoundRobinPeso.png)

Una configuración más interesante es aquella que a cada IP le asigna el mismo servidor, de manera que aplicaciones que necesiten de informaciones personalizadas puedan trabajar bien. La configuración sería así

```
upstream apaches {
	ip_hash;
	server 172.16.168.130;
	server 172.16.168.131;
} 
```

Y se comporta tal como se espera:

![Asignación por IP](./IMGs/P3-04-ipHash.png)

----------------------------------

##Balanceador con haproxy

###Instalación

Clonamos la máquina del balanceador anterior, asegurándonos de tener marcada la opción "Reinicializar la dirección MAC de todas las tarjetas de red". Tras desinstalar nginx y ajustar la IP de la máquina para que no haya conflictos con las que ya tenemos instaladas, podemos instalar haproxy con la siguiente orden:

```
apt-get install haproxy
```

###Configuración

Para configurar haproxy, tenemos que editar el archivo `/etc/haproxy/haproxy.cfg`, de forma que quede de la siguiente manera:

```
global
	daemon
	maxconn 256

defaults
	mode http
	contimeout	4000
	clitimeout	42000
	srvtimeout	43000

frontend http-in
	bind *:80
	default_backend servers

backend servers
	server m1 172.168.1.101:80 maxconn 32
	server m2 172.168.1.102:80 maxconn 32
```

![COnfiguración haproxy](./IMGs/P3-05-ConfiguracionHaproxy.png)

### Ejecución

Para que nuestro balanceador empiece a escuchar en el puerto que le hemos indicado, basta con ejecutar la orden

```
/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg
```

Podemos ya probar el funcionamiento de nuestro balanceador. Como antes, podemos ejecutar ejecutar repetidamente la orden `curl http://172.168.1.104/hola.html` (*la IP de esta nueva máquina balanceadora es la 172.168.1.104*) desde nuestra máquina cliente. Vemos que, como antes, la respuesta se alterna entre la primera y la segunda máquina.

![Round robin haproxy](./IMGs/P3-06-RoundRobin.png)

Al igual que antes, podemos configurar un balanceo ponderado con el atributo `weight`. Por ejemplo, si queremos, como antes, que se asignen el doble de peticiones a la segunda máquina que las que asignamos a la primera tendremos que configurarla sección backend servers del archivo `/etc/haproxy/haproxy.cfg` para que quede de la siguiente manera:

```
backend servers
	server m1 172.168.1.101:80 weight 1 maxconn 32
	server m2 172.168.1.102:80 weight 2 maxconn 32
```

El efecto que conseguimos, tras ejecutar de nuevo la orden `/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg` es el mismo que logramos con nginx, como se ve en la siguiente captura de
pantalla.

![Round robin ponderado haproxy](./IMGs/P3-07-RoundRobinPesoHaproxy.png)

----
Alejandro García Montoro.
