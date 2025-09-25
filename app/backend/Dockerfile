# Build stage
FROM golang:1.23.5-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go modules files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application code
COPY . .

# Build the Go application as a statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o app-backend main.go

# Runtime stage
FROM alpine:latest

# Install necessary certificates and debugging tools
RUN apk --no-cache add ca-certificates curl

# Set the working directory inside the container
WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/app-backend .

# Expose the application port
EXPOSE 8080

# Set the entrypoint to the Go binary
ENTRYPOINT ["./app-backend"]