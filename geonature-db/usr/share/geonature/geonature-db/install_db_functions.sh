#!/bin/bash

function prepare_path (){
    if [ ! -d '/tmp/geonature/' ]
    then
        mkdir /tmp/geonature
    fi

    if [ ! -d '/tmp/taxhub/' ]
    then
        mkdir /tmp/taxhub
    fi

    if [ ! -d '/tmp/nomenclatures/' ]
    then
        mkdir /tmp/nomenclatures
    fi

    if [ ! -d '/tmp/usershub/' ]
    then
        mkdir /tmp/usershub
    fi

    if [ ! -d '/var/log/geonature/geonature-db/' ]
    then
        mkdir -p /var/log/geonature/geonature-db
    fi
}

function database_exists () {
    # /!\ Will return false if psql can't list database. Edit your pg_hba.conf
    # as appropriate.
    if [[ -z $1 ]]
    then
        # Argument is null
        return 0
    else
        # Grep db name in the list of database
        sudo -n -u postgres -s -- psql -tAl | grep -q "^$1|"
        return $?
    fi
}

function write_log() {
    echo $1
    echo "" &>> $LOG_PATH/install_db.log
    echo "" &>> $LOG_PATH/install_db.log
    echo "--------------------" &>> $LOG_PATH/install_db.log
    echo $1 &>> $LOG_PATH/install_db.log
    echo "--------------------" &>> $LOG_PATH/install_db.log
}

function create_role() {
    echo "Création de l'utilisateur '$POSTGRES_USER' ..."
    su postgres -c "psql -c \"CREATE ROLE $POSTGRES_USER WITH LOGIN PASSWORD '$POSTGRES_PASSWORD';\""
    return $?
}

function create_database () {
    prepare_path
    echo "--------------------" &> $LOG_PATH/install_db.log
    write_log "Creating GeoNature database..."
    su postgres -c "createdb -O $POSTGRES_USER $POSTGRES_DB -T template0 -E UTF-8 -l $POSTGRES_LOCALE"
    write_log "Adding PostGIS and other use PostgreSQL extensions"
    su postgres -c "psql -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS postgis;'" &>> $LOG_PATH/install_db.log
    su postgres -c "psql -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS hstore;'" &>> $LOG_PATH/install_db.log
    su postgres -c "psql -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'" &>> $LOG_PATH/install_db.log
    su postgres -c "psql -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";'" &>> $LOG_PATH/install_db.log
    
    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "GRANT..."
    cp $SCRIPT_PATH/grant.sql /tmp/geonature/grant.sql
    sudo sed -i "s/MYPGUSER/$POSTGRES_USER/g" /tmp/geonature/grant.sql
    write_log 'GRANT'
    su postgres -c "psql -d $POSTGRES_DB -f /tmp/geonature/grant.sql" &>> $LOG_PATH/install_db.log
    
    #Public functions
    write_log "Creating 'public' functions..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/public.sql  &>> $LOG_PATH/install_db.log
    
    # Users schema (utilisateurs)
    write_log "Getting and creating USERS schema (utilisateurs)..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/usershub.sql &>> $LOG_PATH/install_db.log
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/usershub-data.sql &>> $LOG_PATH/install_db.log
    if [[ $ADD_USERSHUB_SAMPLE_DATA = "true" ]]
    then
        write_log "Insertion of data for usershub..."
        # fisrt insert taxhub data for usershub
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/adds_for_usershub.sql &>> $LOG_PATH/install_db.log
        # insert geonature data for usershub
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/usershub-dataset.sql &>> $LOG_PATH/install_db.log
    fi

    # Taxonomie schema
    echo "Download and extract taxref file..."
    cp  $SCRIPT_PATH/taxonomie/inpn/data_inpn_taxhub.sql /tmp/taxhub/data_inpn_taxhub.sql
    array=( TAXREF_INPN_v11.zip ESPECES_REGLEMENTEES_v11.zip LR_FRANCE_20160000.zip )
    for i in "${array[@]}"
    do
      if [ ! -f "tmp/taxhub/$i" ]
      then
          wget http://geonature.fr/data/inpn/taxonomie/$i -P /tmp/taxhub
      else
          echo "$i exists"
      fi
      unzip -o /tmp/taxhub/$i -d /tmp/taxhub
    done
    echo "Getting 'taxonomie' schema creation scripts..."
    cp $SCRIPT_PATH/taxonomie/taxhubdb.sql /tmp/taxhub
    cp $SCRIPT_PATH/taxonomie/taxhubdata.sql /tmp/taxhub
    cp $SCRIPT_PATH/taxonomie/taxhubdata_atlas.sql /tmp/taxhub
    cp $SCRIPT_PATH/taxonomie/materialized_views.sql /tmp/taxhub
    write_log "Creating 'taxonomie' schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdb.sql  &>> $LOG_PATH/install_db.log
    write_log "Inserting INPN taxonomic data... (This may take a few minutes)"
    su postgres -c "psql -d $POSTGRES_DB -f /tmp/taxhub/data_inpn_taxhub.sql" &>> $LOG_PATH/install_db.log
    write_log "Creating dictionaries data for taxonomic schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdata.sql  &>> $LOG_PATH/install_db.log
    write_log "Inserting sample dataset  - atlas attributes...."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdata_atlas.sql  &>> $LOG_PATH/install_db.log
    write_log "Creating a view that represent the taxonomic hierarchy..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/materialized_views.sql  &>> $LOG_PATH/install_db.log   

}

function drop_database () {
    echo "Suppression de la base..."
    sudo -n -u postgres -s dropdb $POSTGRES_DB
}