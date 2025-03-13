# Prompts ATB

This file contains prompts used in the application.

## Table of Contents

## Prompts

### Database Schema Conversion Prompt

```
Como un experto que eres en base de datos sql PostgreSQL,procede a convertir el ERD en formato mermaid que te voy a proporcionar, a un script SQL. Analiza la base de datos del código actual y el script SQL y expande la estructura de datos usando las migraciones de Prisma.Recuerda aplicar buenas practicas, como la definición de Indices y la normalización de la base datos, ya que el ERD proporcionado no cuenta con ello.

ERD:
erDiagram
     COMPANY {
         int id PK
         string name
     }
     EMPLOYEE {
         int id PK
         int company_id FK
         string name
         string email
         string role
         boolean is_active
     }
     POSITION {
         int id PK
         int company_id FK
         int interview_flow_id FK
         string title
         text description
         string status
         boolean is_visible
         string location
         text job_description
         text requirements
         text responsibilities
         numeric salary_min
         numeric salary_max
         string employment_type
         text benefits
         text company_description
         date application_deadline
         string contact_info
     }
     INTERVIEW_FLOW {
         int id PK
         string description
     }
     INTERVIEW_STEP {
         int id PK
         int interview_flow_id FK
         int interview_type_id FK
         string name
         int order_index
     }
     INTERVIEW_TYPE {
         int id PK
         string name
         text description
     }
     CANDIDATE {
         int id PK
         string firstName
         string lastName
         string email
         string phone
         string address
     }
     APPLICATION {
         int id PK
         int position_id FK
         int candidate_id FK
         date application_date
         string status
         text notes
     }
     INTERVIEW {
         int id PK
         int application_id FK
         int interview_step_id FK
         int employee_id FK
         date interview_date
         string result
         int score
         text notes
     }

     COMPANY ||--o{ EMPLOYEE : employs
     COMPANY ||--o{ POSITION : offers
     POSITION ||--|| INTERVIEW_FLOW : assigns
     INTERVIEW_FLOW ||--o{ INTERVIEW_STEP : contains
     INTERVIEW_STEP ||--|| INTERVIEW_TYPE : uses
     POSITION ||--o{ APPLICATION : receives
     CANDIDATE ||--o{ APPLICATION : submits
     APPLICATION ||--o{ INTERVIEW : has
     INTERVIEW ||--|| INTERVIEW_STEP : consists_of
     EMPLOYEE ||--o{ INTERVIEW : conducts
```

Este prompt fue utilizado para:
1. Convertir el ERD proporcionado en formato Mermaid a un script SQL completo
2. Crear un esquema Prisma correspondiente
3. Implementar buenas prácticas de base de datos como:
   - Normalización de datos
   - Creación de índices para optimizar consultas
   - Definición de tipos ENUM para campos de estado
   - Implementación de timestamps de auditoría
   - Configuración de restricciones y relaciones
   - Manejo apropiado de eliminación en cascada
   - Nombrado consistente de tablas y columnas

### Solución Implementada

#### 1. Script SQL

