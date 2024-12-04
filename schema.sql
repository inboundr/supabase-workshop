-- schema.sql

-- Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create companies table
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    company_id INTEGER REFERENCES companies(id),
    role TEXT CHECK (role IN ('User', 'Admin')) DEFAULT 'User'
);

-- Create documents table
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id) DEFAULT auth.uid(),
    company_id INTEGER REFERENCES companies(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create document_sections table
CREATE TABLE document_sections (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL REFERENCES documents(id),
    content TEXT NOT NULL,
    embedding VECTOR(384),
    company_id INTEGER REFERENCES companies(id)
);

-- Enable Row Level Security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_sections ENABLE ROW LEVEL SECURITY;