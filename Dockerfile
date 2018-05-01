FROM resin/raspberry-pi-node:latest

ENV INITSYSTEM on

RUN apt-get update && \
    apt-get install -y --force-yes git-core build-essential scons i2c-tools && \
    apt-get install -y --force-yes python-dev swig python-psutil python-rpi.gpio python-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    python -m pip install --upgrade pip setuptools wheel

RUN apt-get update && \
    apt-get install -y protobuf-compiler libprotobuf-dev libprotoc-dev automake libtool autoconf && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /home/loragw
RUN git clone https://github.com/jgarff/rpi_ws281x

WORKDIR  /home/loragw/rpi_ws281x
RUN scons && scons deb && dpkg -i libws2811*.deb && cp ws2811.h rpihw.h pwm.h /usr/local/include/

WORKDIR  /home/loragw/rpi_ws281x/python
RUN python ./setup.py build && python setup.py install

WORKDIR /home/loragw
RUN npm install -g --unsafe-perm rpi-ws281x-native && npm link rpi-ws281x-native

#OLED ... todo
#RUN apt-get install -y --force-yes libfreetype6-dev libjpeg-dev && pip install --upgrade luma.oled

WORKDIR /opt/loragw/dev
RUN git clone https://github.com/kersing/lora_gateway.git && \
    git clone https://github.com/kersing/paho.mqtt.embedded-c.git && \
    git clone https://github.com/kersing/ttn-gateway-connector.git && \
    git clone https://github.com/kersing/protobuf-c.git && \
    git clone https://github.com/kersing/packet_forwarder.git && \
    git clone https://github.com/google/protobuf.git

WORKDIR /opt/loragw/dev/lora_gateway/libloragw
RUN sed -i -e 's/PLATFORM= .*$/PLATFORM= imst_rpi/g' library.cfg && \
    sed -i -e 's/CFG_SPI= .*$/CFG_SPI= native/g' library.cfg && \
    make

WORKDIR /opt/loragw/dev/protobuf-c
RUN ./autogen.sh && ./configure && \
    make protobuf-c/libprotobuf-c.la && mkdir bin && \
    ./libtool install /usr/bin/install -c protobuf-c/libprotobuf-c.la `pwd`/bin && rm -f `pwd`/bin/*so*

WORKDIR /opt/loragw/dev/paho.mqtt.embedded-c
RUN make && make install

WORKDIR /opt/loragw/dev/ttn-gateway-connector
RUN cp config.mk.in config.mk && \
    make && \
    cp bin/libttn-gateway-connector.so /usr/lib/

WORKDIR /opt/loragw/dev/packet_forwarder/mp_pkt_fwd
RUN make && \
    cp mp_pkt_fwd /opt/loragw/mp_pkt_fwd

COPY oled.py monitor-ws2812.py monitor-gpio.py start.sh set_config.py /opt/loragw/
COPY loragw.service monitor.service oled.service /etc/systemd/system/

WORKDIR /opt/loragw
RUN python set_config.py


RUN ln -s /opt/loragw/monitor-ws2812.py /opt/loragw/monitor.py && \
    systemctl enable /etc/systemd/system/loragw.service && \
    systemctl enable /etc/systemd/system/monitor.service


CMD systemctl start loragw.service && \
    systemctl start monitor.service