```sql
-- Create custom types
CREATE TYPE employment_type AS ENUM ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERNSHIP');
CREATE TYPE position_status AS ENUM ('DRAFT', 'PUBLISHED', 'CLOSED', 'ARCHIVED');
CREATE TYPE application_status AS ENUM ('PENDING', 'REVIEWING', 'SHORTLISTED', 'INTERVIEWING', 'OFFERED', 'REJECTED', 'WITHDRAWN');
CREATE TYPE interview_result AS ENUM ('PASSED', 'FAILED', 'PENDING');

-- Create tables with proper indexing and constraints

-- Company table
CREATE TABLE company (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_company_name ON company(name);

-- Employee table
CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employee_company_id ON employee(company_id);
CREATE INDEX idx_employee_email ON employee(email);

-- Interview Flow table
CREATE TABLE interview_flow (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Interview Type table
CREATE TABLE interview_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Position table
CREATE TABLE position (
    id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    interview_flow_id INTEGER NOT NULL REFERENCES interview_flow(id) ON DELETE RESTRICT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status position_status NOT NULL DEFAULT 'DRAFT',
    is_visible BOOLEAN DEFAULT false,
    location VARCHAR(100),
    job_description TEXT,
    requirements TEXT,
    responsibilities TEXT,
    salary_min DECIMAL(10,2),
    salary_max DECIMAL(10,2),
    employment_type employment_type NOT NULL,
    benefits TEXT,
    company_description TEXT,
    application_deadline DATE,
    contact_info TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_position_company_id ON position(company_id);
CREATE INDEX idx_position_interview_flow_id ON position(interview_flow_id);
CREATE INDEX idx_position_status ON position(status);
CREATE INDEX idx_position_employment_type ON position(employment_type);
CREATE INDEX idx_position_application_deadline ON position(application_deadline);

-- Interview Step table
CREATE TABLE interview_step (
    id SERIAL PRIMARY KEY,
    interview_flow_id INTEGER NOT NULL REFERENCES interview_flow(id) ON DELETE CASCADE,
    interview_type_id INTEGER NOT NULL REFERENCES interview_type(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(interview_flow_id, order_index)
);

CREATE INDEX idx_interview_step_flow_id ON interview_step(interview_flow_id);
CREATE INDEX idx_interview_step_type_id ON interview_step(interview_type_id);

-- Candidate table
CREATE TABLE candidate (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_candidate_email ON candidate(email);
CREATE INDEX idx_candidate_name ON candidate(first_name, last_name);

-- Application table
CREATE TABLE application (
    id SERIAL PRIMARY KEY,
    position_id INTEGER NOT NULL REFERENCES position(id) ON DELETE CASCADE,
    candidate_id INTEGER NOT NULL REFERENCES candidate(id) ON DELETE CASCADE,
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status application_status NOT NULL DEFAULT 'PENDING',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(position_id, candidate_id)
);

CREATE INDEX idx_application_position_id ON application(position_id);
CREATE INDEX idx_application_candidate_id ON application(candidate_id);
CREATE INDEX idx_application_status ON application(status);
CREATE INDEX idx_application_date ON application(application_date);

-- Interview table
CREATE TABLE interview (
    id SERIAL PRIMARY KEY,
    application_id INTEGER NOT NULL REFERENCES application(id) ON DELETE CASCADE,
    interview_step_id INTEGER NOT NULL REFERENCES interview_step(id) ON DELETE RESTRICT,
    employee_id INTEGER NOT NULL REFERENCES employee(id) ON DELETE RESTRICT,
    interview_date TIMESTAMP WITH TIME ZONE NOT NULL,
    result interview_result NOT NULL DEFAULT 'PENDING',
    score INTEGER CHECK (score >= 0 AND score <= 100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interview_application_id ON interview(application_id);
CREATE INDEX idx_interview_step_id ON interview(interview_step_id);
CREATE INDEX idx_interview_employee_id ON interview(employee_id);
CREATE INDEX idx_interview_date ON interview(interview_date);
CREATE INDEX idx_interview_result ON interview(result);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_company_updated_at
    BEFORE UPDATE ON company
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employee_updated_at
    BEFORE UPDATE ON employee
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_position_updated_at
    BEFORE UPDATE ON position
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interview_flow_updated_at
    BEFORE UPDATE ON interview_flow
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interview_type_updated_at
    BEFORE UPDATE ON interview_type
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interview_step_updated_at
    BEFORE UPDATE ON interview_step
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_candidate_updated_at
    BEFORE UPDATE ON candidate
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_application_updated_at
    BEFORE UPDATE ON application
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interview_updated_at
    BEFORE UPDATE ON interview
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### 2. Esquema Prisma

```prisma
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native", "debian-openssl-3.0.x"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum EmploymentType {
  FULL_TIME
  PART_TIME
  CONTRACT
  INTERNSHIP
}

enum PositionStatus {
  DRAFT
  PUBLISHED
  CLOSED
  ARCHIVED
}

enum ApplicationStatus {
  PENDING
  REVIEWING
  SHORTLISTED
  INTERVIEWING
  OFFERED
  REJECTED
  WITHDRAWN
}

enum InterviewResult {
  PASSED
  FAILED
  PENDING
}

model Company {
  id          Int         @id @default(autoincrement())
  name        String      @db.VarChar(100)
  employees   Employee[]
  positions   Position[]
  createdAt   DateTime    @default(now()) @map("created_at")
  updatedAt   DateTime    @updatedAt @map("updated_at")

  @@map("company")
}

model Employee {
  id          Int         @id @default(autoincrement())
  companyId   Int         @map("company_id")
  name        String      @db.VarChar(100)
  email       String      @unique @db.VarChar(255)
  role        String      @db.VarChar(100)
  isActive    Boolean     @default(true) @map("is_active")
  company     Company     @relation(fields: [companyId], references: [id], onDelete: Cascade)
  interviews  Interview[]
  createdAt   DateTime    @default(now()) @map("created_at")
  updatedAt   DateTime    @updatedAt @map("updated_at")

  @@map("employee")
}

