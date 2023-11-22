FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-github-hook-dispatcher
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-github-hook-dispatcher -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 robot-github-hook-dispatcher && \
    useradd -u 1000 -g robot-github-hook-dispatcher -s /sbin/nologin -m robot-github-hook-dispatcher

RUN echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd
RUN mkdir /opt/app -p
RUN chmod 700 /opt/app
RUN chown robot-github-hook-dispatcher:robot-github-hook-dispatcher /opt/app

RUN echo 'set +o history' >> /root/.bashrc
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
RUN rm -rf /tmp/*

USER robot-github-hook-dispatcher

WORKDIR /opt/app

COPY  --chown=robot-github-hook-dispatcher --from=BUILDER /go/src/github.com/opensourceways/robot-github-hook-dispatcher/robot-github-hook-dispatcher /opt/app/robot-github-hook-dispatcher

RUN chmod 550 /opt/app/robot-github-hook-dispatcher

RUN echo "umask 027" >> /home/robot-github-hook-dispatcher/.bashrc
RUN echo 'set +o history' >> /home/robot-github-hook-dispatcher/.bashrc

ENTRYPOINT ["/opt/app/robot-github-hook-dispatcher"]
