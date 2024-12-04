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