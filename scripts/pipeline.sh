mkdir -p res/genome
wget -O res/genome/ecoli.fasta.gz ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

#Descomprimir el genoma de E.coli
gunzip res/genome/ecoli.fasta.gz

# indexing code goes here
echo "Running STAR index..."
    mkdir -p res/genome/star_index
    STAR --runThreadN 4 --runMode genomeGenerate --genomeDir res/genome/star_index/ --genomeFastaFiles res/genome/ecoli.fasta --genomeSAindexNbases 9

for sampleid in $(ls data/*.fastq.gz | cut -d"_" -f1 | cut -d"/" -f2 | sort | uniq)

do

	#First, execute QC analysis
echo "Running FastQC..."
    mkdir -p out/fastqc
    fastqc -o out/fastqc data/${sampleid}*.fastq.gz

	#Cut the adapters
echo "Running cutadapt..."
    mkdir -p log/cutadapt
    mkdir -p out/cutadapt
    cutadapt -m 20 -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -o out/cutadapt/${sampleid}_1.trimmed.fastq.gz -p out/cutadapt/${sampleid}_2.trimmed.fastq.gz data/${sampleid}_1.fastq.gz data/${sampleid}_2.fastq.gz > log/cutadapt/${sampleid}.log

	#Align the genome with the reference genome 
echo "Running STAR alignment..."
    mkdir -p out/star/${sampleid}
    STAR --runThreadN 4 --genomeDir res/genome/star_index/ --readFilesIn out/cutadapt/${sampleid}_1.trimmed.fastq.gz out/cutadapt/${sampleid}_2.trimmed.fastq.gz --readFilesCommand zcat --outFileNamePrefix out/star/${sampleid}/
    echo
done

	#Generate a report with MultiQC
echo "Running MultiQC..."
	multiqc -o out/multiqc /home/vant/testsim

	#Conda environment information
echo "Conda environment saved"
	mkdir envs 
	conda env export > envs/rna-seq.yaml



