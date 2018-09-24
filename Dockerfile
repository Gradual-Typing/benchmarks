FROM base/archlinux

RUN pacman --quiet --noconfirm -Syu
RUN pacman --quiet --noconfirm -S base-devel git sudo time wget nano

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
RUN cd ~/tmp && yay --quiet --noconfirm -S chez-scheme-git
USER root

# installing utilities for the experiments
# sice machines run kernel 3.10 which causes problems with Qt5
# see https://bbs.archlinux.org/viewtopic.php?pid=1755257#p1755257
RUN wget http://downloads.sourceforge.net/sourceforge/gnuplot/gnuplot-5.2.0.tar.gz \
    && tar -zxvf gnuplot-5.2.0.tar.gz && cd gnuplot-5.2.0 \
    && ./configure --disable-wxwidgets --with-qt=no --with-x --with-readline=gnu \
    && make -j 8 && make install
RUN pacman --quiet --noconfirm -S bc
RUN raco pkg install --auto csv-reading

# These are needed for building the dynamizer and grift programs, they should
# not be installed after invalidating the cache because arch linux could have
# moved on by then and some of the dependencies will not be in the correct
# state.
RUN pacman --quiet --noconfirm -S stack
RUN pacman --quiet --noconfirm -S clang

# invalidate Docker cache to always pull the recent version of the dynamizer and grift
ARG CACHE_DATE=not_a_date

# installing the Dynamizer
RUN git clone https://github.com/Gradual-Typing/Dynamizer.git \
    && mkdir -p /home/root && cd Dynamizer && stack setup \
    && stack build && stack install \
    && cp /root/.local/bin/dynamizer /usr/local/bin

# installing Grift
RUN raco pkg install grift
RUN cp /root/.racket/7.0/bin/* /usr/local/bin

ARG EXPR_DIR=not_a_path

WORKDIR $EXPR_DIR/scripts

CMD make all
