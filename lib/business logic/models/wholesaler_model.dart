// Firestore Model
/*
sellers (collection)
  |
  |- documentId (auto-generated)
      |
      |- address: string
      |- bank_account_details: string
      |- business_entity: string
      |- business_license_image: string
      |- company_name: string
      |- contact_name: string
      |- country: string
      |- created_at: timestamp
      |- description: string
      |- logo: string
      |- saler_id: string
      |- tax_no: string
      |- zip: string
*/

// Dart Class
import 'package:cloud_firestore/cloud_firestore.dart';

class Seller {
  final String id;
  final String address;
  final String bankAccountDetails;
  final String businessEntity;
  final String businessLicenseImage;
  final String companyName;
  final String contactName;
  final String country;
  final DateTime createdAt;
  final String description;
  final String logo;
  final String salerId;
  final String taxNo;
  final String zip;

  Seller({
    required this.id,
    required this.address,
    required this.bankAccountDetails,
    required this.businessEntity,
    required this.businessLicenseImage,
    required this.companyName,
    required this.contactName,
    required this.country,
    required this.createdAt,
    required this.description,
    required this.logo,
    required this.salerId,
    required this.taxNo,
    required this.zip,
  });

  factory Seller.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Seller(
      id: doc.id,
      address: data['adress'] ?? '',
      bankAccountDetails: data['bank_account_details'] ?? '',
      businessEntity: data['business_entity'] ?? '',
      businessLicenseImage: data['business_license_image'] ?? '',
      companyName: data['company_name'] ?? '',
      contactName: data['contact_name'] ?? '',
      country: data['country'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      logo: data['logo'] ?? '',
      salerId: data['saler_id'] ?? '',
      taxNo: data['tax_no'] ?? '',
      zip: data['zip'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'address': address,
      'bank_account_details': bankAccountDetails,
      'business_entity': businessEntity,
      'business_license_image': businessLicenseImage,
      'company_name': companyName,
      'contact_name': contactName,
      'country': country,
      'created_at': Timestamp.fromDate(createdAt),
      'description': description,
      'logo': logo,
      'saler_id': salerId,
      'tax_no': taxNo,
      'zip': zip,
    };
  }
}