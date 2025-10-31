# Deployment Guide

This guide covers deployment options for the Real-Time Chat Application.

## Table of Contents
1. [Docker Deployment](#docker-deployment)
2. [Kubernetes Deployment](#kubernetes-deployment)
3. [Production Configuration](#production-configuration)
4. [Monitoring and Logging](#monitoring-and-logging)
5. [Backup and Recovery](#backup-and-recovery)

## Docker Deployment

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+

### Quick Start

1. Navigate to the backend directory:
```bash
cd backend
```

2. Build and start all services:
```bash
docker-compose up --build -d
```

3. Check service status:
```bash
docker-compose ps
```

4. View logs:
```bash
docker-compose logs -f
```

5. Stop all services:
```bash
docker-compose down
```

### Production Docker Deployment

For production, use a separate docker-compose file:

**docker-compose.prod.yml:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    restart: always

  auth-service:
    image: chat-auth-service:latest
    environment:
      DB_HOST: postgres
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      - postgres
    restart: always

  # ... other services

volumes:
  postgres_data:
  redis_data:
```

Deploy:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Kubernetes Deployment

### Prerequisites
- Kubernetes cluster (1.25+)
- kubectl configured
- Helm 3+ (optional)

### Database Setup

**postgres-deployment.yaml:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: chatdb
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
```

### Redis Setup

**redis-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  selector:
    app: redis
  ports:
  - port: 6379
```

### Microservices Deployment

**auth-service-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: chat-auth-service:latest
        env:
        - name: DB_HOST
          value: postgres
        - name: DB_NAME
          value: chatdb
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: secret
        ports:
        - containerPort: 8081
        livenessProbe:
          httpGet:
            path: /api/auth/health
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/auth/health
            port: 8081
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth-service
  ports:
  - port: 8081
```

### Secrets Management

Create secrets:
```bash
kubectl create secret generic db-secret \
  --from-literal=username=postgres \
  --from-literal=password=your-secure-password

kubectl create secret generic jwt-secret \
  --from-literal=secret=your-256-bit-jwt-secret
```

### Deploy All Services

```bash
kubectl apply -f postgres-deployment.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f auth-service-deployment.yaml
kubectl apply -f user-service-deployment.yaml
kubectl apply -f chat-service-deployment.yaml
kubectl apply -f gateway-deployment.yaml
kubectl apply -f frontend-deployment.yaml
```

### Ingress Configuration

**ingress.yaml:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chat-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: chat.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: gateway-service
            port:
              number: 8080
```

## Production Configuration

### Environment Variables

Create a `.env.production` file:
```bash
# Database
DB_HOST=postgres-production.example.com
DB_NAME=chatdb_prod
DB_USER=chatuser
DB_PASSWORD=strong-random-password

# Redis
REDIS_HOST=redis-production.example.com
REDIS_PORT=6379

# JWT
JWT_SECRET=generate-with-openssl-rand-base64-32

# Frontend
VITE_API_URL=https://api.chat.example.com
VITE_WS_URL=wss://api.chat.example.com/ws
```

### Security Hardening

1. **JWT Secret Generation:**
```bash
openssl rand -base64 32
```

2. **PostgreSQL SSL:**
Add to application.yml:
```yaml
spring:
  datasource:
    url: jdbc:postgresql://host:5432/db?ssl=true&sslmode=require
```

3. **Redis Authentication:**
```yaml
spring:
  data:
    redis:
      password: ${REDIS_PASSWORD}
```

4. **HTTPS/TLS:**
Configure SSL certificates in gateway and frontend nginx.

## Monitoring and Logging

### Prometheus Metrics

Add to pom.xml:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

Enable metrics in application.yml:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

### ELK Stack Integration

Add Logstash appender:
```xml
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>7.4</version>
</dependency>
```

### Health Checks

All services expose `/health` endpoints:
- Auth Service: http://localhost:8081/api/auth/health
- User Service: http://localhost:8082/api/users/health
- Chat Service: http://localhost:8083/api/chat/health

## Backup and Recovery

### PostgreSQL Backup

Automated daily backup:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgres"
docker exec chat-postgres pg_dump -U postgres chatdb | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Keep only last 30 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete
```

### Redis Backup

Redis RDB snapshots are automatic. Copy RDB file:
```bash
docker exec chat-redis redis-cli SAVE
docker cp chat-redis:/data/dump.rdb /backups/redis/dump_$(date +%Y%m%d).rdb
```

### Disaster Recovery

1. **Database Restore:**
```bash
gunzip -c backup.sql.gz | docker exec -i chat-postgres psql -U postgres chatdb
```

2. **Redis Restore:**
```bash
docker cp backup.rdb chat-redis:/data/dump.rdb
docker restart chat-redis
```

## Scaling Guidelines

### Horizontal Scaling

1. **Auth/User/Chat Services:**
   - Scale replicas in Kubernetes: `kubectl scale deployment auth-service --replicas=3`
   - Use Redis for session sharing

2. **Database:**
   - Use PostgreSQL read replicas for read-heavy operations
   - Configure connection pooling

3. **Redis:**
   - Use Redis Cluster for high availability
   - Configure Redis Sentinel for automatic failover

### Load Balancing

Configure nginx upstream:
```nginx
upstream backend {
    least_conn;
    server gateway-1:8080;
    server gateway-2:8080;
    server gateway-3:8080;
}
```

## Performance Optimization

1. **Database Indexing:**
   - Already included in init.sql
   - Monitor slow queries

2. **Redis Caching:**
   - Cache user profiles
   - Cache frequently accessed chat rooms

3. **Connection Pooling:**
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
```

4. **JVM Tuning:**
```bash
JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC"
```

## Troubleshooting

### Service Not Starting

1. Check logs: `docker-compose logs service-name`
2. Verify environment variables
3. Check database connectivity

### WebSocket Connection Failures

1. Ensure WebSocket path is configured correctly
2. Check CORS settings
3. Verify gateway routing

### High Memory Usage

1. Monitor with: `docker stats`
2. Adjust JVM heap size
3. Check for memory leaks in application

## Support and Maintenance

- Regular updates: Check for security updates monthly
- Database maintenance: Run VACUUM on PostgreSQL monthly
- Log rotation: Configure logrotate for application logs
- Backup verification: Test restore process quarterly
