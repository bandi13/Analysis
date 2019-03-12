FROM    ubuntu:18.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y apt-utils
RUN apt-get git cmake net-tools python python-numpy 
RUN apt-get install -y libnetcdf-dev netcdf-bin libudunits2-0 libudunits2-data libudunits2-dev 
RUN apt-get install -y libexpat1 libexpat1-dev
RUN apt-get install -y libxext-dev libmotif-common libmotif-dev
RUN apt-get install -y xfce4 xfce4-goodies
RUN apt-get install -y tigervnc-standalone-server novnc websockify-common websockify
#RUN && rm -rf /var/lib/apt/lists/*

RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
#RUN echo "America/New_York" > /etc/timezone    
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install GHAAS
RUN git clone https://github.com/bmfekete/RGIS /root/RGIS
RUN /root/RGIS/install.sh /usr/local/share

ENTRYPOINT ["/bin/bash"]
