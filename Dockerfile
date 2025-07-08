FROM golang:alpine as builder
ARG LDFLAGS=""

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories
RUN apk --update --no-cache add git build-base gcc

COPY . /build
WORKDIR /build

RUN go env -w GOPROXY=http://proxy.golang.org
COPY go.mod go.sum ./
RUN go mod download

RUN CGO_CFLAGS="-D_LARGEFILE64_SOURCE" go build -o ./jtso -ldflags "${LDFLAGS}" ./main.go 

FROM alpine:latest

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories
RUN apk update --no-cache 

USER 0
ADD ./html /html
COPY --from=builder /build/jtso /
RUN mkdir -p /etc/jtso
RUN mkdir -p /var/shared/telegraf
RUN mkdir -p /var/shared/grafana
RUN mkdir -p /var/cert
RUN mkdir -p /var/metadata

EXPOSE 8081

ENTRYPOINT ["./jtso"]