model InterviewFlow {
  id              Int             @id @default(autoincrement())
  description     String
  positions       Position[]
  interviewSteps  InterviewStep[]
  createdAt       DateTime        @default(now()) @map("created_at")
  updatedAt       DateTime        @updatedAt @map("updated_at")

  @@map("interview_flow")
}

model InterviewType {
  id              Int             @id @default(autoincrement())
  name            String          @unique @db.VarChar(100)
  description     String?
  interviewSteps  InterviewStep[]
  createdAt       DateTime        @default(now()) @map("created_at")
  updatedAt       DateTime        @updatedAt @map("updated_at")

  @@map("interview_type")
}

model Position {
  id                  Int             @id @default(autoincrement())
  companyId           Int             @map("company_id")
  interviewFlowId     Int             @map("interview_flow_id")
  title               String          @db.VarChar(200)
  description         String?
  status              PositionStatus  @default(DRAFT)
  isVisible           Boolean         @default(false) @map("is_visible")
  location            String?         @db.VarChar(100)
  jobDescription      String?         @map("job_description")
  requirements        String?
  responsibilities    String?
  salaryMin           Decimal?        @map("salary_min") @db.Decimal(10, 2)
  salaryMax           Decimal?        @map("salary_max") @db.Decimal(10, 2)
  employmentType      EmploymentType  @map("employment_type")
  benefits            String?
  companyDescription  String?         @map("company_description")
  applicationDeadline DateTime?       @map("application_deadline")
  contactInfo         String?         @map("contact_info")
  company             Company         @relation(fields: [companyId], references: [id], onDelete: Cascade)
  interviewFlow       InterviewFlow   @relation(fields: [interviewFlowId], references: [id], onDelete: Restrict)
  applications        Application[]
  createdAt           DateTime        @default(now()) @map("created_at")
  updatedAt           DateTime        @updatedAt @map("updated_at")

  @@map("position")
}

model InterviewStep {
  id                Int             @id @default(autoincrement())
  interviewFlowId   Int             @map("interview_flow_id")
  interviewTypeId   Int             @map("interview_type_id")
  name              String          @db.VarChar(100)
  orderIndex        Int             @map("order_index")
  interviewFlow     InterviewFlow   @relation(fields: [interviewFlowId], references: [id], onDelete: Cascade)
  interviewType     InterviewType   @relation(fields: [interviewTypeId], references: [id], onDelete: Restrict)
  interviews        Interview[]
  createdAt         DateTime        @default(now()) @map("created_at")
  updatedAt         DateTime        @updatedAt @map("updated_at")

  @@unique([interviewFlowId, orderIndex])
  @@map("interview_step")
}

model Candidate {
  id            Int           @id @default(autoincrement())
  firstName     String        @map("first_name") @db.VarChar(100)
  lastName      String        @map("last_name") @db.VarChar(100)
  email         String        @unique @db.VarChar(255)
  phone         String?       @db.VarChar(20)
  address       String?
  applications  Application[]
  createdAt     DateTime      @default(now()) @map("created_at")
  updatedAt     DateTime      @updatedAt @map("updated_at")

  @@map("candidate")
}

model Application {
  id              Int             @id @default(autoincrement())
  positionId      Int             @map("position_id")
  candidateId     Int             @map("candidate_id")
  applicationDate DateTime        @default(now()) @map("application_date")
  status          ApplicationStatus @default(PENDING)
  notes           String?
  position        Position        @relation(fields: [positionId], references: [id], onDelete: Cascade)
  candidate       Candidate       @relation(fields: [candidateId], references: [id], onDelete: Cascade)
  interviews      Interview[]
  createdAt       DateTime        @default(now()) @map("created_at")
  updatedAt       DateTime        @updatedAt @map("updated_at")

  @@unique([positionId, candidateId])
  @@map("application")
}

model Interview {
  id              Int             @id @default(autoincrement())
  applicationId   Int             @map("application_id")
  interviewStepId Int             @map("interview_step_id")
  employeeId      Int             @map("employee_id")
  interviewDate   DateTime        @map("interview_date")
  result          InterviewResult @default(PENDING)
  score           Int?
  notes           String?
  application     Application     @relation(fields: [applicationId], references: [id], onDelete: Cascade)
  interviewStep   InterviewStep   @relation(fields: [interviewStepId], references: [id], onDelete: Restrict)
  employee        Employee        @relation(fields: [employeeId], references: [id], onDelete: Restrict)
  createdAt       DateTime        @default(now()) @map("created_at")
  updatedAt       DateTime        @updatedAt @map("updated_at")

  @@map("interview")
}
``` 