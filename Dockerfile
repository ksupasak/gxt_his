FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    openssl \
    openssl-dev \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application files
COPY . .

# Expose port 3000
EXPOSE 3000

# Run the application (HTTP mode for Docker, nginx handles SSL)
CMD ["sh", "start-docker.sh"]

