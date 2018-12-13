import argparse
import os
import os.path
import glob
from os import mkdir
from os import makedirs

# Define las rutas por defecto. Entrada es el directorio local. Para la salida crea un directorio nuevo dentro de la ruta de entrada.
path = os.getcwd()

#print ("El directorio de salida por defecto es '%s'" % default_outpath)

# Se listan los argumentos para la funcionalidad del script
parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
				description='Create a Master Table from Unprocessed genomic data')
parser.add_argument('-i', '--input', metavar='', default=path, help='path to the root folder for unprocessed bam files. (default: ./)')
parser.add_argument('-o', '--output', metavar='', default=path, help='path to the output folder for the processed bam files. (default: ./Output)' )
parser.add_argument('-v', '--version', action='version', version='Master Table Creator v1.0 Dec. 2018')
args = parser.parse_args()

# Revisa si los atributos entregados son validos
try:
	os.chdir(args.input)
except:
	print("ERROR: The input path provided is invalid ('%s')" % args.input)

try:
        os.chdir(args.output)
except:
        print("ERROR: The output path provided is invalid ('%s')" % args.output)

# Crea la carpeta de salida y revisa si existe
try:
	os.mkdir(args.output + '/Output')
except:
	print("ERROR: The ./Output folder could not be created. Check the output path.")

# Entra en la carpeta de los bam y genera Control_Cambios_V1.txt
cambiosv1 = open('Control_Cambios_V1.txt', 'w')

os.chdir(args.input)
for root, dirs, files in os.walk(args.input):
  for file in files:
    if file.endswith(".bam"):
      print(os.path.join(root, file), file=cambiosv1)

