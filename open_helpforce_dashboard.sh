#!/bin/bash

echo "Opening HelpForce Dashboard..."
echo "================================"
echo ""
echo "Login Credentials:"
echo "Email: admin@helpforce.test"
echo "Password: Password123!"
echo ""
echo "Opening browser to: http://localhost:3000"
echo ""

# Open the login page first
open "http://localhost:3000"

echo "After logging in, navigate to:"
echo "http://localhost:3000/app/accounts/1/settings/helpforce"
echo ""
echo "Or use the direct link after login:"
open "http://localhost:3000/app/accounts/1/settings/helpforce"