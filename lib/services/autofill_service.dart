import '../models/criminal_record.dart';
import '../models/victim.dart';
import '../models/rwandan_citizen.dart';
import '../models/passport_holder.dart';
import '../models/arrested_criminal.dart';
import 'api_service.dart';

class AutofillService {
  // Search for Rwandan citizen by ID number
  static Future<RwandanCitizen?> searchRwandanCitizen(String idNumber) async {
    try {
      // Use the API service method for NIDA lookup
      return await ApiService.searchRwandanCitizen(idNumber);
    } catch (e) {
      return null;
    }
  }

  // Search for passport holder by passport number
  static Future<PassportHolder?> searchPassportHolder(String passportNumber) async {
    try {
      // Use the API service method for passport holder lookup
      return await ApiService.searchPassportHolder(passportNumber);
    } catch (e) {
      return null;
    }
  }

  // Universal search method that determines the correct endpoint based on ID format
  static Future<Map<String, dynamic>?> searchPersonData(String idNumber) async {
    try {
      // Use the API service universal search method
      return await ApiService.searchPersonData(idNumber);
    } catch (e) {
      throw Exception('Error searching person data: $e');
    }
  }

  // Autofill criminal record from citizen data
  static CriminalRecord autofillCriminalRecordFromCitizen(
    RwandanCitizen citizen, {
    String? crimeType,
    String? description,
    DateTime? dateCommitted,
  }) {
    return CriminalRecord(
      citizenId: citizen.id,
      idType: citizen.idType,
      idNumber: citizen.idNumber,
      firstName: citizen.firstName,
      lastName: citizen.lastName,
      gender: citizen.gender,
      dateOfBirth: citizen.dateOfBirth,
      maritalStatus: citizen.maritalStatus,
      province: citizen.province,
      district: citizen.district,
      sector: citizen.sector,
      cell: citizen.cell,
      village: citizen.village,
      phone: citizen.phone,
      crimeType: crimeType ?? '',
      description: description,
      dateCommitted: dateCommitted,
    );
  }

  // Autofill victim from citizen data
  static Victim autofillVictimFromCitizen(
    RwandanCitizen citizen, {
    String? crimeType,
    Map<String, dynamic>? evidence,
    DateTime? dateCommitted,
  }) {
    return Victim(
      citizenId: citizen.id,
      idType: citizen.idType,
      idNumber: citizen.idNumber,
      firstName: citizen.firstName,
      lastName: citizen.lastName,
      gender: citizen.gender,
      dateOfBirth: citizen.dateOfBirth,
      province: citizen.province,
      district: citizen.district,
      sector: citizen.sector,
      cell: citizen.cell,
      village: citizen.village,
      phone: citizen.phone,
      maritalStatus: citizen.maritalStatus,
      crimeType: crimeType ?? '',
      evidence: evidence,
      dateCommitted: dateCommitted ?? DateTime.now(),
    );
  }

  // Autofill arrested criminal from criminal record
  static ArrestedCriminal autofillArrestedFromCriminalRecord(
    CriminalRecord criminalRecord, {
    String? arrestLocation,
    DateTime? dateArrested,
  }) {
    return ArrestedCriminal(
      fullname: '${criminalRecord.firstName} ${criminalRecord.lastName}',
      crimeType: criminalRecord.crimeType,
      dateArrested: dateArrested ?? DateTime.now(),
      arrestLocation: arrestLocation,
      idType: criminalRecord.idType,
      idNumber: criminalRecord.idNumber,
      criminalRecordId: criminalRecord.criId,
    );
  }

  // Get common crime types
  static List<String> getCommonCrimeTypes() {
    return [
      'Theft',
      'Robbery',
      'Assault',
      'Battery',
      'Fraud',
      'Drug Offenses',
      'Drug Trafficking',
      'Drug Possession',
      'Violence',
      'Domestic Violence',
      'Sexual Assault',
      'Rape',
      'Murder',
      'Manslaughter',
      'Kidnapping',
      'Extortion',
      'Money Laundering',
      'Cybercrime',
      'Identity Theft',
      'Embezzlement',
      'Burglary',
      'Arson',
      'Vandalism',
      'Trespassing',
      'Public Disorder',
      'Drunk Driving',
      'Reckless Driving',
      'Hit and Run',
      'Terrorism',
      'Human Trafficking',
      'Child Abuse',
      'Elder Abuse',
      'Animal Cruelty',
      'Environmental Crimes',
      'Tax Evasion',
      'Forgery',
      'Counterfeiting',
      'Bribery',
      'Corruption',
      'Other',
    ];
  }

  // Get common ID types
  static List<String> getCommonIdTypes() {
    return [
      'National ID',
      'Passport',
      'Driver License',
      'Military ID',
      'Student ID',
      'Other',
    ];
  }

  // Get common genders
  static List<String> getCommonGenders() {
    return [
      'Male',
      'Female',
      'Other',
    ];
  }

  // Get common marital statuses
  static List<String> getCommonMaritalStatuses() {
    return [
      'Single',
      'Married',
      'Divorced',
      'Widowed',
      'Separated',
      'Other',
    ];
  }

  // Get Rwandan provinces
  static List<String> getRwandanProvinces() {
    return [
      'Kigali',
      'Northern Province',
      'Southern Province',
      'Eastern Province',
      'Western Province',
    ];
  }

  // Get districts by province
  static List<String> getDistrictsByProvince(String province) {
    switch (province) {
      case 'Kigali':
        return [
          'Nyarugenge',
          'Gasabo',
          'Kicukiro',
        ];
      case 'Northern Province':
        return [
          'Burera',
          'Gakenke',
          'Gicumbi',
          'Musanze',
          'Rulindo',
        ];
      case 'Southern Province':
        return [
          'Gisagara',
          'Huye',
          'Kamonyi',
          'Muhanga',
          'Nyamagabe',
          'Nyanza',
          'Nyaruguru',
          'Ruhango',
        ];
      case 'Eastern Province':
        return [
          'Bugesera',
          'Gatsibo',
          'Kayonza',
          'Kirehe',
          'Ngoma',
          'Nyagatare',
          'Rwamagana',
        ];
      case 'Western Province':
        return [
          'Karongi',
          'Ngororero',
          'Nyabihu',
          'Nyamasheke',
          'Rubavu',
          'Rusizi',
          'Rutsiro',
        ];
      default:
        return [];
    }
  }
}
