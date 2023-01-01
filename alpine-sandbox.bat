@echo off
set datadir=%~dp0\data

set t=%time: =0%
set datetime=%date:~0,4%-%date:~5,2%-%date:~8,2%_%t:~0,2%-%t:~3,2%
set workdir=%datadir%\%datetime%\work\
set logdir=%datadir%\%datetime%\logs\

mkdir %workdir%
mkdir %logdir%

docker build --tag alpine-sandbox:1.0 .
docker run -it --rm -v %logdir%:/logs -v %workdir%:/work alpine-sandbox:1.0