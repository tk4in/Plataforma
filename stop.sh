echo "Terminando Serviços."
kill $(cat web.pid 2>/dev/null) 2>/dev/null
if [ $? -eq 0 ]; then while [ -f "web.pid" ]; do sleep 1; done; fi;
rm -f web.pid 2>/dev/null
echo "GW-server terminado."