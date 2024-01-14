subSeq="submit-seq-n-job.o"
subCuda="submit-CUDA_Sort.o"
subCL="submit_cl.o"
i=1
for f in $(ls $subSeq*); do 
	mv $f "f$i.txt"
	i=`expr $i + 1`
done
