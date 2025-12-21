#!/bin/sh
# Setup SSL certificates for nginx

# Create nginx/ssl directory if it doesn't exist
mkdir -p nginx/ssl

# Copy certificates from config/cert if they exist
if [ -f "config/cert/cert.pem" ] && [ -f "config/cert/key.pem" ]; then
    echo "Copying SSL certificates from config/cert/..."
    cp config/cert/cert.pem nginx/ssl/cert.pem
    cp config/cert/key.pem nginx/ssl/key.pem
    echo "SSL certificates copied successfully!"
else
    echo "Warning: SSL certificates not found in config/cert/"
    echo "Please copy your certificates to nginx/ssl/ or generate new ones."
    echo ""
    echo "To generate self-signed certificates for testing:"
    echo "openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
    echo "  -keyout nginx/ssl/key.pem \\"
    echo "  -out nginx/ssl/cert.pem \\"
    echo "  -subj \"/C=TH/ST=State/L=City/O=Organization/CN=localhost\""
fi

