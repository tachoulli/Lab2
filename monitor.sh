#!/bin/bash

#verifica que menos se pase el comando

if [ "$#" -lt 1 ]; then
    echo "Uso: ./monitor.sh \"comando\" [intervalo]"
    exit 1
fi
#____________________________________________________________________________

#Recibe argumentos
comando="$1"
intervalo="${2:-2}"

#Ejecucion del proceso
bash -c "$comando" &
pid=$!

#Registro periódico
log="monitor_${pid}.log"
grafica="monitor_${pid}.png"

#Tiempo
tiempo=0

#Encabezado del log
    echo "TIMESTAMP CPU% MEM% MEM_RSS_KB" > "$log"

#Si se interrumpe con Ctrl+C
trap 'kill "$pid" 2>/dev/null' SIGINT

# Mientras el proceso exista
while ps -p "$pid" > /dev/null 2>&1; do
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Obtener cpu, mem y rss
    datos=$(ps -p "$pid" -o %cpu,%mem,rss --no-headers)

    # Guardar en el log
        echo "$timestamp $datos" >> "$log"

    sleep "$intervalo"
    tiempo=$((tiempo + intervalo))
done

# Crear archivo temporal para gnuplot con tiempo en segundos
awk -v paso="$intervalo" 'NR>1 {print (NR-2)*paso, $3, $5}' "$log" > datos_temp.txt

# Generar gráfica con gnuplot
gnuplot << EOF
set terminal png size 800,600
set output "$grafica"
set title "Monitoreo: $comando (PID $pid)"
set xlabel "Tiempo transcurrido (s)"
set ylabel "CPU (%)"
set y2label "Memoria RSS (KB)"
set y2tics
set autoscale y
set autoscale y2
set key top right
plot "datos_temp.txt" using 1:2 with lines title "CPU (%)", \
     "datos_temp.txt" using 1:3 axes x1y2 with lines title "RSS (KB)"
EOF

# Borrar temporal
rm -f datos_temp.txt

echo "Proceso monitoreado: $pid"
echo "Log generado: $log"
echo "Gráfica generada: $grafica"
