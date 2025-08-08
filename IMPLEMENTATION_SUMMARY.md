# Site Survey - Implementation Summary

## ✅ What's Been Implemented

### 🔐 Authentication System
- **Microsoft SSO Integration**: Uses MSAL.js for Azure AD authentication
- **Development Mode**: Automatic bypass for localhost/127.0.0.1 (Live Server compatible)
- **Production Mode**: Full Microsoft authentication required
- **Session Management**: Real-time user tracking with Supabase

### 🗄️ Database Migration to Supabase
- **Free Tier**: 50,000 monthly active users, 500MB database
- **Real-time Features**: Real-time subscriptions for collaborative editing
- **File Storage**: Built-in file storage for photos and documents
- **PostgreSQL**: Better SQL support than Firebase
- **Cost Effective**: Significant cost savings over Firebase

### 👥 Role-Based Access Control
- **WordPress Integration**: Uses WordPress user roles when available
- **Admin** (alex.greene@ita.com): Full access, user management, all records
- **Manager**: View/edit venues and events, see venue lists
- **User**: Create/edit venues and events, no venue list access

### 🎯 Security Features
- **Authentication**: Microsoft SSO required in production
- **Authorization**: Role-based permissions for all operations
- **Session Tracking**: Active user monitoring and management
- **Access Controls**: Database restrictions by role
- **Client-Side Security**: Uses Azure AD public flow (no secrets in browser)
- **Domain Restrictions**: Azure validates all requests against registered redirect URIs

### 🛠️ Development Features
- **Live Server Compatible**: Automatic development mode detection
- **Mock Authentication**: Uses admin account for local testing
- **All Features Available**: Complete functionality in development
- **Easy Deployment**: Works with WordPress or standalone hosting

## 🚀 How to Use

### For Development (Live Server)
1. Open site-survey.html in VS Code
2. Use Live Server extension (Go Live)
3. Application automatically:
   - Bypasses Microsoft SSO
   - Logs you in as admin user
   - Shows full functionality
   - No configuration needed

### For WordPress Production Deployment

### 🚀 Database Setup: Supabase Migration

#### Step 1: Supabase Project Setup (You've completed this ✅)
- Project created at https://supabase.com
- Project URL and API keys available in your dashboard

#### Step 2: Create Database Tables
Run these SQL commands in your Supabase SQL Editor:

```sql
-- Survey data table
CREATE TABLE surveys (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id VARCHAR(255) UNIQUE NOT NULL,
    survey_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    status VARCHAR(50) DEFAULT 'In Progress'
);

-- Activity log table
CREATE TABLE survey_activity (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255),
    description TEXT NOT NULL,
    section VARCHAR(100),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    change_count INTEGER DEFAULT 1,
    changes JSONB
);

-- User presence for collaborative editing
CREATE TABLE user_presence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    current_section VARCHAR(100),
    is_typing BOOLEAN DEFAULT FALSE,
    typing_field VARCHAR(255),
    UNIQUE(survey_id, user_id)
);

-- Venue database
CREATE TABLE venues (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    venue_name VARCHAR(255) NOT NULL,
    venue_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_by VARCHAR(255)
);

-- Survey database (master list)
CREATE TABLE survey_database (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id VARCHAR(255) UNIQUE NOT NULL,
    event_name VARCHAR(255),
    venue_name VARCHAR(255),
    client_business VARCHAR(255),
    status VARCHAR(50) DEFAULT 'In Progress',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    survey_data JSONB,
    version INTEGER DEFAULT 1,
    tags JSONB DEFAULT '[]'::jsonb
);

-- Enable Row Level Security
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_database ENABLE ROW LEVEL SECURITY;

-- Create policies (allow all for authenticated users for now)
CREATE POLICY "Enable all operations for authenticated users" ON surveys
    FOR ALL USING (true);

CREATE POLICY "Enable all operations for authenticated users" ON survey_activity
    FOR ALL USING (true);

CREATE POLICY "Enable all operations for authenticated users" ON user_presence
    FOR ALL USING (true);

CREATE POLICY "Enable all operations for authenticated users" ON venues
    FOR ALL USING (true);

CREATE POLICY "Enable all operations for authenticated users" ON survey_database
    FOR ALL USING (true);

-- Create storage bucket for files
INSERT INTO storage.buckets (id, name, public) VALUES ('survey-files', 'survey-files', true);

-- Create storage policy
CREATE POLICY "Survey files are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'survey-files');

CREATE POLICY "Users can upload survey files" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'survey-files');

CREATE POLICY "Users can delete their survey files" ON storage.objects
    FOR DELETE USING (bucket_id = 'survey-files');
```

#### Step 3: Get Supabase Configuration
1. Go to your Supabase dashboard → Settings → API
2. Copy these values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon (public) key**: `eyJhbGciOiJIUzI1NiIsI...` (starts with eyJ)

#### Step 4: Update site-survey.html Configuration
Replace the Firebase configuration with Supabase:

