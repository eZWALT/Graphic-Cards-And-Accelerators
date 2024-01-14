# Version secuencial

- Para ejecutar el experimento donde se cambia el valor de size_i
```bash
make seq
sbatch Seq_n_sizei_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subSeq en el for-loop
python3 seqMean.py
``` 

- Para ejecutar el experimento donde se cambia el valor de n
```bash
make seq
sbatch Seq_sizei_n_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subSeq en el for-loop
python3 seqMean.py
```

# CUDA
## Primer Merge
- Para ejecutar el experimento donde se cambia el valor de size_i
```bash
make cudaFirst
sbatch FirstMerge_n25_sizei_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subCuda en el for-loop
python3 mean.py
```

- Para ejecutar el experimento donde se cambia el tamaño de bloque
```bash
make cudaFirstBlock
sbatch FirstMerge_n_sizei_BlockSize_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subCuda en el for-loop
python3 mean.py
```
- Para ejecutar el experimento donde se cambia el valor de n
```bash
make cudaFirstBlock
sbatch FirstMerge_sizei_BlockSize_n_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subCuda en el for-loop
python3 mean.py
```

## PathMerge
- Para ejecutar el experimento donde se cambia el valor de size_i
```bash
make cudaPath
sbatch PathMerge_n25_sizei_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subCuda en el for-loop
python3 mean.py
```

- Para ejecutar el experimento donde se cambia el tamaño de bloque
```bash
make cudaPathBlock
sbatch PathMerge_n_sizei_BlockSize_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subCuda en el for-loop
python3 mean.py
```
- Para ejecutar el experimento donde se cambia el valor de n
```bash
make cudaPathBlock
sbatch PathMerge_sizei_BlockSize_n_job.sh #Lanzar 5 veces
./changeName.sh #Usar la variable $subCuda en el for-loop
python3 mean.py
```
# OpenCL
- Los tres experimentos se ejecutan a la vez
```bash
make opencl
sbatch CLjob.sh
```

Los resultados se ponene en una carpeta (consultar script para más detalles)
