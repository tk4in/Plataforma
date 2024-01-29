echo "Terminando Serviços."
sudo kill -9 $(sudo lsof -t -i:443)
echo "WEB terminado."