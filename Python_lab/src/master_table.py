import argparse
import os
import os.path
import glob
import sys
import re
from os import mkdir
from os import makedirs

# Define las rutas por defecto. Entrada es el directorio local. Para la salida crea un directorio nuevo dentro de la ruta de entrada.
path = os.getcwd()

#print ("El directorio de salida por defecto es '%s'" % default_outpath)

# Se listan los argumentos para la funcionalidad del script
parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
				description='Create a Master Table from Unprocessed genomic data')
parser.add_argument('-i','--input', metavar='', default=path, help='path to the root folder for unprocessed bam files. (default: ./)')
parser.add_argument('-o','--output', metavar='', default=path, help='path to the output folder for the processed bam files. (default: ./Output)' )
parser.add_argument('-t','--temp-files', metavar='', default='F', help='choose if you want to keep the temp and intermediary files; useful for debugging. (default: F or False) ')
parser.add_argument('-v','--version', action='version', version='Master Table Creator v1.0 Dec. 2018')
args = parser.parse_args()

# Revisa si los atributos entregados son validos
try:
	os.chdir(args.input)
except:
	sys.exit("ERROR: The input path provided does not exist. Check the route and try again.")

try:
        os.chdir(args.output)
except:
	sys.exit("ERROR: The output path provided is invalid or do not have write permisions.")

# Crea la carpeta de salida y revisa si existe
try:
	os.mkdir(args.output + '/Output')
except:
	sys.exit("ERROR: The output folder could not be created or already exist. Check the output path.")

# Entra en la carpeta de los bam y genera Control_Cambios_V1.txt
cambiosv1_path = os.path.join(args.output, 'Output', 'Control_Cambios_V1.txt')
cambiosv1 = open(cambiosv1_path, 'w')

os.chdir(args.input)
for root, dirs, files in os.walk(args.input):
  for file in files:
    if file.endswith(".bam"):
      print(os.path.join(root, file), file=cambiosv1)
cambiosv1.close()

# Genera el archivo temporal Control_Cambios_V2.txt
cambiosv2_path = os.path.join(args.output, 'Output', 'Control_Cambios_V2.txt')
cambiosv2 = open(cambiosv2_path, 'w')

f = open(cambiosv1_path, "r")
line = f.readline()
while line:
    line = "".join(line.split("\n"))
    line2 = line.replace("/","_")
    id = line2.split("_")[-2]
    if id is not None:
        if len(id) != 8:
            print(line + "\t" + id + "\t" "NEWID", file = cambiosv2)
        elif id.isdigit() == False:
            print(line + "\t" + id + "\t" + "NEWID", file = cambiosv2)
        else:
            print(line + "\t" + id + "\t" + id, file = cambiosv2)
    line = f.readline()
f.close()
cambiosv2.close()

# Genera el archivo temporal Control_Cambios_V3.txt
cambiosv3_path = os.path.join(args.output, 'Output', 'Control_Cambios_V3.txt')
cambiosv3 = open(cambiosv3_path, 'w')

f = open("/mnt/linux/home/cacerj01/Scripts/Scratch/Python_lab/src/Output/Control_Cambios_V2.txt", "r")
line = f.readline()
while line:
    line = "".join(line.split("\n"))
    idstatus = line.split("\t")[-1]
    if idstatus == "NEWID":
        line2 = line.split("\t")[-2]
        line2 = line2.split("/")[-1]
        id = line2.split("_")[1]
        id = "".join(id.split("-"))
        id = "".join(id.split("R1"))
        id = "".join(id.split("R2"))
            if len(id) == 4:
                if id.startswith("S") == True:
                    id = "10011".join(id.split("S"))
                    print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
                else:
                    id = ['1002', id]
                    id = "".join(id)
                    print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
            elif len(id) == 6:
                id = "10011".join(id.split("S00"))
                print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
            elif len(id) == 8:
                if [str(i) for i in str(id)][-4] == 0:
                    s = [int(i) for i in str(id)]
                    s[4] = '1'
                    id = "".join(map(str,s))
                    print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
            elif len(id) == 9:
                s = str(id)
                id = int(s[-9]+s[2:])
                print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
            elif len(id) == 5:
                if id.startswith("S0") == True:
                    id = "10011".join(id.split("S0"))
                    print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
                else:
                    id = "1002".join(id.split("C"))
                    print(line.split("\t")[0] + "\t" + str(id) + "\t", file = cambiosv3)
            else:
                print(line.split("\t")[0] + "\t" + idstatus, file = cambiosv3)
            line = f.readline()
f.close()
cambiosv3.close()

# 
