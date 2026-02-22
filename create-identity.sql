-- Create identity record for the user
INSERT INTO auth.identities (id, user_id, identity_data, provider, created_at, updated_at) 
VALUES (
    'b1ba9cb4-1dcf-4738-9058-4158ce7126c3',
    'b1ba9cb4-1dcf-4738-9058-4158ce7126c3',
    '{"sub": "b1ba9cb4-1dcf-4738-9058-4158ce7126c3", "email": "Jso101196@gmail.com"}'::jsonb,
    'email',
    now(),
    now()
) ON CONFLICT DO NOTHING;
