FROM jenslaufer/docker-shiny-apps-base:latest

RUN apt-get update && apt-get install -y libproj-dev libgdal-dev

COPY R/apps/ /srv/shiny-server/apps

ARG MONGODB_URI=mongodb://cb-data-db

RUN echo "MONGODB_URI=${MONGODB_URI}" >> /home/shiny/.Renviron

ADD R/requirements.R requirements.R
RUN Rscript requirements.R
