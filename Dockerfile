FROM alpine:3

RUN apk add --no-cache \
  asciinema

WORKDIR /work

ENTRYPOINT ["asciinema", "rec", "/logs/record.cast"]
