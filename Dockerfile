FROM golang AS builder
RUN apt-get update && apt-get install -y make build-essential git
WORKDIR /go/src/app
COPY . .
RUN go mod download
RUN go install ./... .

FROM python:3.9
COPY --from=builder /go/bin/NASA-RETHi-DRDS ./
COPY ./utils/cdcm ./
# RUN apk add --no-cache make build-base git gcc g++
RUN apt-get update && apt-get install -y build-essential linux-headers-generic

RUN python -m pip install jaxlib jax pyviewfactor pyvista
RUN python -m pip install numpy --config-settings=setup-args="-Dallow-noblas=true"

RUN python -m pip install ./cdcm/cdcm_execution/setup.py && \
    python -m pip install ./cdcm/cdcm_hab/setup.py && \
    python -m pip install ./cdcm/lunar_ext_env/setup.py && \
    python -m pip install ./cdcm/yabml/setup.py && \

    # COPY ./db_info.json ./
    # COPY ./db_info_v6.json ./
    # COPY ./db_info_press.json ./

    EXPOSE 20001/udp
CMD ["./NASA-RETHi-DRDS"]
