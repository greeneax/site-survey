# Microsoft SSO Setup Guide for Site Survey Application

## Overview
This guide will help you configure Microsoft Single Sign-On (SSO) authentication for your site survey application with role-based access control.

## Security Levels Implemented

### Admin (alex.greene@ita.com)
- **Full Access**: Can see who's logged in, manage users, view/edit all records
- **Admin Panel**: Access to user management and system statistics
- **Permissions**: 
  - View all records
  - Edit all records  
  - Manage users
  - View user list
  - Delete records

### Manager
- **Data Access**: Can see and edit venue and event records
- **Limited Admin**: Cannot manage users or see user lists
- **Permissions**:
  - View all records
  - Edit all records
  - Cannot manage users
  - Cannot view user lists
  - Cannot delete records

### User (Default)
- **Basic Access**: Can add/edit venues and events, see venue list
- **Restricted View**: Cannot see full record details of other users' work
- **Permissions**:
  - Cannot view all records (only venue list)
  - Can edit records they create
  - Cannot manage users
  - Cannot view user lists
  - Cannot delete records

## Step 1: Azure App Registration

1. **Sign in to Azure Portal**
   - Go to [Azure Portal](https://portal.azure.com)
   - Sign in with your admin account

2. **Navigate to App Registrations**
   - Search for "App registrations" in the top search bar
   - Click on "App registrations"

3. **Create New Registration**
   - Click "New registration"
   - Fill in the details:
     - **Name**: `Site Survey Application`
     - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
     - **Redirect URI**: Select "Single-page application (SPA)" and enter your domain:
       - For testing: `http://localhost:8080` or your local server
       - For production: `https://yourdomain.com`

4. **Copy Important Values**
   After registration, copy these values from the Overview page:
   - **Application (client) ID**: This will replace `YOUR_CLIENT_ID` in the code
   - **Directory (tenant) ID**: This will replace `YOUR_TENANT_ID` in the code

## Step 2: Configure App Registration

1. **Set Redirect URIs**
   - Go to "Authentication" in the left menu
   - Under "Single-page application", add all possible URLs where your app will be hosted:
     - `http://localhost:8080`
     - `https://yourdomain.com`
     - Any other domains you'll use

2. **API Permissions**
   - Go to "API permissions" in the left menu
   - Ensure you have:
     - Microsoft Graph > User.Read (should be added by default)
   - Click "Grant admin consent" if required

3. **Optional: Branding**
   - Go to "Branding & properties"
   - Add your company logo and information

## Step 3: Update Application Code

1. **Replace Configuration Values**
   In your `site-survey.html` file, find this section and update it:

   ```javascript
   const msalConfig = {
       auth: {
           clientId: "YOUR_CLIENT_ID", // Replace with your Application (client) ID
           authority: "https://login.microsoftonline.com/YOUR_TENANT_ID", // Replace with your Directory (tenant) ID
           redirectUri: window.location.origin
       },
       cache: {
           cacheLocation: "sessionStorage",
           storeAuthStateInCookie: false
       }
   };
   ```

2. **Update User Role Mapping**
   Find the `USER_ROLE_MAPPING` object and add your users:

   ```javascript
   const USER_ROLE_MAPPING = {
       'alex.greene@ita.com': USER_ROLES.ADMIN,
       'manager1@ita.com': USER_ROLES.MANAGER,
       'manager2@ita.com': USER_ROLES.MANAGER,
       'user1@ita.com': USER_ROLES.USER,
       'user2@ita.com': USER_ROLES.USER,
       // Add more users as needed
   };
   ```

## Step 4: Testing

1. **Local Testing**
   - Serve your HTML file on a local web server
   - Access it via `http://localhost:8080` (or your configured port)
   - Try logging in with different user accounts

2. **User Access Testing**
   - Test with alex.greene@ita.com - should see Admin panel
   - Test with a manager account - should see all sections but no admin panel
   - Test with a user account - should see limited access

3. **Unauthorized User Testing**
   - Try logging in with an email not in the USER_ROLE_MAPPING
   - Should see "Access denied" message

## Step 5: Production Deployment

1. **Update Redirect URIs**
   - Add your production domain to the Azure App Registration
   - Update the redirect URIs in Azure

2. **HTTPS Requirement**
   - Microsoft SSO requires HTTPS in production
   - Ensure your WordPress site has SSL enabled

3. **WordPress Integration**
   - Upload the HTML file to your WordPress site
   - You can embed it in a page using an HTML block or create a custom page template

## Security Features Implemented

### Authentication
- Microsoft SSO with organizational accounts only
- Session-based authentication with MSAL
- Automatic logout on session expiry

### Authorization  
- Role-based access control (RBAC)
- Permission checks on all data operations
- UI elements hidden/shown based on permissions

### Data Protection
- Read-only modes for restricted users
- Photo deletion permissions
- Activity logging with user attribution

### User Tracking
- Active user monitoring in Firestore
- Session tracking with last seen timestamps
- User role display in activity logs

## Troubleshooting

### Common Issues

1. **"Access denied" for authorized users**
   - Check that the email address exactly matches in USER_ROLE_MAPPING
   - Verify the user is signing in with the correct organizational account

2. **Login popup blocked**
   - Ensure popups are allowed for your domain
   - Try using redirect instead of popup (requires code change)

3. **CORS errors**
   - Ensure your domain is properly configured in Azure App Registration
   - Check that you're serving over HTTPS in production

4. **Users can't see content**
   - Verify user roles are properly assigned
   - Check hasPermission() function calls in the code

### Firebase Security Rules

You may want to add these Firestore security rules for additional protection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Survey data - authenticated users only
    match /artifacts/{surveyId}/public/data/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Venue database - authenticated users only  
    match /venueDatabase/{venueId} {
      allow read, write: if request.auth != null;
    }
    
    // Active users tracking - authenticated users only
    match /activeUsers/{userId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Support

If you need help with setup or encounter issues:

1. Check the browser console for error messages
2. Verify all configuration values are correct
3. Test with a simple user first before adding complex scenarios
4. Ensure your Azure subscription has the necessary permissions

## Adding New Users

To add new users to the system:

1. Add their email and role to the `USER_ROLE_MAPPING` object in the code
2. Redeploy the application
3. The user can now sign in with their Microsoft organizational account

The system will automatically handle permissions based on their assigned role.
