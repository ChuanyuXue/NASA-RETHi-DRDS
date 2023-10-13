FROM golang:alpine AS builder
RUN apk add --no-cache make build-base git
WORKDIR /go/src/app
COPY . .
RUN go mod download
RUN go install ./... .

FROM python:3.9-alpine
COPY --from=builder /go/bin/NASA-RETHi-DRDS ./
COPY . .
RUN pip install requests
RUN apk --no-cache add musl-dev linux-headers g++ pkgconfig hdf5-dev
RUN cd /utils/cdcm/cdcm_execution && pip install -e . 
RUN cd /utils/cdcm/lunar_ext_env && pip install -e . 
RUN cd /utils/cdcm/yabml && pip install -e . 
RUN cd /utils/cdcm/cdcm_hab && pip install -e . 

EXPOSE 20001/udp
CMD ["./NASA-RETHi-DRDS"]



# FROM python:3.9
# COPY --from=builder /go/bin/NASA-RETHi-DRDS ./
# COPY ./utils/cdcm ./
# # RUN apk add --no-cache make build-base git gcc g++
# RUN apt-get update && apt-get install -y build-essential linux-headers-generic

# RUN python -m pip install jaxlib jax pyviewfactor pyvista
# RUN python -m pip install numpy --config-settings=setup-args="-Dallow-noblas=true"

# RUN python -m pip install ./cdcm/cdcm_execution/setup.py && \
#     python -m pip install ./cdcm/cdcm_hab/setup.py && \
#     python -m pip install ./cdcm/lunar_ext_env/setup.py && \
#     python -m pip install ./cdcm/yabml/setup.py && \

# COPY ./db_info.json ./
# COPY ./db_info_v6.json ./
# COPY ./db_info_press.json ./
# CMD [ "python", "/cdcm_hab/examples/HCI_CDCM_DT/thermal_dt_script.py" ]

