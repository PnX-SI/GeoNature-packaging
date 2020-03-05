#!/bin/bash

keepdb="true"

function finish {
  if [ $keepdb = "false" ] 
  then
    drop_database
    echo "fuck it's failed !"
  fi
}
trap finish EXIT

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

    if [ ! -d '/tmp/habref/' ]
    then
        mkdir /tmp/habref
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
        su postgres -c "psql -tAl | grep -q \"^$1|\""
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
    su postgres -c "psql -v ON_ERROR_STOP=1 -c \"CREATE ROLE $POSTGRES_USER WITH LOGIN PASSWORD '$POSTGRES_PASSWORD';\""
    return $?
}

function create_database () {
    keepdb="false"
    prepare_path
    echo "--------------------" &> $LOG_PATH/install_db.log
    write_log "Creating GeoNature database..."
    su postgres -c "createdb -O $POSTGRES_USER $POSTGRES_DB -T template0 -E UTF-8 -l $POSTGRES_LOCALE"
    write_log "Adding PostGIS and other use PostgreSQL extensions"
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS postgis;'" &>> $LOG_PATH/install_db.log
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS hstore;'" &>> $LOG_PATH/install_db.log
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'" &>> $LOG_PATH/install_db.log
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c 'CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";'" &>> $LOG_PATH/install_db.log
    
    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "GRANT..."
    cp $SCRIPT_PATH/grant.sql /tmp/geonature/grant.sql
    sed -i "s/MYPGUSER/$POSTGRES_USER/g" /tmp/geonature/grant.sql
    write_log 'GRANT'
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -f /tmp/geonature/grant.sql" &>> $LOG_PATH/install_db.log
    
    #Public functions
    write_log "Creating 'public' functions..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/public.sql  &>> $LOG_PATH/install_db.log
    
    # Users schema (utilisateurs)
    write_log "Getting and creating USERS schema (utilisateurs)..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/usershub.sql &>> $LOG_PATH/install_db.log
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/usershub-data.sql &>> $LOG_PATH/install_db.log
    if [[ $ADD_USERSHUB_SAMPLE_DATA = "true" ]]
    then
        write_log "Insertion of data for usershub..."
        # fisrt insert taxhub data for usershub
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/adds_for_usershub.sql &>> $LOG_PATH/install_db.log
        # insert geonature data for usershub
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/utilisateurs/usershub-dataset.sql &>> $LOG_PATH/install_db.log
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
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdb.sql  &>> $LOG_PATH/install_db.log
    write_log "Inserting INPN taxonomic data... (This may take a few minutes)"
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -f /tmp/taxhub/data_inpn_taxhub.sql" &>> $LOG_PATH/install_db.log
    write_log "Creating dictionaries data for taxonomic schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdata.sql  &>> $LOG_PATH/install_db.log
    write_log "Inserting sample dataset  - atlas attributes...."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdata_atlas.sql  &>> $LOG_PATH/install_db.log
    write_log "Creating a view that represent the taxonomic hierarchy..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/materialized_views.sql  &>> $LOG_PATH/install_db.log   

    # Habref schema
    echo "Download and extract habref file..."
    if [ ! -f '/tmp/habref/HABREF_50.zip' ]
    then
      wget https://geonature.fr/data/inpn/habitats/HABREF_50.zip -P /tmp/habref
    else
      echo HABREF_50.zip exists
    fi
    unzip -o /tmp/habref/HABREF_50.zip -d /tmp/habref
    cp $SCRIPT_PATH/occhab/habref.sql -P /tmp/habref
    cp $SCRIPT_PATH/occhab/data_inpn_habref.sql -P /tmp/habref 
    write_log "Creating 'habitat' schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/habref/habref.sql &>> $LOG_PATH/install_db.log
    write_log "Inserting INPN habitat data..."
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB  -f /tmp/habref/data_inpn_habref.sql" &>> $LOG_PATH/install_db.log

    # Nomenclatures schema
    echo "Getting 'nomenclature' schema creation scripts..."
    cp $SCRIPT_PATH/nomenclatures/nomenclatures.sql /tmp/nomenclatures
    cp $SCRIPT_PATH/nomenclatures/data_nomenclatures.sql /tmp/nomenclatures
    cp $SCRIPT_PATH/nomenclatures/nomenclatures_taxonomie.sql /tmp/nomenclatures
    cp $SCRIPT_PATH/nomenclatures/data_nomenclatures_taxonomie.sql /tmp/nomenclatures
    write_log "Creating 'nomenclatures' schema"
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/nomenclatures/nomenclatures.sql  &>> $LOG_PATH/install_db.log
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/nomenclatures/nomenclatures_taxonomie.sql  &>> $LOG_PATH/install_db.log
    write_log "Inserting 'nomenclatures' data..."
    sed -i "s/MYDEFAULTLANGUAGE/$NOMENCLATURE_LANGUAGE/g" /tmp/nomenclatures/data_nomenclatures.sql
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/nomenclatures/data_nomenclatures.sql  &>> $LOG_PATH/install_db.log
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/nomenclatures/data_nomenclatures_taxonomie.sql  &>> $LOG_PATH/install_db.log

    # Commons schema
    write_log "Creating 'commons' schema..."
    cp $SCRIPT_PATH/core/commons.sql /tmp/geonature/commons.sql
    sed -i "s/MYLOCALSRID/$LOCAL_SRID/g" /tmp/geonature/commons.sql
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/geonature/commons.sql  &>> $LOG_PATH/install_db.log
    
    # Meta schema
    write_log "Creating 'meta' schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/meta.sql  &>> $LOG_PATH/install_db.log

    # Ref_geo schema
    write_log "Creating 'ref_geo' schema..."
    cp $SCRIPT_PATH/core/ref_geo.sql /tmp/geonature/ref_geo.sql
    sed -i "s/MYLOCALSRID/$LOCAL_SRID/g" /tmp/geonature/ref_geo.sql
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/geonature/ref_geo.sql  &>> $LOG_PATH/install_db.log
    if [ $REFGEO_MUNICIPALITY = "true" ];
    then
        write_log "Insert default French municipalities (IGN admin-express)"
        if [ ! -f '/tmp/geonature/communes_fr_admin_express_2019-01.zip' ]
        then
            wget  --cache=off http://geonature.fr/data/ign/communes_fr_admin_express_2019-01.zip -P /tmp/geonature
        else
            echo "/tmp/geonature/communes_fr_admin_express_2019-01.zip already exist"
        fi
        unzip -o /tmp/geonature/communes_fr_admin_express_2019-01.zip -d /tmp/geonature
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -f /tmp/geonature/fr_municipalities.sql" &>> $LOG_PATH/install_db.log
        write_log "Restore $POSTGRES_USER owner"
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"ALTER TABLE ref_geo.temp_fr_municipalities OWNER TO $POSTGRES_USER;\"" &>> $LOG_PATH/install_db.log
        write_log "Insert data in l_areas and li_municipalities tables"
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/ref_geo_municipalities.sql  &>> $LOG_PATH/install_db.log
        write_log "Drop french municipalities temp table"
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"DROP TABLE ref_geo.temp_fr_municipalities;\"" &>> $LOG_PATH/install_db.log
    fi
    if [ $REFGEO_GRID = "true" ];
    then
        write_log "Insert INPN grids"
        if [ ! -f '/tmp/geonature/inpn_grids.zip' ]
        then
            wget  --cache=off https://geonature.fr/data/inpn/layers/2019/inpn_grids.zip -P /tmp/geonature
        else
            echo "/tmp/geonature/inpn_grids.zip already exist"
        fi
        unzip -o /tmp/geonature/inpn_grids.zip -d /tmp/geonature
        write_log "Insert grid layers... (This may take a few minutes)"
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -f /tmp/geonature/inpn_grids.sql" &>> $LOG_PATH/install_db.log
        write_log "Restore $POSTGRES_USER owner"
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"ALTER TABLE ref_geo.temp_grids_1 OWNER TO $POSTGRES_USER;\"" &>> $LOG_PATH/install_db.log
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"ALTER TABLE ref_geo.temp_grids_5 OWNER TO $POSTGRES_USER;\"" &>> $LOG_PATH/install_db.log
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"ALTER TABLE ref_geo.temp_grids_10 OWNER TO $POSTGRES_USER;\"" &>> $LOG_PATH/install_db.log
        write_log "Insert data in l_areas and li_grids tables"
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/ref_geo_grids.sql  &>> $LOG_PATH/install_db.log
    fi
    if  [ $REFGEO_DEM = "true" ];
    then
        write_log "Insert default French DEM (IGN 250m BD alti)"
        if [ ! -f '/tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
        then
            wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P /tmp/geonature
        else
            echo "/tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
        fi
	      unzip -o /tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d /tmp/geonature
        #gdalwarp -t_srs EPSG:$LOCAL_SRID /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc /tmp/geonature/dem.tif &>> $LOG_PATH/install_db.log
        export PGPASSWORD=$POSTGRES_PASSWORD;raster2pgsql -s $LOCAL_SRID -c -C -I -M -d -t 5x5 /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB  &>> $LOG_PATH/install_db.log
    	#echo "Refresh DEM spatial index. This may take a few minutes..."
        su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"REINDEX INDEX ref_geo.dem_st_convexhull_idx;\"" &>> $LOG_PATH/install_db.log
        if [ $REFGEO_VECTORISE_DEM = "true" ];
        then
            write_log "Vectorisation of DEM raster. This may take a few minutes..."
            su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;\"" &>> $LOG_PATH/install_db.log
            write_log "Refresh DEM vector spatial index. This may take a few minutes..."
            su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -c \"REINDEX INDEX ref_geo.index_dem_vector_geom;\"" &>> $LOG_PATH/install_db.log
        fi
    fi

    # Imports schema
    write_log "Creating 'imports' schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/imports.sql  &>> $LOG_PATH/install_db.log

    # Synthese schema
    write_log "Creating 'synthese' schema..."
    cp $SCRIPT_PATH/core/synthese.sql /tmp/geonature/synthese.sql
    sed -i "s/MYLOCALSRID/$LOCAL_SRID/g" /tmp/geonature/synthese.sql
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/geonature/synthese.sql  &>> $LOG_PATH/install_db.log
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/synthese_default_values.sql  &>> $LOG_PATH/install_db.log
    write_log "Creating commons view depending of synthese"
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/commons_synthese.sql  &>> $LOG_PATH/install_db.log

    # Exports schema
    write_log "Creating 'exports' schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/exports.sql  &>> $LOG_PATH/install_db.log

    # Monitoring schema
    write_log "Creating 'monitoring' schema..."
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -v MYLOCALSRID=$LOCAL_SRID -f $SCRIPT_PATH/core/monitoring.sql  &>> $LOG_PATH/install_db.log

    # Permissions schema
    write_log "Creating 'permissions' schema"
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/permissions.sql  &>> $LOG_PATH/install_db.log
    write_log "Insert 'permissions' data"
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/permissions_data.sql  &>> $LOG_PATH/install_db.log

    # Sensitivity schema
    export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/sensitivity.sql  &>> $LOG_PATH/install_db.log
    write_log "Insert 'gn_sensitivity' data"
    echo "--------------------"
    if [ ! -f '/tmp/geonature/181201_referentiel_donnes_sensibles.csv' ]
        then
            wget --cache=off https://geonature.fr/data/inpn/sensitivity/181201_referentiel_donnes_sensibles.csv -P /tmp/geonature
        else
            echo "/tmp/geonature/181201_referentiel_donnes_sensibles.csv already exist"
    fi
    cp $SCRIPT_PATH/core/sensitivity_data.sql /tmp/geonature/sensitivity_data.sql
    echo "Insert 'gn_sensitivity' data... (This may take a few minutes)"
    su postgres -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_DB -f /tmp/geonature/sensitivity_data.sql" &>> $LOG_PATH/install_db.log

    #Installation des données exemples
    if [ "$SAMPLE_DATA" = true ];
    then
        write_log "Inserting sample datasets..."
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f $SCRIPT_PATH/core/meta_data.sql  &>> $LOG_PATH/install_db.log
        write_log "Inserting sample dataset of taxons for taxonomic schema..."
        cp $SCRIPT_PATH/taxonomie/taxhubdata_taxons_example.sql /tmp/taxhub
        export PGPASSWORD=$POSTGRES_PASSWORD;psql -v ON_ERROR_STOP=1 -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/taxhub/taxhubdata_taxons_example.sql  &>> $LOG_PATH/install_db.log
    fi

    keepdb="true"
}

function drop_database () {
    echo "Suppression de la base..."
    su postgres -c "dropdb $POSTGRES_DB"
    echo "Une erreur d'exécution est survenue, la base à été supprimée"
}