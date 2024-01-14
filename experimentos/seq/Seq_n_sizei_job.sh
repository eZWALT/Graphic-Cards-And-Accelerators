#!/bin/bash 
### Directivas para el gestor de colas (Las que te comes)
#SBATCH --job-name=seq_n_job 
#SBATCH -D . 
#SBATCH --output=submit-seq-n-job.o%j 
#SBATCH --error=submit-seq-n-job.e%j
#SBATCH -A cuda
#SBATCH -p cuda 
#SBATCH --gres=gpu:1

for i in {1..12}; do
	./seq_sort.exe 25 $i 0
done

echo "==================="

for i in {1..12}; do
	./seq_sort.exe 25 $i 1
done

echo "==================="

for i in {1..12}; do
	./seq_sort.exe 25 $i 2
done

echo "==================="
