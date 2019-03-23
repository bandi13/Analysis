FROM    bandi13/gui-docker

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
                                      git cmake vim net-tools python python-numpy \
                                      libnetcdf-dev netcdf-bin libudunits2-0 libudunits2-data libudunits2-dev \
                                      libexpat1 libexpat1-dev libxext-dev libmotif-common libmotif-dev \
                                      && apt clean -y && rm -rf /var/lib/apt/lists/*

# Always use UTC on a server
RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && echo UTC > /etc/timezone

# Install GHAAS
RUN git clone https://github.com/bmfekete/RGIS /tmp/RGIS && /tmp/RGIS/install.sh /usr/local/share && rm -rf /tmp/RGIS

COPY Container/createUserBashrc.sh /opt/startup_scripts/.