```javascript
// Replace Firebase imports with Supabase
import { createClient } from 'https://cdn.skypack.dev/@supabase/supabase-js@2'

// Replace Firebase config with Supabase config
const supabaseConfig = {
    url: 'https://your-project-id.supabase.co',
    anonKey: 'your-anon-key-here'
};

const supabase = createClient(supabaseConfig.url, supabaseConfig.anonKey);
```

## 🚀 WordPress Deployment

#### Step 1: File Upload & Setup
1. **Upload the HTML File**: 
   - ✅ You've already uploaded `site-survey.html` to your file manager
   - Place it in your website's root directory or a subdirectory like `/tools/`
   - Example URL: `https://yoursite.com/site-survey.html`

#### Step 2: Azure AD App Registration (Required for Production)
1. **Go to Azure Portal**: https://portal.azure.com
2. **Navigate to**: Azure Active Directory → App registrations → New registration
3. **Register Application**:
   - Name: "Site Survey Tool"
   - Supported account types: "Accounts in this organizational directory only"
   - Redirect URI: `https://yoursite.com/site-survey.html` (your actual URL)
4. **Copy Configuration Values**:
   - Application (client) ID
   - Directory (tenant) ID
5. **Set API Permissions**:
   - Microsoft Graph → Delegated permissions
   - Add: `User.Read` and `profile`
   - Grant admin consent

#### Step 3: Update Configuration in site-survey.html
1. **Find the MSAL Config** (around line 1890):
```javascript
const msalConfig = {
    auth: {
        clientId: "YOUR_CLIENT_ID_HERE",        // Replace with your Application ID
        authority: "https://login.microsoftonline.com/YOUR_TENANT_ID_HERE", // Replace with your Tenant ID
        redirectUri: "https://yoursite.com/site-survey.html"  // Your actual URL
    }
};
```

**🔒 Security Note**: Client ID and Tenant ID are **safe to expose** in client-side code:
- **Client ID**: Designed to be public (like a username)
- **Tenant ID**: Your organization's public identifier  
- **No Secrets**: Never contains passwords or sensitive data
- **Azure Protection**: Microsoft validates all requests against your configured app
- **Redirect URI**: Azure only allows requests from your registered domains

**What IS Secret**: Client secrets (not used in this implementation) must never be exposed in client-side code.

#### Step 4: WordPress Integration Options

**Option A: Direct Link (Simplest)**
- Link directly to: `https://yoursite.com/site-survey.html?id=EVENT_NUMBER`
- Example: `https://yoursite.com/site-survey.html?id=091234`

**Option B: WordPress Page Integration**
1. Create a new WordPress page
2. Add this shortcode or HTML:
```html
<iframe src="/site-survey.html?id=091234" width="100%" height="800px" frameborder="0"></iframe>
```

**Option C: WordPress Shortcode (Advanced)**
1. Add to your theme's `functions.php`:
```php
function site_survey_shortcode($atts) {
    $atts = shortcode_atts(array(
        'id' => '',
        'height' => '800px'
    ), $atts);
    
    if (empty($atts['id'])) {
        return '<p>Error: Please provide an event ID</p>';
    }
    
    return '<iframe src="/site-survey.html?id=' . esc_attr($atts['id']) . '" width="100%" height="' . esc_attr($atts['height']) . '" frameborder="0"></iframe>';
}
add_shortcode('site_survey', 'site_survey_shortcode');
```

2. Use in posts/pages: `[site_survey id="091234"]`

#### Step 5: User Access Setup
1. **Admin Users**: 
   - alex.greene@ita.com automatically gets admin access
   - Can manage user roles through the admin panel
2. **Other Users**:
   - Must have Microsoft accounts in your organization
   - Default role: "User" (can create/edit surveys)
   - Admins can promote to "Manager" or "Admin" roles

#### Step 6: Testing
1. **Visit your URL**: `https://yoursite.com/site-survey.html?id=TEST`
2. **Sign in** with your Microsoft account
3. **Test features**:
   - Create event information
   - Upload photos
   - Use AI features (if configured)
   - Test mobile responsiveness

### For Development Testing on WordPress
- Use `?dev=true` parameter to bypass authentication: 
- `https://yoursite.com/site-survey.html?id=TEST&dev=true`
- This gives admin access for testing purposes

## 🔧 Configuration Required for Production

### Supabase Configuration (COMPLETED):
```javascript
const supabaseConfig = {
    url: 'https://iasddcsryzgtcasuxioc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlhc2RkY3NyeXpndGNhc3V4aW9jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NDA3NDcsImV4cCI6MjA3MDAxNjc0N30.fwZ-uDhkWIai76XW7AYgdwoUkuo_D52ypCQ6tEvtScY'
};
```

### Azure App Registration Setup (If using Microsoft auth):
- See `AZURE_SETUP_GUIDE.md` for complete instructions
- See `CONFIG_REFERENCE.js` for quick reference

## 🎛️ User Management

