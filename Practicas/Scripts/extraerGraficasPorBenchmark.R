library(plotrix)
library(ggplot2)
library(reshape2)
library(plyr)

argumentos <- commandArgs(trailingOnly = TRUE)

datosRaw <- ldply( argumentos[1:3], function(archivo){
	data.frame(read.csv(archivo, header=TRUE), ID=archivo)
})

datos <- melt(datosRaw,id.vars="ID")

datosResumidos <- ddply(
	datos,
	c("ID","variable"),
	summarise,
	mean=mean(value),
	sd=sd(value),
	se=std.error(value)
)

campos <- unique(datosResumidos$variable)

graficos <- lapply(campos, function(campo){

	ggplot(subset(datosResumidos, variable==campo), aes(x=variable, y=mean, fill=ID)) + 

	    geom_bar(position=position_dodge(), stat="identity") +

	    geom_errorbar(
	    	aes(ymin=mean-se, ymax=mean+se),
	        width=.2,                    # Width of the error bars
	        position=position_dodge(.9)
	    ) +

	    xlab("Configuraciones") +
	    ylab("Valores") +

		scale_x_discrete(labels="") +

    	ggtitle(gsub("\\."," ",campo)) +

	    scale_fill_hue(name="Configuración", # Legend label, use darker colors
                   labels=c("Servidor único", "Granja web nginx", "Granja web haproxy"))

	prefijo <- argumentos[4]
	ggsave(sprintf("../IMGs/%s/%s%s.png",prefijo,prefijo,campo))

})

#"Time taken for tests","Failed requests","Requests per second","Time per request"
#"Transactions per second", "Average response time (seconds)", "Maximum response time"
#"Availability","Elapsed time","Response time","Transaction rate","Failed transactions","Longest transaction"