#!/bin/bash

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

function create_role() {
    echo "Création de l'utilisateur '$POSTGRES_PASSWORD' ..."
    su postgres -c "psql -c \"CREATE ROLE $POSTGRES_USER WITH LOGIN PASSWORD '$POSTGRES_PASSWORD';\""
}

function create_database () {
    mkdir -p log
    echo "Création de la base..."
    su postgres -c "createdb -O $POSTGRES_USER $POSTGRES_DB"
    echo "Ajout de l'extension pour les UUID..."
    su postgres -c "psql -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";'"
    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "Création de la structure de la base de données..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/usershub.sql &>> log/install_db.log
    echo "Insertion des données minimales dans la base de données..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/usershub-data.sql &>> log/install_db.log
    if 
     $ADD_USERSHUB_SAMPLE_DATA ]]
    then
        echo "Insertion des données exemple dans la base de données..."
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/usershub-dataset.sql &>> log/install_db.log
    fi
}

function drop_database () {
    echo "Suppression de la base..."
    sudo -n -u postgres -s dropdb $POSTGRES_DB
}