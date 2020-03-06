FROM  debian:stretch

# TEST
RUN apt-get update -y

RUN apt-get install -y tasksel

RUN tasksel install standart

RUN apt-get install -y sudo


# in pipeline?
RUN apt-get upgrade -y
RUN apt-get upgrade -y python

RUN apt-get install -y git unzip wget apt-utils

RUN adduser --disabled-password --gecos '' geonature
RUN adduser geonature sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER geonature

WORKDIR /home/geonature

COPY ./test.sh .
COPY ./master.zip .
COPY ./install_all.sh .

RUN ./install_all.sh 