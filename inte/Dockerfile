#Deriving the latest base image
FROM python:alpine
WORKDIR /

#to COPY the remote file at working directory in container
COPY ./pyapi /pyapi
COPY ./db_command_habitat.py /
# Now the structure looks like this '/usr/app/src/test.py'


#CMD instruction should be used to run the software
#contained by your image, along with any arguments.

CMD [ "python", "./db_command_habitat.py"]