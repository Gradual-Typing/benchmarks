FROM base/archlinux

RUN pacman --quiet --noconfirm -Syu
RUN pacman --quiet --noconfirm -S base-devel
RUN pacman --quiet --noconfirm -S git
RUN pacman --quiet --noconfirm -S sudo
RUN pacman --quiet --noconfirm -S time
RUN pacman --quiet --noconfirm -S wget
RUN pacman --quiet --noconfirm -S nano
RUN pacman --quiet --noconfirm -S openssh
RUN pacman --quiet --noconfirm -S clang
RUN pacman --quiet --noconfirm -S stack
RUN pacman --quiet --noconfirm -S gnuplot
RUN pacman --quiet --noconfirm -S bc

WORKDIR /app

# installing Racket and Typed Racket
RUN pacman --quiet --noconfirm -S racket racket-docs

# installing Gambit-C compiler for Scheme
RUN pacman --quiet --noconfirm -S gambit-c

# installing OCaml
RUN pacman --quiet --noconfirm -S ocaml opam

# installing Chez Scheme
ENV HomeDocker /home/docker
RUN useradd -m --uid 1000 -G wheel -d ${HomeDocker} -p 1234 -s /bin/bash docker \
    && echo " %wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER docker
RUN mkdir ~/tmp && cd ~/tmp && git clone https://aur.archlinux.org/yay.git \
    && cd yay && makepkg --noconfirm -si
RUN yay --quiet --noconfirm -S chez-scheme-git
USER root

# invalidate Docker cache to always pull the recent version of the dynamizer and grift
ARG CACHE_DATE=not_a_date

# installing the Dynamizer
RUN git clone https://github.com/Gradual-Typing/Dynamizer.git \
    && mkdir -p /home/root && cd Dynamizer && stack setup \
    && stack build && stack install \
    && cp /root/.local/bin/dynamizer /usr/local/bin

# installing Grift
RUN git clone https://github.com/Gradual-Typing/Grift.git \
    && cd Grift && git checkout moving-benchmark \
    && export PLTSTDERR="error debug@tr-timing" \
    && raco pkg install
RUN cd Grift && raco exe -o grift main.rkt \
    && raco exe -o grift-bench benchmark/bench.rkt \
    && raco exe -o grift-configs benchmark/configs.rkt \
    && cp grift grift-bench grift-configs /usr/local/bin

# installing utilities for the experiments
RUN raco pkg install --auto csv-reading

ARG EXPR_DIR=not_a_path

WORKDIR $EXPR_DIR/scripts

CMD make all
