#!/bin/bash

function test_apache_benchmark {
	AB_SALIDA=`ab -n 1000 -c 15 http://$1/benchmark.php | grep -E 'Time taken for tests|Failed requests|Requests per second|Time per request' | grep -E -o '[0-9.]*'`

	AB_TIME_TESTS=`echo $AB_SALIDA | cut -d ' ' -f1`
	AB_FAILED=`echo $AB_SALIDA | cut -d ' ' -f2`
	AB_REQ_SECONDS=`echo $AB_SALIDA | cut -d ' ' -f3`
	AB_TIME_REQ=`echo $AB_SALIDA | cut -d ' ' -f4`

	echo "$AB_TIME_TESTS,$AB_FAILED,$AB_REQ_SECONDS,$AB_TIME_REQ" >> $2
	echo
	echo "###############################################"
	echo "# DEBUG: APACHE BENCHMARK TERMINADO           #"
	echo "###############################################"
	echo
}

function test_openwebload {
	OL_SALIDA=`openload -o CSV -l 60 http://$1/benchmark.php 15`
	
	OL_TOTAL_TPS=`echo $OL_SALIDA | cut -d ',' -f3`
	OL_AVG_TIME=`echo $OL_SALIDA | cut -d ',' -f4`
	OL_MAX_TIME=`echo $OL_SALIDA | cut -d ',' -f5`

	echo "$OL_TOTAL_TPS,$OL_AVG_TIME,$OL_MAX_TIME" >> $2

	echo
	echo "###############################################"
	echo "# DEBUG: OPENWEBLOAD TERMINADO                #"
	echo "###############################################"
	echo
}

function test_siege {
	SI_SALIDA=`siege -b -c 15 -t60S -v http://$1/benchmark.php 2>&1 >/dev/null | grep -E 'Availability|Elapsed time|Response time|Transaction rate|Failed transactions|Longest transaction' | grep -E -o '[0-9.]*'`
	
	SI_AVAILABILITY=`echo $SI_SALIDA | cut -d ' ' -f1`
	SI_ELAPSED=`echo $SI_SALIDA | cut -d ' ' -f2`
	SI_RESP_TIME=`echo $SI_SALIDA | cut -d ' ' -f3`
	SI_TRANS_RATE=`echo $SI_SALIDA | cut -d ' ' -f4`
	SI_FAILED_TRANS=`echo $SI_SALIDA | cut -d ' ' -f5`
	SI_LONGEST_TRANS=`echo $SI_SALIDA | cut -d ' ' -f6`

	echo "$SI_AVAILABILITY,$SI_ELAPSED,$SI_RESP_TIME,$SI_TRANS_RATE,$SI_FAILED_TRANS,$SI_LONGEST_TRANS" >> $2

	echo
	echo "###############################################"
	echo "# DEBUG: SIEGE TERMINADO                      #"
	echo "###############################################"
	echo
}

IP_MAQUINA1=172.168.1.101
IP_BALANCEADOR_NGINX=172.168.1.103
IP_BALANCEADOR_HAPROXY=172.168.1.104

IPs=( $IP_MAQUINA1 $IP_BALANCEADOR_NGINX $IP_BALANCEADOR_HAPROXY )

FILES_AB=( ab_servidor.csv ab_nginx.csv ab_haproxy.csv )
FILES_OL=( ol_servidor.csv ol_nginx.csv ol_haproxy.csv )
FILES_SI=( si_servidor.csv si_nginx.csv si_haproxy.csv )

for i in `seq 0 2`
do
	rm ${FILES_AB[$i]} ${FILES_OL[$i]} ${FILES_SI[$i]}
	for j in `seq 1 10`
	do
		test_apache_benchmark ${IPs[$i]} ${FILES_AB[$i]}
		test_openwebload  ${IPs[$i]} ${FILES_OL[$i]}
		test_siege  ${IPs[$i]} ${FILES_SI[$i]}
	done
done
