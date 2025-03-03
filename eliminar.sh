!/bin/bash
clear
sleep 1
echo "Esto eliminara un archivo"
ls -l
read archivo
trash-put "$archivo"