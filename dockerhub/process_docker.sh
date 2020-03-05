set -e

# docker hub configuration
organisation=geonature
depots="debian ubuntu"

# debian versions
# buster 10
# stretch 9
versions_debian="buster stretch"

versions_ubuntu="18.04"

# docker login
docker login

# process each depot
for depot in ${depots}
do

    versions_name=versions_${depot}

    # process each version
    for version in ${!versions_name}
    do

        docker_name=${organisation}/${depot}:${version} 
        echo "process ${docker_name} : init" 

        # create dir
        dir_name=${depot}-${version}
        rm -Rf ${dir_name}
        mkdir ${dir_name}
        
        # create Dockerfile (replace DEPOT_VERSION with $version)
        cp ./Dockerfile_sample ${dir_name}/Dockerfile
        sed -i "s/VERSION/${version}/g" ${dir_name}/Dockerfile
        sed -i "s/DEPOT/${depot}/g" ${dir_name}/Dockerfile

        # build docker
        cd ${dir_name}
        docker build -t ${docker_name} .
        # docker build -t ${docker_name} . --no-cache
        # docker run ${docker_name}

        # push docker
        docker push ${docker_name}

        cd ..
        echo "process ${docker_name} : done" 
    done # versions
done # depots
