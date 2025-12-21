# SSL Certificates

Place your SSL certificates in this directory:

- `cert.pem` - SSL certificate file
- `key.pem` - SSL private key file

You can copy from `config/cert/` directory:

```bash
cp config/cert/cert.pem nginx/ssl/cert.pem
cp config/cert/key.pem nginx/ssl/key.pem
```

Or generate self-signed certificates for testing:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=TH/ST=State/L=City/O=Organization/CN=localhost"
```

