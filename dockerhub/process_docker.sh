# docker hub configuration
organisation=geonature
depot=debian

# debian versions
# buster 10
# stretch 9
versions="buster stretch"

# docker login
# docker login

# process each version
for version in ${versions}
do
    docker_name=${organisation}/${depot}:${version} 
    echo build ${docker_name}

    # create dir
    dir_name=debian-${version}
    rm -R ${dir_name}
    mkdir ${dir_name}
    
    # create Dockerfile (replace DEBIAN_VERSION with $version)
    sed "s/DEBIAN_VERSION/${version}/g" ./Dockerfile_sample > ${dir_name}/Dockerfile

    # create source.list
    sed "s/DEBIAN_VERSION/${version}/g" ./sources.list_sample > ${dir_name}/sources.list

    # build docker
    cd ${dir_name}
    docker build -t ${docker_name} .

    # push docker
    docker push ${docker_name} .

    cd ..
done

echo "process done : built debian images for versions ${versions}" 