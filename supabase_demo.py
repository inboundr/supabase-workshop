import os
from supabase import create_client, Client
from supabase.client import Client as SupabaseClient

# Supabase project URL and API key (hard-coded)
SUPABASE_URL = 'https://your-project.supabase.co'  # Replace with your actual Supabase project URL
SUPABASE_KEY = 'anon-key'  # Replace with your actual anon key

# Initialize the Supabase client with the anon key
supabase: SupabaseClient = create_client(SUPABASE_URL, SUPABASE_KEY)

# User credentials (for demo purposes)
users = [
    {'email': 'alice@companya.com', 'password': 'testtest'},
    {'email': 'bob@companya.com', 'password': 'testtest'},
    {'email': 'charlie@companyb.com', 'password': 'testtest'},
    {'email': 'david@companyb.com', 'password': 'testtest'},
]

# Helper function to authenticate and perform queries
def perform_query(email, password):
    print(f"\nLogging in as {email}...")

    try:
        # Sign in the user using the correct method signature
        credentials = {'email': email, 'password': password}
        auth_response = supabase.auth.sign_in_with_password(credentials)
        session = auth_response.session
        user_id = session.user.id
    except Exception as e:
        print(f"Authentication failed for {email}: {str(e)}")
        return

    if not session:
        print(f"Authentication failed for {email}: No session returned.")
        return

    print(f"Authenticated user ID: {user_id}")

    # Set the access token for authenticated requests
    access_token = session.access_token
    supabase.postgrest.auth(access_token)

    # Perform a select query on documents
    print(f"Attempting to retrieve documents for {email}...")
    try:
        documents_response = supabase.table('documents').select('*').execute()
        documents_data = documents_response.data
        print(f"Documents accessible by {email}:")
        for doc in documents_data:
            print(f"- {doc['name']} (Company ID: {doc['company_id']})")
    except Exception as e:
        print(f"Error retrieving documents for {email}: {str(e)}")

    # Perform a select query on document_sections
    print(f"\nAttempting to retrieve document sections for {email}...")
    try:
        sections_response = supabase.table('document_sections').select('*').execute()
        sections_data = sections_response.data
        print(f"Document sections accessible by {email}:")
        for section in sections_data:
            print(f"- Section ID: {section['id']}, Document ID: {section['document_id']}")
    except Exception as e:
        print(f"Error retrieving document sections for {email}: {str(e)}")

    # Sign out the user
    supabase.auth.sign_out()
    print(f"Signed out {email}.")

# Main execution: Perform queries for each user
if __name__ == "__main__":
    for user in users:
        perform_query(user['email'], user['password'])