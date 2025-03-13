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