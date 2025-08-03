
# IAM Microservices Platform

Welcome to the **IAM Microservices Platform** — a modular, scalable system for Identity and Access Management (IAM). This platform consists of multiple independent microservices that together provide user management, authentication, and infrastructure orchestration.

---

## 📂 Repository Structure

The platform is organized into multiple repositories (folders) inside this main repo:

```

iam-microservices-platform/
├── iam-common-utilities/       # Shared code & utilities used by all services
├── iam-user-service/           # Handles user CRUD operations and profiles
├── iam-auth-service/           # Handles authentication, JWT tokens, login/logout
├── iam-infrastructure/         # Docker & infrastructure configuration (Postgres, Redis, Vault, etc.)
├── iam-database-postgres/      # Database schema, migrations, and seed data for PostgreSQL
├── iam-authorization-service/  # Authorization service placeholder
├── iam-chat-service/           # Chat service placeholder
├── iam-notification-service/   # Notification service placeholder
├── iam-redis-config/           # Redis configuration and setup
├── iam-vault-config/           # Vault configuration and secrets management
├── iam-database-mongo/         # MongoDB schema and data for chat service
├── iam-frontend-react/         # React frontend for the platform
├── iam-infrastructure/         # Docker-compose and environment setup
├── architecture/               # Architecture diagrams and design docs
├── gradle/                     # Gradle build setup
├── build/                      # Build output directory (ignored in git)
└── README.md                   # This README file

````
## Repositories links

This monorepo hosts multiple microservices. Each microservice has its own Git repository and is managed as a Git submodule.

| Service                  | Repository Link                                                                 |
|--------------------------|----------------------------------------------------------------------------------|
| API Gateway              | [iam-api-gateway](https://github.com/malak29/iam-api-gateway.git)               |
| Auth Service             | [iam-auth-service](https://github.com/malak29/iam-auth-service.git)             |
| Authorization Service    | [iam-authorization-service](https://github.com/malak29/iam-authorization-service.git) |
| Chat Service             | [iam-chat-service](https://github.com/malak29/iam-chat-service.git)             |
| Common Utilities         | [iam-common-utilities](https://github.com/malak29/iam-common-utilities.git)     |
| Database (Mongo)         | [iam-database-mongo](https://github.com/malak29/iam-database-mongo.git)         |
| Database (Postgres)      | [iam-database-postgres](https://github.com/malak29/iam-database-postgres.git)   |
| Frontend (React)         | [iam-frontend-react](https://github.com/malak29/iam-frontend-react.git)         |
| Infrastructure           | [iam-infrastructure](https://github.com/malak29/iam-infrastructure.git)         |
| Notification Service     | [iam-notification-service](https://github.com/malak29/iam-notification-service.git) |
| Redis Config             | [iam-redis-config](https://github.com/malak29/iam-redis-config.git)             |
| User Service             | [iam-user-service](https://github.com/malak29/iam-user-service.git)             |
| Vault Config             | [iam-vault-config](https://github.com/malak29/iam-vault-config.git)             |


---

## 🏗 Architecture Diagrams

### System Overview Diagram  
*(Placeholder for high-level system architecture showing services and their interactions)*



---

### Database & Service Interaction Diagram  
*(Placeholder for detailed database schema and how services connect to the DB and each other)*



---

## 🚀 Getting Started — Setup & Run

Sure! Here's an updated **"🚀 Getting Started — Setup & Run"** section with the setup script step added. This tells users to run `setup.sh` first, which will clone all the individual microservice repos into their respective folders:

---

## 🚀 Getting Started — Setup & Run

### Prerequisites

* [Java 21+](https://adoptium.net/)
* [Docker](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Gradle](https://gradle.org/install/)
* PostgreSQL and Redis will run inside Docker containers

---

### Step 1: Clone the parent platform repo

```bash
git clone https://github.com/malak29/iam-microservices-platform.git
cd iam-microservices-platform
```

---

### Step 2: Pull Microservice Repos

All microservices are in their own repositories. Use the setup script to pull them into the correct folders:

```bash
bash setup.sh
```

This will automatically clone each service into its respective folder under this project. Each has its own independent Git history.

---

### Step 3: Environment Variables

Create a `.env.local` file in `iam-infrastructure/` with the following variables:

```env
POSTGRES_DB=iam_db
POSTGRES_USER=iam_user
POSTGRES_PASSWORD=your_password
POSTGRES_PORT=5432

REDIS_PORT=6379

VAULT_PORT=8200
VAULT_ROOT_TOKEN=dev-token

MONGO_PORT=27017
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=password
MONGO_DB=iam_chat
```

---

### Step 4: Start Infrastructure

Use Docker Compose to start Postgres, Redis, Vault, and MongoDB:

```bash
cd iam-infrastructure
docker-compose up -d
```

This will:

* Start PostgreSQL on port 5432
* Start Redis on port 6379
* Start Vault on port 8200
* Start MongoDB on port 27017
* Start Adminer (DB UI) on port 8080

---

### Step 5: Initialize the Database

Postgres will automatically run SQL scripts from `iam-database-postgres/init/` to create tables and seed reference data.

You can connect to Postgres to verify:

```bash
docker exec -it iam-postgres psql -U iam_user -d iam_db
```

Run `\dt` to list tables.

---

### Step 6: Build & Run Microservices

Back in the root folder (`iam-microservices-platform`), run:

```bash
./gradlew build
```

Then run services individually:

```bash
# User Service
java -jar iam-user-service/build/libs/iam-user-service.jar

# Auth Service
java -jar iam-auth-service/build/libs/iam-auth-service.jar
```

Or run them from your IDE.

---

### Step 7: Test APIs

* User Service: [http://localhost:8081/api/v1/users](http://localhost:8081/api/v1/users)
* Auth Service: [http://localhost:8082/api/v1/auth/login](http://localhost:8082/api/v1/auth/login)

Use Postman or curl to test endpoints.

---

## 📝 Notes

* All microservices share common utilities located in `iam-common-utilities`.
* The system uses JWT tokens stored in Redis for session management.
* Database schema is designed with proper foreign keys for referential integrity.
* Docker Compose orchestrates infrastructure services for ease of development.
* Currently, only User and Auth services are fully implemented; others are placeholders for future work.

---

## 🛠️ Future Work

* API Gateway to route requests centrally
* Service-to-service communication (e.g., Auth service calls User service)
* Add more microservices: Authorization, Chat, Notifications
* Frontend React app to interact with backend APIs
* Secure Redis and Vault for production readiness
* Add CI/CD pipelines and monitoring

---

## 🙋 How to Contribute

* Fork the repo and create feature branches
* Follow Java and Spring Boot best practices
* Add tests for new features
* Open pull requests with clear descriptions

---

## 📞 Contact

For questions or collaboration, contact **Malak Parmar**
Email: [malakparmar.29@gmail.com](mailto:malakparmar.29@gmail.com)
GitHub: [https://github.com/malak29](https://github.com/malak29)

---

Thanks for checking out the IAM Microservices Platform! 🚀

