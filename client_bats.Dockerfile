FROM alpine:latest

RUN apk add --no-cache bash bats jq curl

RUN mkdir /app
WORKDIR /app

CMD ["tail", "-f", "/dev/null"]
