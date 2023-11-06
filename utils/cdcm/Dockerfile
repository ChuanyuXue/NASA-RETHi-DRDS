FROM python:3.9-alpine
COPY . .
RUN apk add musl-dev linux-headers g++ pkgconfig hdf5-dev
RUN cd /cdcm_execution && pip install -e . 
RUN cd /lunar_ext_env && pip install -e . 
RUN cd /yabml && pip install -e . 
RUN cd /cdcm_hab && pip install -e . 
CMD [ "python", "/cdcm_hab/examples/HCI_CDCM_DT/thermal_dt_script.py" ]