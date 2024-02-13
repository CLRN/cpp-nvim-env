FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y --allow-unauthenticated \
    wget \
    git \
    ripgrep \
    unzip \
    npm \
    gettext \
    python3-venv \
    python3-pip \
    build-essential \
    gdb \
    software-properties-common \
    lsb-release \
    curl \
    && apt-get clean

RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 18 && rm -rf llvm.sh
RUN apt-get update && apt-get install -y --allow-unauthenticated clang-tools-18

RUN for f in /usr/lib/llvm-*/bin/*; do ln -sf "$f" /usr/bin; done && \
    ln -sf clang /usr/bin/cc && \
    ln -sf clang /usr/bin/c89 && \
    ln -sf clang /usr/bin/c99 && \
    ln -sf clang++ /usr/bin/c++ && \
    ln -sf clang++ /usr/bin/g++ && \
    rm -rf /var/lib/apt/lists/*


RUN rm -f $(which cmake)

ARG CMAKE_VERSION=3.28.3
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && mkdir /usr/bin/cmake \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr/bin/cmake \
      && rm /tmp/cmake-install.sh
ENV PATH="/usr/bin/cmake/bin:${PATH}"

RUN git clone --depth 1 --branch release https://github.com/ninja-build/ninja.git && cd ninja && \
    cmake -Bbuild-cmake && cd build-cmake && make install -j 6 && cp /usr/local/bin/ninja /usr/bin/ninja && \
    cd ../../ && rm -rf ninja

RUN git clone --branch release-0.9 --depth 1 https://github.com/neovim/neovim.git && \
    cd neovim && make CMAKE_BUILD_TYPE=Release install -j 6 && \
    cd .. && rm -rf neovim

RUN nvim -v

RUN git clone https://github.com/CLRN/nvim-config.git ~/.config/nvim

## Install packer.nvim for installing plugins
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim \
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

RUN nvim --headless -c ':MasonInstallAll' +qall

# lazy git
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf lazygit.tar.gz lazygit && \
    install lazygit /usr/local/bin

RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install

# cpp debugger
RUN curl -LO https://github.com/microsoft/vscode-cpptools/releases/download/v1.18.5/cpptools-linux.vsix && \ 
    unzip cpptools-linux.vsix && \
    mv extension/debugAdapters/bin/* /usr/local/bin/ && \
    chmod 777 /usr/local/bin/OpenDebugAD7 && \
    rm -rf extension 

# Install Boost
# https://www.boost.org/doc/libs/1_80_0/more/getting_started/unix-variants.html
ENV BOOST_VERSION=1.84.0
RUN cd /tmp && \
    BOOST_VERSION_MOD=$(echo $BOOST_VERSION | tr . _) && \
    wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_MOD}.tar.bz2 && \
    tar --bzip2 -xf boost_${BOOST_VERSION_MOD}.tar.bz2 && \
    cd boost_${BOOST_VERSION_MOD} && \
    ./bootstrap.sh --with-toolset=clang --prefix=/usr/local && \
    ./b2 -j 6 install && \
    rm -rf /tmp/*

# git
RUN git config --global credential.helper store
RUN git config --global user.email "clrnmail@gmail.com"
RUN git config --global user.name "clrn"
RUN git config --global pull.rebase true

ENV LD_LIBRARY_PATH=/usr/local/lib/
ENV SHELL=/usr/bin/bash

RUN ln -sf /usr/lib/llvm-18/bin/clangd /usr/local/bin/clangd-17
RUN ln -sf /usr/lib/llvm-18/bin/clang-format /usr/local/bin/bde-format-15
COPY ./gdbinit /root/.gdbinit

CMD ["/usr/bin/bash"]
