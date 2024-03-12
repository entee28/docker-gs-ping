# syntax=docker/dockerfile:1

##
## Build the application from source
##

FROM golang:1.22.1 AS build-stage

WORKDIR /app

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod/ \ 
    go mod download

COPY *.go ./

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=cache,target=/.cache \
    CGO_ENABLED=0 GOOS=linux go build -o /docker-gs-ping

##
## Run the tests in the container
##

FROM build-stage AS run-test-stage
RUN --mount=type=cache,target=/.cache \
    go test -v ./...

##
## Deploy the application binary into a lean image
##

FROM gcr.io/distroless/base-debian11 AS build-release-stage

WORKDIR /

COPY --from=build-stage /docker-gs-ping /docker-gs-ping

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/docker-gs-ping"]
