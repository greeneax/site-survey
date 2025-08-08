/* CONFIGURATION REFERENCE - Site Survey Microsoft SSO */

/* 
 * AZURE APP REGISTRATION CONFIGURATION NEEDED:
 * 
 * 1. Client ID: [Your Application (client) ID from Azure]
 * 2. Tenant ID: [Your Directory (tenant) ID from Azure]
 * 
 * Replace these values in site-survey.html around line 1890:
 */

const msalConfig = {
    auth: {
        clientId: "YOUR_CLIENT_ID_HERE",
        authority: "https://login.microsoftonline.com/YOUR_TENANT_ID_HERE",
        redirectUri: window.location.origin
    },
    cache: {
        cacheLocation: "localStorage",
        storeAuthStateInCookie: false
    }
};

/* 
 * REDIRECT URIS TO ADD IN AZURE:
 * 
 * For Production:
 * - https://yourdomain.com/site-survey/
 * - https://yourdomain.com/site-survey/site-survey.html
 * 
 * For Development (Live Server):
 * - http://localhost:5500
 * - http://127.0.0.1:5500
 * - http://localhost:5500/site-survey.html
 * - http://127.0.0.1:5500/site-survey.html
 */

/* 
 * MICROSOFT GRAPH PERMISSIONS NEEDED:
 * - User.Read
 * - profile
 * - openid  
 * - email
 */

/* 
 * USER ROLES DEFINED:
 * - admin: alex.greene@ita.com (hardcoded) + configurable via Admin Panel
 * - manager: Configurable via Admin Panel
 * - user: Default role for new users
 */

/* 
 * DEVELOPMENT MODE:
 * - Automatically activates on localhost/127.0.0.1
 * - Uses mock admin user for testing
 * - All features work without Azure configuration
 */
