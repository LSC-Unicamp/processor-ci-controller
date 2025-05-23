#!/bin/bash

if [ -z "$1" ]; then
    nome_do_arquivo="./build/out.bit" 
else
    nome_do_arquivo=$1
fi

# Variáveis de configuração
REMOTE_USER="julio"
REMOTE_HOST="100.82.191.95"
REMOTE_PORT="22"  # Porta SSH padrão
TUNNEL_PORT="20000"
BITSTREAM_FILE=$nome_do_arquivo
BOARD="opensourceSDRLabKintex7"

# Ativa o túnel na máquina remota usando SSH
ssh -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST "nc -lp $TUNNEL_PORT | openFPGALoader -b $BOARD --file-type bit" &

# Dá um tempo para o túnel ser configurado
sleep 2

# Envia o bitstream para o túnel
nc -q 0 $REMOTE_HOST $TUNNEL_PORT < $BITSTREAM_FILE

sleep 10