# Architecture

## Overview

- **Cloud:** AWS (eu-central-1 / Frankfurt)
- **Orchestration:** Kubernetes (EKS – Elastic Kubernetes Service)
- **Container registry:** AWS ECR
- **CI/CD:** GitHub Actions (build, test, image push, EKS deploy)
- **Two independent applications:** MERN stack (Project 1) and Python ETL (Project 2); both run in the same EKS cluster in separate namespaces.

## Components

| Component | Description |
|-----------|-------------|
| **VPC** | 10.0.0.0/16; 2 public subnets (different AZs). |
| **EKS cluster** | Single control plane; Kubernetes API and scheduler. |
| **EKS node group** | EC2 (t2/t3 small–medium); MERN and ETL pods run here. |
| **Namespace `mern`** | React frontend (Nginx), Express backend, MongoDB. |
| **Namespace `python`** | ETL CronJob (runs every hour). |
| **ECR** | case-mern-client, case-mern-server, case-etl images. |
| **GitHub Actions** | Separate workflows for MERN and ETL; push → build → ECR push → update on EKS. |
| **CloudWatch** | EKS control plane logs (api, audit, authenticator); alarms send to SNS. |
| **SNS** | Critical alarm notifications (optional email subscription). |

## Data flow – MERN

- User → Ingress/ALB (if configured) or port-forward → **mern-client** (React static, Nginx:80).
- **mern-client** → **mern-server** (Express:5050) → **mongo** (MongoDB:27017).
- All in `mern` namespace; services reach each other via ClusterIP and DNS names.

## Data flow – Python ETL

- CronJob `etl-cronjob` (schedule: `0 * * * *`) creates a Job every hour.
- Job runs a single pod; image is ECR’s `case-etl:latest`. Pod exits when done, Job completes.
