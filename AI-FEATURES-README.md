# AI-Enhanced Site Survey Application

## 🤖 AI Features Overview

This application now includes powerful AI assistance capabilities using OpenAI's API to help automate agenda analysis and provide real-time suggestions during site surveys.

## 🔧 Setup Instructions

### 1. Get Your OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key (starts with `sk-`)
5. Copy and securely store your key

### 2. Configure AI in the Application
1. Open the site survey application
2. Click the **"🤖 AI Assistant"** button in the header
3. Enter your OpenAI API key in the configuration modal
4. Click **"Save API Key"** and then **"Test Connection"**
5. Enable **"AI Assistance"** for real-time suggestions
6. Enable **"Agenda Analysis"** for document processing

## 📋 Key Features

### Agenda Analysis
- **Upload Support**: PDF, DOC, DOCX, and image files
- **Automatic Extraction**: Event details, schedule, venue requirements
- **Smart Suggestions**: Room layouts, session breakdowns, AV needs
- **One-Click Apply**: Automatically populate survey fields

### Real-Time AI Assistance
- **Context-Aware**: Suggestions based on current section and data
- **AV Recommendations**: Equipment suggestions based on event type
- **Technical Guidance**: Site survey best practices and considerations
- **Question Prompts**: Important questions to ask during surveys

### Secure API Key Management
- **Session Storage**: Keys stored only in browser session
- **No Server Storage**: API key never sent to application servers
- **Privacy First**: Direct communication with OpenAI only

## 🚀 Using Agenda Analysis

### Step 1: Upload Agenda
1. Navigate to the **"General"** section
2. Find the **"Agenda"** upload area
3. Drag and drop files or click to browse
4. Supported formats: PDF, DOC, DOCX, JPG, PNG

### Step 2: AI Analysis Prompt
- When you upload an agenda, you'll see an AI analysis prompt
- Choose **"Yes, analyze with AI"** to proceed
- Or click **"No, I'll fill manually"** to skip

### Step 3: Review Results
- AI will extract and display:
  - Event information (name, dates, attendees)
  - Venue requirements
  - Suggested room layouts
  - Session schedules
  - AV equipment needs

### Step 4: Apply Suggestions
- Review the analysis results
- Click **"Apply AI Suggestions"** to auto-fill survey fields
- Or click **"No, I'll fill manually"** to proceed without applying

## 🧠 Real-Time AI Assistance

### Activating AI Assistance
1. Configure your API key (see Setup Instructions)
2. Enable **"AI Assistance"** in the AI settings
3. The AI suggestions panel will appear on the right side

### How It Works
- AI analyzes your current survey data and active section
- Provides context-aware suggestions for:
  - AV equipment recommendations
  - Technical considerations
  - Important questions to ask
  - Potential challenges to watch for
  - Setup best practices

### Suggestion Categories
- **Equipment**: Microphones, projectors, lighting, etc.
- **Technical**: Power requirements, internet needs, setup logistics
- **Questions**: Key questions to ask venue staff
- **Challenges**: Common issues to anticipate
- **Best Practices**: Professional recommendations

## 📁 File Processing Capabilities

### Document Types
- **PDF Files**: Full text extraction using PDF.js
- **Word Documents**: Text extraction using Mammoth.js
- **Images**: OCR text recognition using Tesseract.js

### What AI Can Extract
- Event names and descriptions
- Dates and scheduling information
- Attendee counts and expectations
- Session details and breakdowns
- Room requirements and layouts
- AV equipment specifications
- Venue location requirements
- Special technical needs

## 🔒 Security & Privacy

### API Key Security
- Keys stored in browser sessionStorage only
- Cleared when browser session ends
- Never transmitted to application servers
- Direct secure connection to OpenAI API

### Data Privacy
- Survey data sent to OpenAI only when explicitly requested
- No automatic data transmission
- User controls all AI interactions
- Can disable AI features at any time

### Best Practices
- Use a dedicated API key for this application
- Set usage limits in your OpenAI account
- Monitor API usage through OpenAI dashboard
- Regularly rotate API keys

## 💡 Tips for Best Results

### Agenda Upload Tips
- Use high-quality scans for image files
- Ensure PDF files contain selectable text (not just images)
- Upload complete agenda documents rather than partial files
- Include session details and timing information

### AI Assistance Tips
- Fill in basic event information first for better context
- Use descriptive venue names and event types
- Include attendee counts for better equipment recommendations
- Review AI suggestions before applying - they're starting points, not final answers

## 🛠️ Troubleshooting

### Common Issues

**"API connection failed"**
- Verify your API key is correct and starts with 'sk-'
- Check your OpenAI account has available credits
- Ensure you have internet connectivity

**"Failed to extract text"**
- Try a different file format (PDF works best)
- Ensure images are high quality and text is clearly readable
- Check file size is under 10MB

**"AI analysis failed"**
- Verify the uploaded document contains readable text
- Try uploading a simpler document format
- Check OpenAI API status at status.openai.com

**"No suggestions appearing"**
- Ensure AI Assistance is enabled in settings
- Verify API key is configured and tested
- Try entering more event details for better context

### Performance Notes
- Large files may take longer to process
- OCR on images requires more processing time
- Complex documents may need manual review of AI suggestions

## 📞 Support

For technical issues:
1. Check browser console for error messages
2. Verify API key configuration
3. Test with simple documents first
4. Review OpenAI API documentation for rate limits

## 🔄 Updates

The AI features are designed to evolve with your needs. Future enhancements may include:
- Support for additional document formats
- Enhanced venue database integration
- Automated equipment ordering suggestions
- Integration with calendar systems
- Multi-language support

---

**Note**: AI suggestions are meant to assist and accelerate your work, but should always be reviewed by experienced technicians. The AI provides starting points and recommendations based on common practices, but every event is unique and may require custom solutions.
