FROM golang:alpine AS builder
RUN apk add --no-cache make build-base git
WORKDIR /go/src/app
COPY . .
RUN go mod download
RUN go install ./... .

FROM python:alpine
COPY --from=builder /go/bin/NASA-RETHi-DRDS ./
# RUN apk add --no-cache make build-base git gcc g++
RUN apk --no-cache add musl-dev linux-headers g++
RUN python -m pip install numpy --config-settings=setup-args="-Dallow-noblas=true" 
# COPY ./db_info.json ./
# COPY ./db_info_v6.json ./
# COPY ./db_info_press.json ./

EXPOSE 20001/udp
CMD ["./NASA-RETHi-DRDS"]
