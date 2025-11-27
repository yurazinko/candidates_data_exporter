# Candidates Data Exporter

This project is a Ruby on Rails application that acts as a backend service for generating CSV reports of candidates and their job applications, leveraging the Teamtailor JSON:API.

## 1. Running this project on local machine

Copy the configuration file:
```bash
cp example.env .env
```
Request the master key from the repository owner to decrypt credentials for external dependencies. Put this key into your .env file.
Alternatively configure dependencies by providing ENV variables:
```
TEAMTAILOR_API_BASE_URL=https://api.teamtailor.com/v1
TEAMTAILOR_API_KEY=secret-key-123
```

Build an image:
```bash
docker-compose build
```

Install all the gems:
```bash
docker-compose run app bundle install
```

Start Rails application server:

```bash
docker-compose up
```

The App will be available under this URL: http://localhost:3000

## 2. Connecting to the Rails console

First connect to the application container shell:

```bash
docker-compose run app sh
```

Then perform command for entering to the actual Rails console:
```bash
bundle exec rails c
```

You can also run Rails console from Docker Compose directly:
```bash
docker-compose run app rails c
```

## 3. Testing

For testing we are using Rspec. For runing all tests:
```bash
docker-compose run app bundle exec rspec spec
```

## 4. Stopping and Cleanup
To stop the application and remove containers:
```bash
docker-compose down -v
```