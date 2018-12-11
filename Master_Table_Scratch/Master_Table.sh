######################################################################################################################
####Script para generar el control de cambios de los bam incluidos en carpetas "Unprocessed", separados por 	######
####ácido nucléico, y la creacion de la Master Table								######
####						 								######
#### Usage: ./Master_Table.sh {site} {path} 									######
#### site = lab donde se realizó la secuenciación; values = {cemp, gmayor, accamargo}				######
#### path = ruta absoluta a la ubicacion de los bam; ej: /Projects/LungCancer/GMayor/AI-2018/Unprocessed/BAM/ 	######
######################################################################################################################

####Define variables relevantes para el proceso que corresponden al site y al directorio de trabajo####

SITE=$1
DIR=$2

####Lista de todos los BAM en la carpeta Unprocessed, sin considerar “none”. Columnas: “ruta en P700” e “ID"

find $DIR -name "*.bam" | while read r; do 
				ID=$(echo $r | cut -d "_" -f2)
				echo -e "$r\t$ID"
			done | grep -v "none" | sort -nrk2,2 > Control_Cambios_V1.txt

#####Lista las muestras e identifica los ID incorrectos. Columnas: “ruta en P700”, “ID OLD” y “NEWID”, donde NEW ID será cambiado al ID correcto. Las muestras que están buenas, tiene el ID repetido en las columnas 2 y 3####

cat Control_Cambios_V1.txt | while read line; do 
				ID=$(echo $line | cut -f2 -d' ')  
				if [[ -n $(echo $ID | grep -P "^S|^C|^....0|new$|old$") ]] || [[ ${#ID} != 8 ]]; then 
					echo -e "$line NEWID" | sed 's/ /\t/g'
				else 
					echo -e "$line $ID" | sed 's/ /\t/g'
				fi 
			done

#####Igual a V2, pero con las Columnas: “ruta en P700”, “ID OLD” y “NEWID”, donde “NEW ID” ya fue cambiado al ID correcto, y si no necesitaba cambios, “NEWID” es igual a “ID OLD”.######

cat Control_Cambios_V2.txt | while read line; do
        if [[ -n $(echo $line | grep NEWID) ]]; then
                ID=$(echo $line | cut -f2 -d' ')
                LEN=$(echo $ID | awk '{print length($1)}')
                if [ $LEN == 4 ]; then
                        if [[ -n $(echo $ID | grep "^S") ]] ; then
                                NEWID=$(echo $ID | sed 's/S/10011/g')
                                echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                        else
                                NEWID=$(echo $ID | awk '{print "1002"$1}')
                                echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                        fi
                elif [ $LEN == 6 ]
                then
                        NEWID=$(echo $ID | sed 's/S00/10011/g')
                        echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                elif [ $LEN == 8 ]
                then
                        NEWID=$(echo $ID | sed 's/./1/5')
                        echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                elif [ $LEN == 9 ]
                then
                        NEWID=$(echo $ID | sed 's/10002/1002/g')
                        echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                elif [ $LEN == 5 ]
                then
                        if [[ -n $(echo $ID | grep "^S0") ]] ; then
                                NEWID=$(echo $ID | sed 's/S0/10011/g')
                                echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                        else
                                NEWID=$(echo $ID | sed 's/C/1002/g')
                                echo -e "$line" | sed "s/NEWID/"$NEWID"/g"
                        fi

                fi

        else

                echo -e "$line"

        fi
done

#####Esta lista es igual a V3, pero se le agrego el valor de md5sum y el número de reads totales (output de samtools flagstat). Columnas: “BAM”: ruta en los P700; “MD5SUM”: hash MD5 del bam; “READS”: número de reads totales; “OLD_ID”: ID original; “NEW_ID”: ID modificado######

cat Control_Cambios_V3.txt | while read line; do 
	BAM=$(echo $line | awk '{print $1}')
	OLDID=$(echo $line | awk '{print $2}')
	NEWID=$(echo $line | awk '{print $3}')
	MD5=$(md5sum $BAM | awk '{print $1}')
	READS=$(samtools flagstat $BAM | head -n1 | cut -d' ' -f1)
	echo -e "$BAM\t$MD5\t$READS\t$OLDID\t$NEWID\t"
done  > Control_Cambios_V4.txt

#####Este archivo es el mismo que el “Files_PGM_GMayor_final.txt”, pero se le agregó una columna al final que contiene el valor de MD5SUM. 	
#Columnas: 																	
#	1)Nombre de la corrida															
#	2)Ruta en PGM del archivo barcodes.json de la corrida
#	3)Ruta en PGM del archivo de coverage analysis (results.json) de la corrida
#	4)ID original de la muestra
#	5)Barcode de la muestra
#	6)Numero de reads totales del BAM
#	7)Ruta en PGM del archivo BAM original
#	8)MD5SUM																

cat Files_PGM_GMayor_final.txt | sed ‘s/bamno-BAMFile/bam/’ | while read line; do 
								if [[ -n $(echo $line | grep "no-BAMFile") ]]; then 
									echo -e $line”\t”no-BAMFile
								else 
									BAM=$(echo $line | cut -f7 -d' ')
									MD5=$(md5sum $BAM | awk '{print $1}')
									echo -e "$line\t$MD5"
								fi
							done > Files_PGM_GMayor_final_MD5SUM.txt


#####Esta tabla se generó cruzando la información contenida en Files_PGM_GMayor_final_MD5SUM.txt y Control_Cambios_V4.txt, utilizando las columnas OLD_ID y MD5SUM como identificadores para el cruce#####

merge_tables.R

#####Correción de ID de los nombres de los archivos y dentro del header del BAM#####
awk 'NR>1{print $0}' Master_Table_GMayor.txt | grep -Ev "no\-BAMFile|none|JUm1|Control" | while read line ; do

ID_OLD=$(echo $line | awk '{print $2}')
ID_NEW=$(echo $line | awk '{print $3}')
BAM=$(echo $line | awk '{print $9}')
OLDNAME=$(basename $BAM)
NEWNAME=$(basename $BAM | sed "s/_"$ID_OLD"_/_"$ID_NEW"_/g")

echo "Procesando archivo $BAM"

        if [[ -n $(echo $BAM | grep "/DNA/") ]]; then
                if [ $ID_OLD == $ID_NEW ]; then
                        cp $BAM ./tmp/DNA
                else
                        samtools view -H $BAM > header.sam
                        sed "s/SM:"$ID_OLD"/SM:"$ID_NEW"/g" header.sam > header_corrected.sam
                        samtools reheader header_corrected.sam $BAM > ./tmp/DNA/$NEWNAME
                fi
        else
                if [ $ID_OLD == $ID_NEW ]; then
                        cp $BAM ./tmp/RNA
                else
                        samtools view -H $BAM > header.sam
                        sed "s/SM:"$ID_OLD"/SM:"$ID_NEW"/g" header.sam > header_corrected.sam
                        samtools reheader header_corrected.sam $BAM > ./tmp/RNA/$NEWNAME

                fi
        fi
done


