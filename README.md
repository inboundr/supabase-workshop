# Supabase RLS Demo Repository

This repository demonstrates how to set up a multi-tenant application using Supabase's Row Level Security (RLS) policies. It includes:

- A PostgreSQL schema defining tables for companies, users, documents, and document sections.
- Sample data to populate the database.
- A Python script that authenticates users and demonstrates how RLS policies are enforced.
- Instructions to set up the demo environment from scratch.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [1. Create a Supabase Project](#1-create-a-supabase-project)
  - [2. Set Up the Database Schema](#2-set-up-the-database-schema)
  - [3. Insert Sample Data](#3-insert-sample-data)
  - [4. Create RLS Policies](#4-create-rls-policies)
  - [5. Set Up Supabase Auth Users](#5-set-up-supabase-auth-users)
  - [6. Set Up the Python Environment](#6-set-up-the-python-environment)
  - [7. Run the Python Script](#7-run-the-python-script)
- [Files in This Repository](#files-in-this-repository)
- [Notes](#notes)

## Prerequisites

- A [Supabase](https://supabase.com) account.
- [Python 3.7+](https://www.python.org/downloads/) installed on your machine.
- `pip` package manager.
- (Optional) [Git](https://git-scm.com/downloads) for version control.

## Setup Instructions

### 1. Create a Supabase Project

- Sign in to your Supabase account.
- Create a new project.
  - Note your project's **URL** and **anon key**; you'll need them later.

### 2. Set Up the Database Schema

- In the Supabase dashboard, navigate to **SQL Editor**.
- Create a new query and paste the contents of [`schema.sql`](#schemasql).

#### `schema.sql`

```sql
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
```

- Run the query to create the tables.

### 3. Insert Sample Data

- In the SQL Editor, create a new query and paste the contents of [`data.sql`](#datasql).

#### `data.sql`

```sql
-- data.sql

-- Insert sample companies
INSERT INTO companies (id, name) VALUES
  (1, 'Company A'),
  (2, 'Company B');

-- Insert sample users
-- Replace the UUIDs with actual user IDs after setting up Auth users
INSERT INTO users (id, email, company_id, role) VALUES
  ('<alice-uuid>', 'alice@companya.com', 1, 'Admin'),
  ('<bob-uuid>', 'bob@companya.com', 1, 'User'),
  ('<charlie-uuid>', 'charlie@companyb.com', 2, 'Admin'),
  ('<david-uuid>', 'david@companyb.com', 2, 'User');

-- Insert sample documents
INSERT INTO documents (id, name, owner_id, company_id) VALUES
  (1, 'Company A Document 1', '<alice-uuid>', 1),
  (2, 'Company A Document 2', '<bob-uuid>', 1),
  (3, 'Company B Document 1', '<charlie-uuid>', 2);

-- Insert sample document sections
INSERT INTO document_sections (id, document_id, content, embedding, company_id) VALUES
  (1, 1, 'Content of section 1 in Company A Document 1', NULL, 1),
  (2, 2, 'Content of section 1 in Company A Document 2', NULL, 1),
  (3, 3, 'Content of section 1 in Company B Document 1', NULL, 2);
```

- **Important:** The `<alice-uuid>`, `<bob-uuid>`, etc., placeholders need to be replaced with the actual UUIDs of the users from Supabase Auth. We'll get these IDs in [Step 5](#5-set-up-supabase-auth-users).

### 4. Create RLS Policies

- In the SQL Editor, run the following queries to set up the RLS policies:

```sql
-- RLS policies for documents table

-- SELECT policy: Users can select documents within their company
CREATE POLICY "Company-based select access on documents"
ON documents
FOR SELECT
USING (
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
);

-- INSERT policy: Users can insert documents within their company
CREATE POLICY "Company-based insert access on documents"
ON documents
FOR INSERT
WITH CHECK (
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    AND owner_id = auth.uid()
);

-- UPDATE policy: Users can update their own documents or if they are Admin
CREATE POLICY "Role-based update access on documents"
ON documents
FOR UPDATE
USING (
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    AND (
        owner_id = auth.uid() OR
        (SELECT role FROM users WHERE id = auth.uid()) = 'Admin'
    )
)
WITH CHECK (
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    AND (
        owner_id = auth.uid() OR
        (SELECT role FROM users WHERE id = auth.uid()) = 'Admin'
    )
);

-- DELETE policy: Users can delete their own documents or if they are Admin
CREATE POLICY "Role-based delete access on documents"
ON documents
FOR DELETE
USING (
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    AND (
        owner_id = auth.uid() OR
        (SELECT role FROM users WHERE id = auth.uid()) = 'Admin'
    )
);

-- RLS policies for document_sections table

-- SELECT policy: Users can select document sections of documents within their company
CREATE POLICY "Company-based select access on document_sections"
ON document_sections
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM documents
        WHERE documents.id = document_sections.document_id
        AND documents.company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    )
);

-- INSERT policy: Users can insert document sections into documents within their company
CREATE POLICY "Company-based insert access on document_sections"
ON document_sections
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM documents
        WHERE documents.id = document_sections.document_id
        AND documents.company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    )
);

-- UPDATE policy: Users can update document sections if they own the document or are Admin
CREATE POLICY "Role-based update access on document_sections"
ON document_sections
FOR UPDATE
USING (
    EXISTS (
        SELECT 1
        FROM documents
        WHERE documents.id = document_sections.document_id
        AND documents.company_id = (SELECT company_id FROM users WHERE id = auth.uid())
        AND (
            documents.owner_id = auth.uid() OR
            (SELECT role FROM users WHERE id = auth.uid()) = 'Admin'
        )
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM documents
        WHERE documents.id = document_sections.document_id
        AND documents.company_id = (SELECT company_id FROM users WHERE id = auth.uid())
        AND (
            documents.owner_id = auth.uid() OR
            (SELECT role FROM users WHERE id = auth.uid()) = 'Admin'
        )
    )
);

-- DELETE policy: Users can delete document sections if they own the document or are Admin
CREATE POLICY "Role-based delete access on document_sections"
ON document_sections
FOR DELETE
USING (
    EXISTS (
        SELECT 1
        FROM documents
        WHERE documents.id = document_sections.document_id
        AND documents.company_id = (SELECT company_id FROM users WHERE id = auth.uid())
        AND (
            documents.owner_id = auth.uid() OR
            (SELECT role FROM users WHERE id = auth.uid()) = 'Admin'
        )
    )
);
```

### 5. Set Up Supabase Auth Users

- Navigate to **Authentication** > **Users** in the Supabase dashboard.
- Create users with the following emails and passwords:

  - **Alice**
    - Email: `alice@companya.com`
    - Password: `password123`
  - **Bob**
    - Email: `bob@companya.com`
    - Password: `password123`
  - **Charlie**
    - Email: `charlie@companyb.com`
    - Password: `password123`
  - **David**
    - Email: `david@companyb.com`
    - Password: `password123`

- After creating each user, copy their **UUID** from the dashboard.
- Go back to [`data.sql`](#datasql) and replace `<alice-uuid>`, `<bob-uuid>`, etc., with the actual UUIDs.
- Re-run the updated `data.sql` script to insert the data with the correct user IDs.

### 6. Set Up the Python Environment

- Ensure you have Python 3.7 or higher installed.
- Clone the repository or copy the files to your local machine.
- Create a virtual environment (optional but recommended):

  ```bash
  python -m venv venv
  ```

- Activate the virtual environment:

  - On Windows:

    ```bash
    venv\Scripts\activate
    ```

  - On macOS/Linux:

    ```bash
    source venv/bin/activate
    ```

- Install the required packages using `requirements.txt`:

  ```bash
  pip install -r requirements.txt
  ```

#### `requirements.txt`

```plaintext
supabase==2.10.0
```

### 7. Run the Python Script

- Open `supabase_demo.py` and update the `SUPABASE_URL` and `SUPABASE_KEY` variables with your project's URL and **anon key**.

  ```python
  # Supabase project URL and API key (hard-coded)
  SUPABASE_URL = 'https://your-project.supabase.co'  # Replace with your actual Supabase project URL
  SUPABASE_KEY = 'your-anon-key'  # Replace with your actual anon key
  ```

- Run the script:

  ```bash
  python supabase_demo.py
  ```

- You should see output showing each user's access to documents and document sections, demonstrating how RLS policies are enforced.

## Files in This Repository

- **`schema.sql`**: Contains SQL commands to create the database schema.
- **`data.sql`**: Contains SQL commands to insert sample data.
- **`supabase_demo.py`**: The Python script that demonstrates RLS policies.
- **`requirements.txt`**: Lists Python dependencies.

## Notes

- **User IDs Matching**: Ensure that the user IDs in the `users` table match the UUIDs from Supabase Auth; otherwise, the RLS policies will not work as expected.
- **RLS Policies**: The script uses the Supabase **anon key** to initialize the client, ensuring that RLS policies are respected.
- **Security**: Do not share your Supabase **anon key** or **service role key** publicly.
- **Environment Variables**: While we've hard-coded the API key and URL for simplicity, consider using environment variables for better security in real applications.

---

**Feel free to explore the code and modify it to suit your needs. If you have any questions or need further assistance, please reach out!**