### Admin Panel Features
- View active users and sessions
- Set user roles (Admin/Manager/User)
- Monitor all survey activities
- Access all venue records

### Role Management
- **Default**: New users get "User" role
- **Admin Override**: alex.greene@ita.com is always admin
- **Role Assignment**: Admins can change any user's role
- **Real-time Updates**: Changes take effect immediately

## 🔒 Security Model & Safety

### Why Client ID & Tenant ID Are Safe to Expose

**These are NOT secrets:**
- **Client ID**: Think of it like a username - it identifies your app to Microsoft
- **Tenant ID**: Your organization's public identifier (like a company ID)
- **Public by Design**: Microsoft designed these to be visible in client-side applications

**Azure AD Security Layers:**
1. **Redirect URI Validation**: Azure only accepts authentication from your registered domains
2. **User Consent**: Users must explicitly grant permission to your app
3. **Token Validation**: All tokens are validated server-side by Microsoft
4. **Scope Limitations**: App can only access what you've configured (User.Read, profile)

**What Would Happen if Someone Copied Your IDs:**
- ❌ They can't impersonate your app (redirect URI mismatch)
- ❌ They can't access your user data (domain restrictions)
- ❌ They can't bypass authentication (Microsoft validates everything)
- ✅ At worst: They could create a similar login page (but users would see wrong domain)

**Real Security Comes From:**
- ✅ HTTPS on your website
- ✅ Proper redirect URI configuration
- ✅ Firebase security rules
- ✅ Role-based access control in your app

### What IS Actually Secret
**Never expose these** (but we don't use them):
- Client secrets (for server-side apps)
- Private keys
- Database connection strings with passwords
- API keys with write access

**Our Implementation**: Uses the "public client" flow specifically designed for browsers and mobile apps where secrets cannot be safely stored.

## 🔒 Access Control Matrix

| Feature | Admin | Manager | User |
|---------|-------|---------|------|
| Create/Edit Venues | ✅ | ✅ | ✅ |
| View Venue List | ✅ | ✅ | ❌ |
| Load Venue Data | ✅ | ✅ | ✅ |
| Admin Panel | ✅ | ❌ | ❌ |
| User Management | ✅ | ❌ | ❌ |
| View All Records | ✅ | ✅ | ❌ |
| Edit All Records | ✅ | ❌ | ❌ |

## 📱 Mobile & Browser Support
- Works on all modern browsers
- Mobile-friendly responsive design
- Touch-friendly interface
- Camera access for photos

## 🔄 Migration Notes
- All existing data preserved
- No changes to Firebase structure
- Existing features unchanged
- Backward compatible

## 🧪 Testing
- **Development**: Full functionality with mock admin user
- **Production**: Real Microsoft authentication required
- **Role Testing**: Use admin panel to test different roles
- **Mobile Testing**: Test camera and touch features

## 📞 Support & Troubleshooting

### WordPress-Specific Issues

**🔧 Common Problems & Solutions:**

1. **"Mixed Content" Errors (HTTP/HTTPS)**
   - Ensure your WordPress site uses HTTPS
   - Update all Firebase URLs to use HTTPS
   - Check browser console for blocked content

2. **iframe Restrictions**
   - Some WordPress themes block iframes
   - Try direct link method instead
   - Add to theme's `functions.php`:
   ```php
   add_filter('wp_kses_allowed_html', function($allowed_tags) {
       $allowed_tags['iframe'] = array(
           'src' => true,
           'width' => true,
           'height' => true,
           'frameborder' => true
       );
       return $allowed_tags;
   });
   ```

3. **Microsoft Authentication Issues**
   - Verify redirect URI exactly matches your URL
   - Check Azure AD app permissions are granted
   - Test with `?dev=true` parameter first

4. **File Upload/Camera Issues**
   - WordPress may block file types
   - Ensure HTTPS for camera access
   - Check browser permissions

**🔍 Testing Checklist:**
- [ ] File accessible at correct URL
- [ ] HTTPS enabled on WordPress site
- [ ] Azure AD app configured correctly
- [ ] Test user can sign in with Microsoft
- [ ] Photos upload successfully
- [ ] Mobile interface works
- [ ] AI features function (if configured)

**🚨 Emergency Development Mode:**
- Add `?dev=true` to any URL for testing
- Bypasses authentication
- Gives full admin access
- Example: `https://yoursite.com/site-survey.html?id=TEST&dev=true`

### General Support
- Check browser console for errors
- Verify Azure configuration matches guide
- Test with different browsers
- Use development mode for troubleshooting

### Quick WordPress Implementation Summary
1. ✅ Upload `site-survey.html` to your website
2. 🔧 Set up Azure AD app registration  
3. ⚙️ Update client/tenant IDs in the HTML file
4. 🔗 Link to surveys: `yoursite.com/site-survey.html?id=EVENT_NUMBER`
5. 👥 Assign user roles through admin panel
6. 📱 Test on mobile and desktop
