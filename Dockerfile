FROM    ubuntu:18.04
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake net-tools python python-numpy 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libnetcdf-dev netcdf-bin libudunits2-0 libudunits2-data libudunits2-dev 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libexpat1 libexpat1-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libxext-dev libmotif-common libmotif-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-goodies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tigervnc-standalone-server novnc websockify-common websockify

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install GHAAS
RUN git clone https://github.com/bmfekete/RGIS /root/RGIS
RUN /root/RGIS/install.sh /usr/local/share

ENTRYPOINT ["/bin/bash"]
