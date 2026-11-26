# Serverless GraphQL Architecture with AWS RDS Integration

A production-grade, cost-optimized, and security-hardened **Serverless GraphQL Architecture** provisioned on AWS using **Terraform**, **Serverless Framework**, **AWS ECS Fargate**, **AWS Lambda**, **Amazon RDS (PostgreSQL)**, and **GitHub Actions CI/CD**.

---

## Architecture Overview

```mermaid
flowchart TB
    subgraph Users["End Users & CI/CD"]
        Client["React SPA Frontend<br/>(Browser / HTTPS)"]
        Dev["GitHub Repository<br/>(GitHub Actions CI/CD)"]
    end

    subgraph Edge["AWS Edge & Static Hosting"]
        CF["Amazon CloudFront<br/>(SSL/TLS + CDN Caching)"]
        S3["Amazon S3 Bucket<br/>(Private Origin via OAC)"]
    end

    subgraph VPC["Amazon VPC (10.0.0.0/16)"]
        subgraph PublicSubnets["Public Subnets (AZ-A & AZ-B)"]
            ALB["Internal / Edge ALB<br/>(HTTPS Termination)"]
            NAT["NAT Gateway<br/>(Outbound Patching/AWS APIs)"]
        end

        subgraph PrivateSubnets["Private Subnets (AZ-A & AZ-B - Zero Public IP)"]
            ECS["AWS ECS Fargate<br/>(Private Apollo GraphQL Server)"]
            Lambda["AWS Lambda (Node.js/TS)<br/>(Queries & Mutations Resolvers)"]
            RDS[("Amazon RDS PostgreSQL<br/>(db.t4g.micro - Encrypted)")]
        end
    end

    subgraph SecurityObs["Security, Secrets & Observability"]
        SM["AWS Secrets Manager<br/>(DB Credentials)"]
        IAM["AWS IAM<br/>(Least-Privilege Roles & OIDC)"]
        CW["Amazon CloudWatch<br/>(Logs, Metrics & Alarms)"]
        ECR["Amazon ECR<br/>(Container Registry)"]
    end

    Client -->|HTTPS| CF
    CF -->|OAC| S3
    Client -->|GraphQL Queries/Mutations/Subscriptions| ALB
    ALB --> ECS
    ECS -->|AWS SDK Invoke| Lambda
    ECS -->|Fetch Secrets| SM
    Lambda -->|SQL over TLS :5432| RDS
    Lambda -->|Fetch DB Creds| SM
    ECS -.->|Logs & Metrics| CW
    Lambda -.->|Logs & Metrics| CW
    RDS -.->|DB Metrics| CW
    Dev -->|OIDC Auth| IAM
    Dev -->|Push Image| ECR
    Dev -->|Deploy Infra & Lambdas| VPC
