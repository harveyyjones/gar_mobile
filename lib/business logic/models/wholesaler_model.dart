import 'package:cloud_firestore/cloud_firestore.dart';

class WholesalerModel {
  final String id;
  final String email;
  final String phone;
  final String name;
  final String surname;
  final String nipNumber;
  final bool isActive;
  final bool isSellerInApp;
  final double rating;
  final int totalSales;
  final DateTime createdAt;
  final AddressDetails address;
  final BankDetails bankDetails;
  final List<String> categories;
  final List<String> paymentMethods;
  final List<String> products;
  final List<String> shippingMethods;
  final WorkingHours workingHours;
  final String logoUrl; // New field for logo URL
  final String sellerId; // Add sellerId field

  WholesalerModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.name,
    required this.surname,
    required this.nipNumber,
    required this.isActive,
    required this.isSellerInApp,
    required this.rating,
    required this.totalSales,
    required this.createdAt,
    required this.address,
    required this.bankDetails,
    required this.categories,
    required this.paymentMethods,
    required this.products,
    required this.shippingMethods,
    required this.workingHours,
    required this.logoUrl, // Add logoUrl to constructor
    required this.sellerId, // Add sellerId to constructor
  });

  factory WholesalerModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Debug the incoming data
    print('Processing wholesaler data for ID $id: $data');

    // Extract the address data from the nested object
    final addressData = data['address'] as Map<String, dynamic>? ?? {};
    print('Found address data: $addressData');

    return WholesalerModel(
      id: id,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      nipNumber: data['nip_number'] ?? '',
      isActive: data['is_active'] ?? false,
      isSellerInApp: true, // Set isSellerInApp to true
      rating: (data['rating'] ?? 0).toDouble(),
      totalSales: data['total_sales'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: AddressDetails(
        addressOfCompany: addressData['adress_of_company'] ?? '', // Corrected spelling
        city: addressData['city'] ?? '',
        country: addressData['country'] ?? '',
        zipNo: addressData['zip_no'] ?? '',
      ),
      bankDetails: BankDetails.fromMap(data['bank_details'] as Map<String, dynamic>? ?? {}),
      categories: List<String>.from(data['categories'] ?? []),
      paymentMethods: List<String>.from(data['payment_methods'] ?? []),
      products: List<String>.from(data['products'] ?? []),
      shippingMethods: List<String>.from(data['shipping_methods'] ?? []),
      workingHours: WorkingHours.fromMap(data['working_hours'] as Map<String, dynamic>? ?? {}),
      logoUrl: data['logo_url'] ?? '', // Assign logoUrl from Firestore data
      sellerId: data['seller_id'] ?? '', // Assign sellerId from Firestore data
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'name': name,
      'surname': surname,
      'nip_number': nipNumber,
      'is_active': isActive,
      'is_seller_in_app': isSellerInApp,
      'rating': rating,
      'total_sales': totalSales,
      'created_at': Timestamp.fromDate(createdAt),
      'address': address.toMap(), // Nest the address data
      'bank_details': bankDetails.toMap(),
      'categories': categories,
      'payment_methods': paymentMethods,
      'products': products,
      'shipping_methods': shippingMethods,
      'working_hours': workingHours.toMap(),
      'logo_url': logoUrl, // Include logoUrl in Firestore mapping
      'seller_id': sellerId, // Include sellerId in Firestore mapping
    };
  }
}

class AddressDetails {
  final String addressOfCompany;
  final String country;
  final String zipNo;
  final String city;


  AddressDetails({
    required this.addressOfCompany,
    required this.city,
    required this.country,
    required this.zipNo,
  });
  factory AddressDetails.fromMap(Map<String, dynamic> map) {
    print('Parsing address data: $map'); // Debug log
    return AddressDetails(
      addressOfCompany: map['address_of_company'] ?? '', // Changed from 'adress_of_company' to 'address_of_company'
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      zipNo: map['zip_no'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address_of_company': addressOfCompany, // Changed from 'adress_of_company' to 'address_of_company'
      'city': city,
      'country': country,
      'zip_no': zipNo,
     
    };
  }
}

class BankDetails {
  final String accountNumber;
  final String bankName;
  final String swiftCode;

  BankDetails({
    required this.accountNumber,
    required this.bankName,
    required this.swiftCode,
  });

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      accountNumber: map['account_number'] ?? '',
      bankName: map['bank_name'] ?? '',
      swiftCode: map['swift_code'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_number': accountNumber,
      'bank_name': bankName,
      'swift_code': swiftCode,
    };
  }
}

class WorkingHours {
  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;
  final DayHours sunday;

  WorkingHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      monday: DayHours.fromMap(map['monday'] as Map<String, dynamic>? ?? {}),
      tuesday: DayHours.fromMap(map['tuesday'] as Map<String, dynamic>? ?? {}),
      wednesday: DayHours.fromMap(map['wednesday'] as Map<String, dynamic>? ?? {}),
      thursday: DayHours.fromMap(map['thursday'] as Map<String, dynamic>? ?? {}),
      friday: DayHours.fromMap(map['friday'] as Map<String, dynamic>? ?? {}),
      saturday: DayHours.fromMap(map['saturday'] as Map<String, dynamic>? ?? {}),
      sunday: DayHours.fromMap(map['sunday'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monday': monday.toMap(),
      'tuesday': tuesday.toMap(),
      'wednesday': wednesday.toMap(),
      'thursday': thursday.toMap(),
      'friday': friday.toMap(),
      'saturday': saturday.toMap(),
      'sunday': sunday.toMap(),
    };
  }
}

class DayHours {
  final String open;
  final String close;

  DayHours({
    required this.open,
    required this.close,
  });

  factory DayHours.fromMap(Map<String, dynamic> map) {
    return DayHours(
      open: map['open'] ?? '',
      close: map['close'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'open': open,
      'close': close,
    };
  }
}
