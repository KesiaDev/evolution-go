FROM golang:1.25.0-alpine AS build

RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

# Clonar o repo diretamente (evita todos os problemas de build context do Railway)
RUN git clone --depth=1 https://github.com/KesiaDev/evolution-go.git .

# Clonar whatsmeow-lib (submodule)
RUN git clone --depth=1 https://github.com/EvolutionAPI/whatsmeow.git ./whatsmeow-lib

# Verificar que go.mod está presente
RUN ls go.mod go.sum

ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

FROM alpine:3.19.1 AS final

RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp

WORKDIR /app

COPY --from=build /build/server .
COPY --from=build /build/manager/dist ./manager/dist
COPY --from=build /build/VERSION ./VERSION

ENV TZ=America/Sao_Paulo

ENTRYPOINT ["/app/server"]
