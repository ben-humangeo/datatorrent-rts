FROM netflixoss/java:7

MAINTAINER Benjamin Parrish <ben@thehumangeo.com>

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get -y install ant python python-pip vim &&\
  python -m pip install --no-input --upgrade --force pip &&\
  pip install nflx-genie-client==2.2.0

# Download and configure hadoop client
RUN mkdir -p /apps/hadoop/2.6.0 &&\
  cd /apps/hadoop/2.6.0 &&\
  wget -q -P /apps/hadoop/2.6.0 'http://apache.cs.utah.edu/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz' &&\
  tar xf hadoop-2.6.0.tar.gz &&\
  rm hadoop-2.6.0.tar.gz &&\
  chown root:root -R hadoop-2.6.0 &&\
  mv hadoop-2.6.0/* . &&\
  rm -rf hadoop-2.6.0

ENV HADOOP_HOME=/apps/hadoop/2.6.0
ENV HADOOP_PREFIX=$HADOOP_HOME
ENV PATH=$HADOOP_HOME/bin:$PATH

# This is not needed to get Genie working as the scripts loaded into conf below can be copied at runtime
# I'm just adding them here so that the hadoop and pig commands can connect to the cluster from Genie node by default
# in case someone wants to mess around with them as a client
ADD hadoop/2.6.0/conf/*.xml $HADOOP_HOME/etc/hadoop/

# Download and configure pig client
RUN mkdir -p /apps/pig/0.14.0 &&\
  cd /apps/pig/0.14.0 &&\
  wget -q -P /apps/pig/0.14.0 'http://apache.cs.utah.edu/pig/pig-0.14.0/pig-0.14.0.tar.gz' &&\
  tar xf pig-0.14.0.tar.gz &&\
  rm pig-0.14.0.tar.gz &&\
  chown root:root -R pig-0.14.0 &&\
  mv pig-0.14.0/* . &&\
  rm -rf pig-0.14.0

# Build the Pig examples
ENV PIG_HOME=/apps/genie/pig/0.14.0

RUN mkdir -p $PIG_HOME &&\
  cd $PIG_HOME &&\
  wget -q -P $PIG_HOME 'http://apache.cs.utah.edu/pig/pig-0.14.0/pig-0.14.0-src.tar.gz' &&\
  tar xf pig-0.14.0-src.tar.gz &&\
  mv pig-0.14.0-src/* . &&\
  rm -rf pig-0.14.0-src pig-0.14.0-src.tar.gz &&\
  ant &&\
  cd tutorial &&\
  ant &&\
  mv pigtutorial.tar.gz /tmp &&\
  cd .. &&\
  rm -rf * &&\
  mkdir tutorial &&\
  mv /tmp/pigtutorial.tar.gz tutorial/ &&\
  cd tutorial &&\
  tar xf pigtutorial.tar.gz &&\
  mv pigtmp/* . &&\
  rm -rf pigtmp pigtutorial.tar.gz

ENV PIG_HOME=/apps/pig/0.14.0
ENV PATH=$PIG_HOME/bin:$PATH

RUN sudo apt-get install -y curl

RUN cd /tmp/
RUN curl -LSO https://www.datatorrent.com/downloads/datatorrent-rts.bin
RUN sudo sh ./datatorrent-rts.bin -E JAVA_HOME=/usr/lib/jvm/java-7-oracle

EXPOSE 9090