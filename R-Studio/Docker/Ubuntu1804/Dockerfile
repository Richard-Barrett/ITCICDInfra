FROM ubuntu:18.04

RUN apt-get update && \
    apt-get upgrade &&\
    apt-get install -y r-base && \
    apt-get install -y gdebi-core && \
    apt-get install -y wget && \
    apt-get install -y htop && \
    apt-get install -y atop && \
    apt-get install -y rsyslog && \ 
    apt-get install -y curl && \
    apt-get install -y net-tools && \
    apt-get install -y python3 && \
    apt-get install -y build-essential && \
    apt-get isntall -y libssl-dev && \
    apt-get install -y libffi-dev python-dev && \
    apt-get install -y python3-pip && \
    apt-get install -y net-tools && \
    apt-get install -y hping3 && \ 
    apt-get install -y fping && \
    apt-get install -y gawk && \
    apt-get install -y sed && \
    apt-get install -y grep && \
    apt-get install -y less && \
    apt-get install -y vim && \
    apt-get install -y gnupg && \
    apt-get clean && \
    
    # Make Directories && Install R-Studio 
    mkdir Git && \
    mkdir Packages && \
    cd Packages/ && \ 
      wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5042-amd64.deb && \
      gdebi rstudio-server-1.2.5042-amd64.deb && \
    cd ~

EXPOSE 8787

CMD ["rstudio-server", "--protected-mode no"]
