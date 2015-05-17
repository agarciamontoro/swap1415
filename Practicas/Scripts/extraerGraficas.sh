NOMBRES=( "servidor.csv", "nginx.csv", "haproxy.csv" )

for PRE in "ab_" "ol_" "si_"
do
	mkdir -p ../IMGs/$PRE
	
	FILE1=../Datos/$PRE"servidor.csv"
	FILE2=../Datos/$PRE"nginx.csv"
	FILE3=../Datos/$PRE"haproxy.csv"

	Rscript ./extraerGraficasPorBenchmark.R $FILE1 $FILE2 $FILE3 $PRE
done

rm Rplots.pdf