# Criminal Tracking System - Mobile App

A comprehensive Flutter mobile application for tracking criminal records and managing crime reports in Rwanda.

## 🚀 Features

### **Public Features**
- **Criminal Search**: Search for criminals by ID number or passport
- **News Section**: View arrested criminals with photos and details
- **Multilingual Support**: Kinyarwanda and English messages

### **User Features (Login Required)**
- **Unified Reporting**: Report both victims and criminals in one interface
- **NIDA Integration**: Auto-fill personal data from national database
- **Photo Upload**: Add criminal photos with arrest records
- **Notification System**: Send alerts to RIB for criminal sightings

### **Admin Features**
- **Dashboard**: Comprehensive statistics and crime data visualization
- **Criminal Records Management**: Full CRUD operations
- **Victim Reports Management**: Manage and track victim reports
- **Arrested Criminals**: Register arrests and publish to news
- **User Management**: Approve users and manage permissions
- **Notification Management**: Process criminal sighting alerts

## 🏗️ Architecture

### **Database Schema**
The app integrates with PostgreSQL database with the following tables:
- `rwandan_citizen` - NIDA citizen data
- `passport_holder` - Foreign passport holders
- `criminal_record` - Criminal records
- `victim` - Victim reports
- `criminals_arrested` - Arrested criminals for news
- `notification` - Alert notifications
- `users` - System users

### **API Integration**
Base URL: `https://tracking-criminal.onrender.com/api/v1`

#### **Criminal Records**
- `GET /criminal-records/search/:idNumber` - Search person by ID
- `GET /criminal-records` - Get all criminal records (paginated)
- `POST /criminal-records` - Add criminal record
- `PUT /criminal-records/:id` - Update criminal record
- `DELETE /criminal-records/:id` - Delete criminal record
- `GET /criminal-records/recent` - Get recent records
- `GET /criminal-records/statistics` - Get crime statistics

#### **Victims**
- `POST /victims` - Add victim record
- `GET /victims` - Get all victims (paginated)
- `GET /victims/:id` - Get victim by ID
- `PUT /victims/:id` - Update victim record
- `DELETE /victims/:id` - Delete victim record
- `GET /victims/recent` - Get recent victims
- `GET /victims/statistics` - Get victim statistics

#### **Notifications**
- `POST /notifications` - Send notification
- `GET /notifications` - Get all notifications (paginated)
- `GET /notifications/:id` - Get notification by ID
- `DELETE /notifications/:id` - Delete notification
- `GET /notifications/stats/rib-statistics` - Get notification stats

#### **User Management**
- `GET /users` - Get all users
- `GET /users/pending` - Get pending approvals
- `PUT /users/:id/approval` - Approve/reject user
- `DELETE /users/:id` - Delete user
- `GET /auth/verify-email/:token` - Verify email
- `POST /auth/forgot-password` - Reset password
- `POST /auth/change-password` - Change password

#### **Arrested Criminals**
- `POST /arrested` - Add arrested criminal
- `GET /arrested` - Get all arrested criminals
- `PUT /arrested/:id` - Update arrested criminal
- `DELETE /arrested/:id` - Delete arrested criminal
- `GET /arrested/statistics` - Get arrest statistics

## 📱 App Workflow

### **Step 1: Home Screen**
- Shows search bar, login button, and news section
- Users can search for criminals without login
- Public access to news and alerts

### **Step 2: Authentication**
- Users and admins can login
- Role-based access control
- Email verification system

### **Step 3: Crime Reporting (Logged-in Users)**
- Select report type: Victim or Criminal
- Enter ID number for auto-fill from NIDA
- Supports multiple ID types:
  - `indangamuntu_yumunyarwanda` (Rwandan National ID)
  - `indangamuntu_yumunyamahanga` (Foreign National ID)
  - `indangampunzi` (Refugee ID)
  - `passport` (Passport)

### **Step 4: Auto-fill Process**
- System searches `rwandan_citizen` and `passport_holder` tables
- If found: Auto-fills personal information
- If not found: Shows "Not registered in NIDA" message
- User completes remaining crime-specific details

### **Step 5: Search Results**
- **Criminal Found**: Shows "WAHUNZE UBUTABERA" (committed crime)
- **Clean Record**: Shows "Uri umwere ntago wahunze ubutabera" (no crimes)
- Option to send alert notification to RIB

### **Step 6: Admin Notification Processing**
- Admin receives alerts in enhanced notification screen
- Can call reporter directly
- Register arrests from notifications
- Convert notifications to arrested criminal records

### **Step 7: News Publication**
- Arrested criminals automatically appear in news section
- Includes photos, full names, and crime types
- Public viewing for crime awareness

## 🛠️ Technical Stack

### **Frontend**
- **Flutter 3.0+** - Cross-platform mobile development
- **Dart** - Programming language
- **Material Design** - UI components

### **Key Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  intl: ^0.18.1
  provider: ^6.1.1
  fluttertoast: ^8.2.4
  dropdown_search: ^5.0.6
  image_picker: ^1.0.4
  url_launcher: ^6.2.1
  fl_chart: ^0.66.0
  flutter_local_notifications: ^16.3.0
```

### **State Management**
- **Provider** - For authentication and data management
- **StatefulWidget** - For local component state

### **Data Storage**
- **SharedPreferences** - User session and settings
- **Flutter Secure Storage** - Authentication tokens

## 🚦 Getting Started

### **Prerequisites**
- Flutter SDK 3.0 or higher
- Dart SDK
- Android Studio / VS Code
- Chrome browser (for web testing)

### **Installation**
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run -d chrome  # For web
   flutter run -d android # For Android
   flutter run -d ios     # For iOS
   ```

### **Configuration**
Update `lib/utils/constants.dart` with your API configuration:
```dart
class AppConstants {
  static const String baseUrl = 'your-api-base-url';
  static const String apiVersion = '/api/v1';
}
```

## 🔐 Security Features

- **JWT Authentication** - Secure token-based authentication
- **Role-based Access** - Admin vs User permissions
- **Input Validation** - Comprehensive data validation
- **Secure Storage** - Encrypted local storage for sensitive data

## 🌍 Localization

- **English** - Primary language
- **Kinyarwanda** - Local language support for key messages
- Crime status messages in both languages

## 📊 Analytics & Reporting

- **Crime Statistics** - Visual charts and graphs
- **Geographic Data** - Province and district-based analytics
- **Time-based Reports** - Trend analysis
- **User Activity** - Registration and usage statistics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is developed for Rwanda Investigation Bureau (RIB) for criminal tracking and public safety purposes.

## 📞 Support

For technical support or questions about the Criminal Tracking System, please contact the development team.

---

**Rwanda Investigation Bureau - Criminal Tracking System** 🇷🇼