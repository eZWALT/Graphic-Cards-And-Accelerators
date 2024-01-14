import re

#Este es el archivo que se ha usado para hacer la media de los 5 tiempos


#Estos nombres se obtienen de ejecutar el script changeName.sh
f = open("f1.txt", "r");
f2 = open("f2.txt", "r");
f3 = open("f3.txt", "r");
f4 = open("f4.txt", "r");
f5 = open("f5.txt", "r");

#Esto son las muestras que tomas por modo
samples = 27 - 15 + 1

#NO TOCAR
samples = samples * 4 + 1 
j = 1
i = 1
for (l1,l2,l3,l4,l5) in zip(f,f2,f3,f4,f5):

	if j % samples == 0:
		print(l1)
		j = 1
		continue

	if i % 4 == 0:

		l = re.findall("[0-9]+[.][0-9]+", l1)
		l2 = re.findall("[0-9]+[.][0-9]+", l2)
		l3 = re.findall("[0-9]+[.][0-9]+", l3)
		l4 = re.findall("[0-9]+[.][0-9]+", l4)
		l5 = re.findall("[0-9]+[.][0-9]+", l5)

		res = (float(l[0]) + float(l2[0]) + float(l3[0]) + float(l4[0]) + float(l5[0])) / 5.0
		ress = (float(l[1]) + float(l2[1]) + float(l3[1])+ float(l4[1]) + float(l5[1])) / 5.0
		resss = (float(l[2]) + float(l2[2]) + float(l3[2])+ float(l4[2]) + float(l5[2])) / 5.0
		print(f"Ancho de Banda HtD: {res:.6f} GB/s, Ancho de Banda Kernels: {ress:.6f} GB/s, Ancho de Banda DtH: {resss:.6f} GB/s")

		i = 0

	elif i % 3 == 0:
		n1 = float(re.search("[0-9]+[.][0-9]+", l1).group(0))
		n2 = float(re.search("[0-9]+[.][0-9]+", l2).group(0))
		n3 = float(re.search("[0-9]+[.][0-9]+", l3).group(0))
		n4 = float(re.search("[0-9]+[.][0-9]+", l4).group(0))
		n5 = float(re.search("[0-9]+[.][0-9]+", l5).group(0))
		res = (n1 + n2 + n3 + n4 + n5) / 5.0
		print(f"Tiempo Kernels: {res:.6f} ms")

	else:
		print(l1.strip())


	i = i + 1
	j = j + 1
