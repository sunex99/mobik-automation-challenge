# Build stage
FROM golang:1.23 AS builder
WORKDIR /app
COPY . .
RUN go get github.com/lib/pq && \
    go build -o app-backend main.go

# Runtime stage
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/app-backend .
EXPOSE 5000
CMD ["./app-backend"]