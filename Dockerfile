FROM ubuntu:18.04
LABEL maintainer="aa <bb@cc.dd>"

RUN apt-get update && \
    apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion \
    sudo \
    curl \
    git-core \
    gnupg \
    linuxbrew-wrapper \
    locales \
    zsh \
    wget \
    vim \
    nano \
    npm \
    fonts-powerline && \
    locale-gen en_US.UTF-8 && \
    adduser --quiet --disabled-password --shell /bin/bash --home /home/devuser --gecos "User" devuser && \
    echo "devuser:userpassword" | chpasswd &&  usermod -aG sudo devuser

ENV TERM xterm
CMD ["bash"]

RUN mkdir src
COPY Problem.py src/
COPY GenerateData.ipynb src/
COPY GenerateProblem.py src/
COPY dist.py src/

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion

# miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p /opt/conda && \
    export PATH="/opt/conda/bin:$PATH"

ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN conda install -c https://conda.anaconda.org/conda-forge pyomo pyomo.extras ipyleaflet pyvis
RUN conda install -c anaconda jupyter pip
RUN conda install appdirs requests 
RUN pip install mpu

RUN apt-get update && apt-get install -y glpk-utils curl grep sed dpkg && apt-get clean

RUN chmod 777 /src
RUN sudo chown -R root:devuser /src

# Add Tini. Tini operates as a process subreaper for jupyter. This prevents kernel crashes.
ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN sudo chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

USER devuser
WORKDIR /src

#The -p tag here is important—you will need to connect the port that the notebook is running on inside the container with your local machine.
CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
