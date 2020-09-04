# webrtc janus dockerfile

### build
docker build -t janus


### run
docker run -p 7088:7088 -p 7089:7089 -p 8000:8000 -p 8088:8088 -p 8089:8089 -p 8889:8889 -p 10000-10200:10000-10200/udp janus:latest

### 说明
server http://ip:8088/janus
