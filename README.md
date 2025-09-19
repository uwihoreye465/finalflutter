# Criminal Tracking System

A comprehensive Flutter application for tracking criminal records, victims, and notifications in Rwanda. The system integrates with NIDA (National Identification Agency) for automatic data population and provides administrative management capabilities.

## Features

### 🔍 **Criminal Search & Tracking**
- Search criminals by ID number (National ID or Passport)
- Automatic data population from NIDA records
- Real-time criminal record verification
- Clean record confirmation for law-abiding citizens

### 📝 **Crime Reporting**
- **Victim Reporting**: Report crime victims with detailed information
- **Criminal Reporting**: Report criminal activities with evidence
- **Separate Forms**: Different forms for passport holders vs citizens
- **Auto-fill**: Automatic population of personal data from NIDA
- **Evidence Management**: Support for evidence files and descriptions

### 👮 **Admin Management**
- **Comprehensive Dashboard**: Overview of all system statistics
- **CRUD Operations**: Full Create, Read, Update, Delete for all entities
- **User Management**: Approve/reject user registrations
- **Notification Management**: View and manage notifications with GPS locations
- **Statistics & Analytics**: Detailed charts and reports

### 📊 **Statistics & Analytics**
- **Crime Type Distribution**: Pie charts showing crime categories
- **Geographic Analysis**: Province and district-wise crime distribution
- **Monthly Trends**: Time-based crime analysis
- **Arrest Statistics**: Arrest data and officer performance
- **Notification Analytics**: RIB statistics and message tracking

### 🔔 **Notification System**
- **GPS Location Tracking**: View notification locations on maps
- **RIB Management**: Track messages by RIB office
- **Real-time Updates**: Live notification status
- **Filter & Search**: Advanced filtering capabilities

## API Integration

The application integrates with the following API endpoints:

### Criminal Records
- `GET /api/v1/criminal-records/search/:idNumber` - Search person by ID
- `GET /api/v1/criminal-records` - Get all criminal records (paginated)
- `POST /api/v1/criminal-records` - Add criminal record
- `GET /api/v1/criminal-records/statistics` - Get criminal statistics

### Victims
- `POST /api/v1/victims` - Add victim record
- `GET /api/v1/victims` - Get all victims (paginated)
- `GET /api/v1/victims/statistics` - Get victim statistics

### Arrested Criminals
- `POST /api/v1/arrested` - Add arrested criminal
- `GET /api/v1/arrested` - Get all arrested criminals
- `GET /api/v1/arrested/statistics` - Get arrest statistics

### Notifications
- `POST /api/v1/notifications` - Send notification
- `GET /api/v1/notifications` - Get all notifications
- `GET /api/v1/notifications/stats/rib-statistics` - Get RIB statistics

## ID Type Support

The system supports multiple ID types:

### Rwandan Citizens
- `indangamuntu_yumunyarwanda` - National ID for Rwandan citizens
- `indangamuntu_yumunyamahanga` - National ID for foreign residents
- `indangampunzi` - Refugee ID

### Foreign Nationals
- `passport` - International passport holders

## Data Structure

### Criminal Record
```json
{
  "id_type": "indangamuntu_yumunyarwanda",
  "id_number": "1190000000000001",
  "first_name": "John",
  "last_name": "Doe",
  "gender": "Male",
  "date_of_birth": "1990-01-01",
  "crime_type": "Theft",
  "description": "Crime description",
  "date_committed": "2024-01-01"
}
```

### Victim Record
```json
{
  "id_type": "passport",
  "id_number": "US123456789",
  "first_name": "Jane",
  "last_name": "Smith",
  "victim_email": "jane@example.com",
  "crime_type": "Assault",
  "evidence": {
    "description": "Evidence description",
    "files": [],
    "uploadedAt": "2024-01-01T12:00:00.000Z"
  }
}
```

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd criminal_tracking_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   - Update `lib/utils/constants.dart` with your API base URL
   - Current default: `https://tracking-criminal.onrender.com`

4. **Run the application**
   ```bash
   flutter run
   ```

## Dependencies

- `flutter`: SDK
- `http`: HTTP client for API calls
- `shared_preferences`: Local storage
- `flutter_secure_storage`: Secure storage
- `fl_chart`: Charts and graphs
- `intl`: Internationalization
- `provider`: State management
- `fluttertoast`: Toast notifications
- `dropdown_search`: Enhanced dropdowns
- `url_launcher`: Open external URLs
- `image_picker`: Image selection

## Project Structure

```
lib/
├── config/
│   └── firebase_config.dart
├── models/
│   ├── arrested_criminal.dart
│   ├── criminal_record.dart
│   ├── notification.dart
│   ├── passport_holder.dart
│   ├── rwandan_citizen.dart
│   ├── user.dart
│   └── victim.dart
├── screens/
│   ├── admin/
│   │   ├── enhanced_admin_dashboard.dart
│   │   ├── enhanced_notifications_screen.dart
│   │   ├── enhanced_statistics_screen.dart
│   │   ├── manage_criminal_records_screen.dart
│   │   ├── manage_victims_screen.dart
│   │   ├── manage_arrested_criminals_screen.dart
│   │   └── manage_users_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── user/
│   │   └── enhanced_report_screen.dart
│   └── search/
│       └── search_result_screen.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── autofill_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
├── utils/
│   ├── constants.dart
│   └── validators.dart
├── widgets/
│   ├── common_footer.dart
│   ├── common_header.dart
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   └── loading_widget.dart
└── main.dart
```

## Key Features Implementation

### 1. Auto-fill Functionality
- Searches NIDA database using ID number
- Automatically populates personal information
- Supports both citizen and passport holder data
- Handles different ID types appropriately

### 2. Form Validation
- Required field validation
- Email format validation
- ID number format validation
- Evidence structure validation

### 3. Admin Dashboard
- Real-time statistics
- Interactive charts and graphs
- CRUD operations for all entities
- Search and filter capabilities
- GPS location display for notifications

### 4. Security Features
- User authentication and authorization
- Role-based access control
- Secure API communication
- Data validation and sanitization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Changelog

### Version 1.0.0
- Initial release
- Criminal search and tracking
- Crime reporting system
- Admin management dashboard
- Statistics and analytics
- Notification system with GPS tracking
- NIDA integration for auto-fill
- Multi-ID type support