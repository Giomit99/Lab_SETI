+#!/bin/bash

set -e

declare -a arr=("tcp" "udp")
readonly DataDir='../data' 
declare -a L
declare -a B
declare -a N1	#NB1
declare -a N2	#NB2
declare -a T_N_1	#D1
declare -a T_N_2	#D2
declare -a Denominatore


for ProtocolName in "${arr[@]}"
do
    echo -e "\e[96mProtocollo\e[0m: $ProtocolName"
    declare InputFile="${DataDir}/${ProtocolName}_throughput.dat"
    declare OutputPngFile="${DataDir}/${ProtocolName}_BandaLatenza.png"
    declare OutputDatFile="${DataDir}/${ProtocolName}_ritardo.dat"

    if [ -e $OutputDatFile ] 
    then
        rm $OutputDatFile $OutputPngFile -f 
    fi
    
	# estraggo dati:
    N1=$(head -n 1 ${DataDir}/${ProtocolName}_throughput.dat | cut -d' ' -f1)
 
    T_N_1=$(head -n 1 ${DataDir}/${ProtocolName}_throughput.dat | cut -d' ' -f2)
    
    N2=$(tail -n 1 ${DataDir}/${ProtocolName}_throughput.dat | cut -d' ' -f1)

    T_N_2=$(tail -n 1 ${DataDir}/${ProtocolName}_throughput.dat | cut -d' ' -f2)
    
    #calcolo le relative costanti
    echo 'Calcolo le relative costanti'
    # il delay è legato al thorughtput medio e al numero di byte dalla formula T*D=N -> D=N/T
    DelayMin=$(bc <<<"scale=20;var1=${N1};var2=${T_N_1};var1 / var2")
    DelayMax=$(bc <<<"scale=20;var1=${N2};var2=${T_N_2};var1 / var2")
    Denominatore=$(bc <<< "scale=20;${DelayMax}-${DelayMin}")
    
    L=$(bc <<< "scale=20;var1=${DelayMin}*${N2};var2=${DelayMax}*${N1};var3=var1-var2;var3/${Denominatore}")
    B=$(bc <<< "scale=20;var1=${N2}-${N1};var1/${Denominatore}")

    echo bandwiwidth: $B
    echo latency: $L
    #stampa i valori Numero_byte e Latenza sul file .dat
    echo 'stampo i valori Numero_byte e Latenza sul file .dat'
    N_LINEE_FILE=$(wc -l "${DataDir}/${ProtocolName}_throughput.dat" | cut -d ' ' -f1)
    NUMERO_LINEA=1

    while [ $NUMERO_LINEA -lt $N_LINEE_FILE ]
    do 
        N=$(sed "${NUMERO_LINEA}q;d" ${DataDir}/${ProtocolName}_throughput.dat | cut -d' ' -f1)
        D=$(bc <<<"scale=20;var1=${L};var2=${N};var3=${B};var1 + (var2 / var3)")
        echo $N $D
        printf "$N $D \n" >> ${OutputDatFile}
        ((NUMERO_LINEA++))
    done
    
    echo COSTANTI=
    L0=$(bc <<< "scale=2;$L")
    B0=$(bc <<< "scale=2;$B")

    echo "L0=$L0"
    echo "B0=$B0"
    echo 'GRAFICO: '
gnuplot <<-eNDgNUPLOTcOMMAND
    set term png size 900,700
    
    set logscale x 2
	set logscale y 10
	set xlabel "msg size (B)"
	set ylabel "throughput (KB/s)"
	
	set output "../data/$OutputPngFile"
	plot "../data/${OutputDatFile}" using 1:2 title "Latency-Bandwidth model with L=${L0} and B=${B0}"\
	    with linespoint, \
	     "../data/${InputFile}" using 1:3 title "${ProtocolName} ping-pong Throughput (average)" \
			with linespoints
			
	clear
eNDgNUPLOTcOMMAND

done
