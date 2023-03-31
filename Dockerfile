FROM dart

WORKDIR /dart_api

ADD pubspec.* /dart_api/

RUN pub get

ADD . /dart_api/

RUN pub get

WORKDIR /dart_api

EXPOSE 8888

ENTRYPOINT [ "pub", "run", "conduit:conduit", "server", "--port", "8888" ]