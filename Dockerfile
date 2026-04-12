FROM golang:1.25.0-alpine AS build

RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

COPY . .

# Debug: verificar se go.mod foi copiado
RUN echo "=== ls /build ===" && ls -la /build | head -20 && echo "=== go.mod ===" && cat /build/go.mod | head -3

# Clonar whatsmeow-lib (submodule não é inicializado pelo Railway)
RUN git clone --depth=1 https://github.com/EvolutionAPI/whatsmeow.git ./whatsmeow-lib

ARG VERSION=dev
RUN cd /build && CGO_ENABLED=1 go build -mod=mod -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

FROM alpine:3.19.1 AS final

RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp

WORKDIR /app

COPY --from=build /build/server .
COPY --from=build /build/manager/dist ./manager/dist
COPY --from=build /build/VERSION ./VERSION

ENV TZ=America/Sao_Paulo

ENTRYPOINT ["/app/server"]
