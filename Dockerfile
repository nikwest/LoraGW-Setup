FROM resin/rpi-raspbian:stretch

ENV INITSYSTEM on

RUN apt-get install -y --force-yes git-core build-essential ntp scons i2c-tools
RUN apt-get install -y --force-yes python-dev swig python-psutil python-rpi.gpio python-pip
RUN python -m pip install --upgrade pip setuptools wheel

#COPY my_service.service /etc/systemd/system/my_service.service
#RUN systemctl enable /etc/systemd/system/my_service.service
