# Deployment

<cite>
**Referenced Files in This Document**   
- [Dockerfile](file://Dockerfile)
- [docker-compose.yml](file://docker-compose.yml)
- [create_secrets.sh](file://create_secrets.sh)
- [src/env.dart](file://src/env.dart)
- [README.md](file://README.md)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Dockerfile Configuration](#dockerfile-configuration)
3. [Docker Compose Setup](#docker-compose-setup)
4. [Secrets Management with Google Cloud](#secrets-management-with-google-cloud)
5. [Environment Configuration](#environment-configuration)
6. [Deployment Workflows](#deployment-workflows)
7. [Best Practices](#best-practices)
8. [Common Issues and Solutions](#common-issues-and-solutions)
9. [Example Commands](#example-commands)

## Introduction
This document provides comprehensive deployment guidance for the Discord bot application. It covers containerization using Docker, orchestration via docker-compose, integration with Google Cloud Secret Manager, and best practices for production deployment. The system is designed to be portable across environments while maintaining security and reliability through proper secret management and container configuration.

## Dockerfile Configuration
The Dockerfile defines a multi-stage build process optimized for Dart applications. It begins with the official `dart:stable` image, establishing a reliable Dart runtime environment. The build process first copies dependency specification files (`pubspec.*`) and installs dependencies using `dart pub get`. Afterward, the entire application source is copied into the container.

A secondary `dart pub get --offline` command ensures dependency consistency without requiring network access during the final build phase. The container entry point is defined using the `CMD` instruction to execute the main application file via `dart run bin/main.dart`. This configuration enables rapid container startup and consistent execution across environments.

The current configuration does not include AOT (Ahead-of-Time) compilation, as indicated by commented-out lines for binary compilation and executable permission setting. This suggests the application runs in JIT (Just-In-Time) mode within the container, prioritizing build simplicity over startup performance.

**Section sources**
- [Dockerfile](file://Dockerfile#L1-L22)

## Docker Compose Setup
The docker-compose.yml file orchestrates the bot service with environment isolation and network configuration. It defines a single service named `red-door-bot` that builds from the current directory context using the specified Dockerfile.

Environment variables are injected securely through the `env_file` directive, which loads variables from a `.env` file. This separation of configuration from code follows the twelve-factor app methodology. The service exposes port 24000 on the host, mapped to the same port in the container, enabling external connectivity for any network operations the bot may require.

The `restart: unless-stopped` policy ensures high availability by automatically restarting the container after system reboots or crashes, except when explicitly stopped by an operator. This configuration provides resilience in production environments while allowing controlled shutdowns for maintenance.

**Section sources**
- [docker-compose.yml](file://docker-compose.yml#L1-L12)

## Secrets Management with Google Cloud
The `create_secrets.sh` script enables integration with Google Cloud Secret Manager for secure secret storage. The script first validates the presence of a `.env` file in the current directory, providing clear error messaging if missing.

It processes each line of the `.env` file, skipping empty lines and comments. For valid key-value pairs, it transforms uppercase environment variable names with underscores into lowercase secret names with hyphens (e.g., `BOT_TOKEN` becomes `bot-token`). This naming convention aligns with Google Cloud's secret naming requirements.

Using the `gcloud secrets create` command, the script attempts to create each secret in the `red-door-bot` project with automatic replication. It handles the case where secrets already exist (exit code 6) by skipping creation rather than failing, enabling idempotent execution. The script outputs detailed progress information, including success messages and warnings, to guide users through the process.

The script requires appropriate IAM permissions to create secrets in the target project. Users must have the `secretmanager.secrets.create` permission on the project. The output reminds users to note the generated secret names for use in deployment workflows.

**Section sources**
- [create_secrets.sh](file://create_secrets.sh#L1-L50)

## Environment Configuration
The bot requires several environment variables to function correctly, as defined in the `envKeys` constant in `src/env.dart`. These include `BOT_TOKEN`, `FOOTER_TEXT`, `ADMIN_USER_ID`, `WAIFU_API_URL`, `GUILD_ID`, `AI_API_KEY`, `RED_DOOR_AI_PERSONA`, and `AI_MODEL`. All are marked as required.

The application implements a dual environment loading strategy through the `Env` abstract class and its concrete implementations: `FileBasedEnv` and `PlatformEnv`. Currently, the `envProvider` is configured to use `PlatformEnv`, which reads variables directly from the operating system's environment. The `FileBasedEnv` implementation, though commented out, demonstrates the capability to read from a `.env` file.

The `validate` method in the `Env` class performs comprehensive validation of required environment variables, collecting all missing variables before failing. This approach provides better user experience by reporting all missing configuration at once rather than failing on the first missing variable. The validation occurs during the `init` method call, ensuring configuration correctness before application startup.

**Section sources**
- [src/env.dart](file://src/env.dart#L1-L100)

## Deployment Workflows
### Development Environment
For development, use docker-compose with a local `.env` file:
1. Create `.env` with required variables
2. Run `docker-compose up --build` to build and start the container
3. Monitor logs for startup messages and errors
4. Use `docker-compose down` to stop and remove containers

### Production Environment
For production deployment:
1. Use `create_secrets.sh` to populate Google Cloud Secret Manager
2. Configure deployment platform (e.g., Google Cloud Run, Kubernetes) to retrieve secrets from Secret Manager
3. Deploy using the same Docker image built via the Dockerfile
4. Implement health checks and logging pipelines
5. Set up monitoring and alerting for container health and bot connectivity

The transition from development to production involves changing only the method of secret injection, not the application code or container image, ensuring consistency across environments.

## Best Practices
### Secret Management
- Never commit `.env` files to version control
- Use different Google Cloud projects for development and production
- Rotate secrets regularly and update them in Secret Manager
- Restrict IAM permissions to minimum required for secret access
- Use the script's idempotent nature to safely re-run during environment setup

### Container Networking
- Expose only necessary ports in production
- Use internal networks when multiple services need to communicate
- Implement network policies to restrict container-to-container communication
- Consider using a reverse proxy for any HTTP endpoints

### Process Monitoring
- Implement structured logging for easier log aggregation
- Set up health checks that verify bot connectivity to Discord
- Monitor container resource usage (CPU, memory)
- Use external monitoring tools to detect bot unresponsiveness
- Implement alerting for authentication failures or connection drops

## Common Issues and Solutions
### Missing Environment Variables
**Issue**: Application fails to start with "Environment variables are not set properly" error  
**Solution**: Verify all required variables are present in `.env` file or environment. Check for typos in variable names.

### Secret Creation Permission Errors
**Issue**: `gcloud secrets create` fails with permission denied  
**Solution**: Ensure service account has `Secret Manager Admin` role or equivalent permissions. Verify correct project is targeted.

### Container Build Failures
**Issue**: `dart pub get` fails during build  
**Solution**: Check internet connectivity in build environment. Verify `pubspec.yaml` syntax is correct.

### Bot Connection Issues
**Issue**: Bot fails to connect to Discord  
**Solution**: Validate `BOT_TOKEN` is correct and bot has necessary permissions in the guild. Check that `GUILD_ID` matches the target server.

### Port Conflicts
**Issue**: "Port already in use" error when starting container  
**Solution**: Change host port mapping in docker-compose.yml (e.g., `24001:24000`) or stop conflicting service.

## Example Commands
```bash
# Build and start the bot in development
docker-compose up --build -d

# View container logs
docker-compose logs -f

# Rebuild and restart the container
docker-compose up --build --force-recreate -d

# Stop and remove containers
docker-compose down

# Run the create_secrets script
./create_secrets.sh

# Manually create a secret (alternative to script)
echo -n "your-secret-value" | gcloud secrets create bot-token --project=red-door-bot --data-file=- --replication-policy=automatic

# List all secrets in the project
gcloud secrets list --project=red-door-bot

# Build Docker image manually
docker build -t red-door-bot -f Dockerfile .
```