FROM golang:alpine AS builder
WORKDIR /go/src/app
COPY . .
RUN go mod download
RUN go install ./... .

FROM alpine
COPY --from=builder /go/bin/data-service ./
COPY ./db_info.json ./
EXPOSE 20001/udp 25530/udp
CMD ["./data-service"]
