FROM golang:alpine AS builder
RUN apk add --no-cache make build-base git
WORKDIR /go/src/app
COPY . .
RUN go mod download
RUN go install ./... .

FROM alpine
COPY --from=builder /go/bin/data-service ./
COPY ./db_info.json ./
COPY ./db_infov6.json ./
COPY ./db_info_press.json ./


EXPOSE 20001/udp
CMD ["./data-service"]
