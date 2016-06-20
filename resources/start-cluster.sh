#!/bin/bash

echo "starting cluster.."
/usr/local/pgsql/bin/gtm -D /usr/local/pgsql/data_gtm >logfile 2>&1 &
/usr/local/pgsql/bin/postgres --datanode -p 15432 -c pooler_port=40101 -D /usr/local/pgsql/data_datanode_1 >logfile 2>&1 &
/usr/local/pgsql/bin/postgres --datanode -p 15433 -c pooler_port=40102 -D /usr/local/pgsql/data_datanode_2 >logfile 2>&1 &
/usr/local/pgsql/bin/postgres --coordinator -c pooler_port=40100 -D /usr/local/pgsql/data_coord1 >logfile 2>&1 &

PS_COUNT=$(ps aux | grep postgres | wc -l)
echo "check if cluster has started($PS_COUNT)..."

while [ $PS_COUNT -lt '30' ]; do
  sleep 1;
  PS_COUNT=$(ps aux | grep postgres | wc -l);
  echo "check if cluster has started($PS_COUNT)...";
done
echo "cluster running!"


echo "setup cluster.."
/usr/local/pgsql/bin/psql -c "ALTER NODE coord1 WITH (TYPE = 'coordinator', PORT = 5432, HOST='0.0.0.0')" postgres 
/usr/local/pgsql/bin/psql -c "CREATE NODE datanode_1 WITH (TYPE = 'datanode', PORT = 15432, HOST='0.0.0.0')" postgres
/usr/local/pgsql/bin/psql -c "CREATE NODE datanode_2 WITH (TYPE = 'datanode', PORT = 15433, HOST='0.0.0.0')" postgres

/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_1) 'ALTER NODE datanode_1 WITH (TYPE = ''datanode'', PORT = 15432)'" postgres
/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_1) 'CREATE NODE datanode_2 WITH (TYPE = ''datanode'', PORT = 15433)'" postgres
/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_1) 'CREATE NODE coord1 WITH (TYPE = ''coordinator'', PORT = 5432)'" postgres

/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_2) 'ALTER NODE datanode_2 WITH (TYPE = ''datanode'', PORT = 15433)'" postgres
/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_2) 'CREATE NODE datanode_1 WITH (TYPE = ''datanode'', PORT = 15432)'" postgres
/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_2) 'CREATE NODE coord1 WITH (TYPE = ''coordinator'', PORT = 5432)'" postgres

/usr/local/pgsql/bin/psql -c "SELECT pgxc_pool_reload()" postgres
/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_1) 'SELECT pgxc_pool_reload()'" postgres
/usr/local/pgsql/bin/psql -c "EXECUTE DIRECT ON (datanode_2) 'SELECT pgxc_pool_reload()'" postgres
echo "setup done!"


for f in /pgxl-initdb.d/*; do
  case "$f" in
    *.sql)    echo "$0: running $f"; echo "exit" | psql -f "$f"; echo ;;
    *)        echo "$0: ignoring $f" ;;
  esac
  echo
done

tail -f /usr/local/pgsql/data_gtm/gtm.log
