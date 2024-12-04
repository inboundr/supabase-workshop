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