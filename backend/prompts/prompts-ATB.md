# Prompts ATB

This file contains prompts used in the application.

## Table of Contents

## Prompts

### Database Schema Conversion Prompt

```
Como un experto que eres en base de datos sql PostgreSQL,procede a convertir el ERD en formato mermaid que te voy a proporcionar, a un script SQL. Analiza la base de datos del código actual y el script SQL y expande la estructura de datos usando las migraciones de Prisma.Recuerda aplicar buenas practicas, como la definición de Indices y la normalización de la base datos, ya que el ERD proporcionado no cuenta con ello.

ERD:
erDiagram
     CANDIDATE {
         int id PK
         string firstName
         string lastName
         string email
         string phone
         string address
     }
     EDUCATION {
         int id PK
         int candidate_id FK
         string institution
         string title
         datetime startDate
         datetime endDate
     }
     WORK_EXPERIENCE {
         int id PK
         int candidate_id FK
         string company
         string position
         string description
         datetime startDate
         datetime endDate
     }
     RESUME {
         int id PK
         int candidate_id FK
         string filePath
         string fileType
         datetime uploadDate
     }

     CANDIDATE ||--o{ EDUCATION : has
     CANDIDATE ||--o{ WORK_EXPERIENCE : has
     CANDIDATE ||--o{ RESUME : has
```

Este prompt fue utilizado para:
1. Convertir el ERD proporcionado en formato Mermaid a un script SQL completo
2. Crear un esquema Prisma correspondiente
3. Implementar buenas prácticas de base de datos como:
   - Normalización de datos
   - Creación de índices para optimizar consultas
   - Implementación de timestamps de auditoría
   - Configuración de restricciones y relaciones
   - Manejo apropiado de eliminación en cascada
   - Nombrado consistente de tablas y columnas

### Solución Implementada

#### 1. Script SQL

```sql
-- Create tables with proper indexing and constraints

-- Candidate table
CREATE TABLE candidate (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(15),
    address VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_candidate_email ON candidate(email);
CREATE INDEX idx_candidate_name ON candidate(first_name, last_name);

-- Education table
CREATE TABLE education (
    id SERIAL PRIMARY KEY,
    institution VARCHAR(100) NOT NULL,
    title VARCHAR(250) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    candidate_id INTEGER NOT NULL REFERENCES candidate(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_education_candidate_id ON education(candidate_id);
CREATE INDEX idx_education_institution ON education(institution);
CREATE INDEX idx_education_dates ON education(start_date, end_date);

-- Work Experience table
CREATE TABLE work_experience (
    id SERIAL PRIMARY KEY,
    company VARCHAR(100) NOT NULL,
    position VARCHAR(100) NOT NULL,
    description VARCHAR(200),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    candidate_id INTEGER NOT NULL REFERENCES candidate(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_work_experience_candidate_id ON work_experience(candidate_id);
CREATE INDEX idx_work_experience_company ON work_experience(company);
CREATE INDEX idx_work_experience_dates ON work_experience(start_date, end_date);

-- Resume table
CREATE TABLE resume (
    id SERIAL PRIMARY KEY,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    upload_date TIMESTAMP WITH TIME ZONE NOT NULL,
    candidate_id INTEGER NOT NULL REFERENCES candidate(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_resume_candidate_id ON resume(candidate_id);
CREATE INDEX idx_resume_upload_date ON resume(upload_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_candidate_updated_at
    BEFORE UPDATE ON candidate
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_education_updated_at
    BEFORE UPDATE ON education
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_experience_updated_at
    BEFORE UPDATE ON work_experience
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resume_updated_at
    BEFORE UPDATE ON resume
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### 2. Esquema Prisma

```prisma
generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native", "debian-openssl-3.0.x"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Candidate {
  id                Int               @id @default(autoincrement())
  firstName         String            @map("first_name") @db.VarChar(100)
  lastName          String            @map("last_name") @db.VarChar(100)
  email             String            @unique @db.VarChar(255)
  phone             String?           @db.VarChar(15)
  address           String?           @db.VarChar(100)
  educations        Education[]
  workExperiences   WorkExperience[]
  resumes           Resume[]
  createdAt         DateTime          @default(now()) @map("created_at")
  updatedAt         DateTime          @updatedAt @map("updated_at")

  @@map("candidate")
}

model Education {
  id            Int       @id @default(autoincrement())
  institution   String    @db.VarChar(100)
  title         String    @db.VarChar(250)
  startDate     DateTime  @map("start_date")
  endDate       DateTime? @map("end_date")
  candidateId   Int       @map("candidate_id")
  candidate     Candidate @relation(fields: [candidateId], references: [id], onDelete: Cascade)
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @updatedAt @map("updated_at")

  @@map("education")
}

model WorkExperience {
  id          Int       @id @default(autoincrement())
  company     String    @db.VarChar(100)
  position    String    @db.VarChar(100)
  description String?   @db.VarChar(200)
  startDate   DateTime  @map("start_date")
  endDate     DateTime? @map("end_date")
  candidateId Int       @map("candidate_id")
  candidate   Candidate @relation(fields: [candidateId], references: [id], onDelete: Cascade)
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @updatedAt @map("updated_at")

  @@map("work_experience")
}

model Resume {
  id          Int       @id @default(autoincrement())
  filePath    String    @map("file_path") @db.VarChar(500)
  fileType    String    @map("file_type") @db.VarChar(50)
  uploadDate  DateTime  @map("upload_date")
  candidateId Int       @map("candidate_id")
  candidate   Candidate @relation(fields: [candidateId], references: [id], onDelete: Cascade)
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @updatedAt @map("updated_at")

  @@map("resume")
}
``` 