*This project has been created as part of the 42 curriculum by <login1>[, <login2>[, <login3>...]].*

# Inception

## Description

The **Inception** project aims to introduce system administration and containerization using **Docker** and **Docker Compose**.

The goal is to build a small infrastructure composed of multiple interconnected services running inside isolated Docker containers. Each service has its own dedicated container and configuration.

The infrastructure generally includes:

- An **Nginx** web server
- A **WordPress** website running with PHP-FPM
- A **MariaDB** database
- Persistent storage using Docker volumes
- A dedicated Docker network for inter-container communication

This project helps understand modern deployment practices, service orchestration, networking, and data persistence using containers.

---

# Project Description

## Docker Usage

Docker is used to isolate each service inside its own container.  
Each container is built from a custom `Dockerfile`, while the entire infrastructure is managed through `docker-compose.yml`.

This approach ensures:

- Reproducible environments
- Easier deployment
- Service isolation
- Simplified dependency management

Unlike virtual machines, Docker containers are lightweight and share the host system kernel.

---

## Sources Included in the Project

The project contains:

- Custom Dockerfiles for each service
- Docker Compose configuration
- Nginx configuration files
- MariaDB setup scripts
- WordPress configuration
- Shell scripts for automatic service initialization
- Docker volumes for persistent data
- Environment variables stored in a `.env` file

---

# Design Choices & Comparisons

## Virtual Machines vs Docker

### Virtual Machines
- Virtualize an entire operating system
- Require more resources
- Slower startup time
- Better isolation

### Docker
- Virtualizes at the application level
- Lightweight and faster
- Shares the host kernel
- Easier to deploy and scale

Docker is more suitable for lightweight service orchestration and development environments.

---

## Secrets vs Environment Variables

### Environment Variables
- Easy to configure
- Commonly used in development
- Can expose sensitive data if not handled properly

### Docker Secrets
- More secure
- Designed for sensitive information
- Better suited for production environments

In this project, environment variables are used for simplicity and compatibility with the project requirements.

---

## Docker Network vs Host Network

### Docker Network
- Isolated communication between containers
- Improved security
- Internal DNS resolution between services

### Host Network
- Containers share the host network directly
- Less isolation
- Higher exposure to conflicts and security issues

A dedicated Docker network is used in this project to ensure secure and organized communication between services.

---

## Docker Volumes vs Bind Mounts

### Docker Volumes
- Managed by Docker
- Better portability
- Recommended for persistent application data

### Bind Mounts
- Direct mapping to host filesystem
- Useful during development
- More dependent on host machine structure

Docker volumes are used in this project to persist WordPress and MariaDB data.

---

# Instructions

## Prerequisites

Before starting, make sure the following tools are installed:

- Docker
- Docker Compose
- GNU Make
- Linux environment (recommended)

---

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd inception