# docker buildx build -t xuechuanyu/rethi-drds:main --platform linux/arm64,linux/amd64 --push .
# docker build -t rethi-drds:main .

FROM golang:alpine AS builder
RUN apk add --no-cache make build-base git
WORKDIR /go/src/app
COPY . .
RUN go mod download
RUN go install ./... .

FROM alpine
COPY --from=builder /go/bin/NASA-RETHi-DRDS ./
# COPY ./db_info.json ./
# COPY ./db_info_v6.json ./
# COPY ./db_info_press.json ./


EXPOSE 20001/udp
CMD ["./NASA-RETHi-DRDS"]
