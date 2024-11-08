import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_app/business%20logic/firebase_service.dart';
import 'package:shop_app/business%20logic/models/cart_model.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import at the top

class PostCheckoutScreen extends StatefulWidget {
  final Cart cart;

  const PostCheckoutScreen({
    Key? key,
    required this.cart,
  }) : super(key: key);

  @override
  _PostCheckoutScreenState createState() => _PostCheckoutScreenState();
}

class _PostCheckoutScreenState extends State<PostCheckoutScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedBusinessEntity;

  // Controllers for main company details
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNameController = TextEditingController();

  // Controllers for business identification
  final _nipNumberController = TextEditingController();
  final _euVatController = TextEditingController();
  final _taxNoController = TextEditingController();
  final _companyRegNoController = TextEditingController();

  // Controllers for delivery address
  final _deliveryNameController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _deliveryCityController = TextEditingController();
  final _deliveryZipController = TextEditingController();
  final _deliveryCountryController = TextEditingController();
  final _deliveryPhoneController = TextEditingController();
  final _cargoCompanyController = TextEditingController();
  final _cargoCustomerNoController = TextEditingController();

  // Define business entity types as a constant
  final List<String> _businessEntityTypes = [
    'Corporation',
    'LLC',
    'Sole Proprietorship',
    'Partnership',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _firebaseService.getUserData();
      if (userData != null) {
        _companyNameController.text = userData['company_name'] ?? '';
        _addressController.text = userData['adress_of_company'] ?? '';
        _cityController.text = userData['city'] ?? '';
        _zipController.text = userData['zip_no'] ?? '';
        _countryController.text = userData['country'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _contactNameController.text = userData['contact_name'] ?? '';
        _nipNumberController.text = userData['nip_number'] ?? '';
        _euVatController.text = userData['eu_vat_no'] ?? '';
        _taxNoController.text = userData['tax_no'] ?? '';
        _companyRegNoController.text =
            userData['company_registration_no'] ?? '';
        _selectedBusinessEntity = userData['business_entity'] ?? '';

        // Load delivery address if exists
        if (userData['adress_of_delivery']?.isNotEmpty ?? false) {
          final delivery = userData['adress_of_delivery'][0];
          _deliveryNameController.text = delivery['name'] ?? '';
          _deliveryAddressController.text = delivery['adress'] ?? '';
          _deliveryCityController.text = delivery['city'] ?? '';
          _deliveryZipController.text = delivery['zip'] ?? '';
          _deliveryCountryController.text = delivery['country'] ?? '';
          _deliveryPhoneController.text = delivery['phone'] ?? '';
          _cargoCompanyController.text = delivery['cargo_company'] ?? '';
          _cargoCustomerNoController.text = delivery['cargo_customer_no'] ?? '';
        }

        // Handle business entity type
        final businessEntity = userData['business_entity'] as String?;
        setState(() {
          _selectedBusinessEntity = businessEntity != null &&
                  _businessEntityTypes.contains(businessEntity)
              ? businessEntity
              : null;
        });
      }
    } catch (e) {
      _showCustomSnackBar(
        'Failed to load user data',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showCustomSnackBar(
        'Please fill in all required fields',
        isError: true,
      );
      return;
    }

    if (_selectedBusinessEntity == null) {
      _showCustomSnackBar(
        'Please select a business entity type',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Starting order placement...'); // Debug log

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create user data with print statements for debugging
      final userData = {
        'company_name': _companyNameController.text,
        'adress_of_company': _addressController.text,
        'email': currentUser.email, // Use the current user's email
        'city': _cityController.text,
        'zip_no': _zipController.text,
        'country': _countryController.text,
        'phone': _phoneController.text,
        'contact_name': _contactNameController.text,
        'nip_number': _nipNumberController.text,
        'eu_vat_no': _euVatController.text,
        'tax_no': _taxNoController.text,
        'company_registration_no': _companyRegNoController.text,
        'business_entity': _selectedBusinessEntity,
        'adress_of_delivery': [
          {
            'name': _deliveryNameController.text,
            'adress':
                _deliveryAddressController.text, // Complete the address field
            'city': _deliveryCityController.text,
            'zip': _deliveryZipController.text,
            'country': _deliveryCountryController.text,
            'phone': _deliveryPhoneController.text,
            'cargo_company': _cargoCompanyController.text,
            'cargo_customer_no': _cargoCustomerNoController.text,
            'business_entity': 'Ship to my place',
          }
        ],
      };

      print('User data prepared: ${userData.toString()}'); // Debug log

      final deliveryAddress = {
        'name': _deliveryNameController.text,
        'adress': _deliveryAddressController.text, // Complete the address field
        'city': _deliveryCityController.text,
        'zip': _deliveryZipController.text,
        'country': _deliveryCountryController.text,
        'phone': _deliveryPhoneController.text,
        'cargo_company': _cargoCompanyController.text,
        'cargo_customer_no': _cargoCustomerNoController.text,
        'business_entity': 'Ship to my place',
      };

      print(
          'Delivery address prepared: ${deliveryAddress.toString()}'); // Debug log
      print(
          'Cart data prepared: ${widget.cart.items.length} items'); // Debug log

      // First update the user profile
      print('Updating user profile...'); // Debug log
      await _firebaseService.updateUserProfile(userData);
      print('User profile updated successfully'); // Debug log

      // Then save the order
      print('Saving order...'); // Debug log
      final orderId = await _firebaseService.saveOrder(
        cart: widget.cart,
        userData: userData,
        deliveryAddress: deliveryAddress,
      );
      print('Order saved successfully with ID: $orderId'); // Debug log

      _showCustomSnackBar(
        // Update success message to include Order ID
        'Order placed successfully! Order ID: $orderId',
        isError: false,
      );

      // Navigate back after successful order
      Future.delayed(Duration(seconds: 2), () {
        // New navigation logic
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } catch (e, stackTrace) {
      print('Error in _saveProfile: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug stack trace

      _showCustomSnackBar(
        'Failed to place order. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // New method to show custom snack bar
  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.xmark_circle
                  : CupertinoIcons.check_mark_circled,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add this Scaffold wrapper
      body: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Checkout'),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Updated Order Summary Section
                          Text(
                            'Podsumowanie zamówienia',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 16),
                          // Order items list
                          ...widget.cart.items
                              .map((item) => Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemBackground,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: CupertinoColors.systemGrey5,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            item.image,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 60,
                                              height: 60,
                                              color:
                                                  CupertinoColors.systemGrey5,
                                              child: Icon(CupertinoIcons.photo),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${item.quantity} × ${item.price} PLN',
                                                style: GoogleFonts.poppins(
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${(item.price * item.quantity).toStringAsFixed(2)} PLN',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          SizedBox(height: 24),
                          // Pricing summary
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                _buildPricingRow('Subtotal', widget.cart.total),
                                SizedBox(height: 8),
                                _buildPricingRow('Shipping', 0),
                                Divider(height: 24),
                                _buildPricingRow(
                                  'Total',
                                  widget.cart.total,
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                          // ... existing form code ...
                          SizedBox(height: 32),
                          // Form starts here
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSection(
                                  'Informacje o firmie',
                                  [
                                    _buildTextField(
                                      controller: _companyNameController,
                                      label: 'Nazwa firmy',
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller: _addressController,
                                      label: 'Adres firmy',
                                      required: true,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildTextField(
                                            controller: _cityController,
                                            label: 'Miasto',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _zipController,
                                            label: 'Kod pocztowy',
                                            required: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildTextField(
                                      controller: _countryController,
                                      label: 'Kraj',
                                      required: true,
                                    ),
                                  ],
                                ),
                                _buildSection(
                                  'Informacje o działalności',
                                  [
                                    _buildDropdown(
                                      value: _selectedBusinessEntity,
                                      label: 'Typ podmiotu gospodarczego',
                                      items: _businessEntityTypes,
                                      onChanged: (value) {
                                        setState(() =>
                                            _selectedBusinessEntity = value);
                                      },
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller: _nipNumberController,
                                      label: 'Numer NIP',
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller: _euVatController,
                                      label: 'Numer VAT UE',
                                    ),
                                    _buildTextField(
                                      controller: _taxNoController,
                                      label: 'Numer podatkowy',
                                    ),
                                    _buildTextField(
                                      controller: _companyRegNoController,
                                      label: 'Numer rejestracji firmy',
                                      required: true,
                                    ),
                                  ],
                                ),
                                _buildSection(
                                  'Informacje kontaktowe',
                                  [
                                    _buildTextField(
                                      controller: _contactNameController,
                                      label: 'Osoba kontaktowa',
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Telefon',
                                      required: true,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ],
                                ),
                                _buildSection(
                                  'Informacje o dostawie',
                                  [
                                    _buildTextField(
                                      controller: _deliveryNameController,
                                      label: 'Imię i nazwisko kontaktu dostawy',
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller: _deliveryAddressController,
                                      label: 'Adres dostawy',
                                      required: true,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildTextField(
                                            controller: _deliveryCityController,
                                            label: 'Miasto',
                                            required: true,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _deliveryZipController,
                                            label: 'Kod pocztowy',
                                            required: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildTextField(
                                      controller: _deliveryCountryController,
                                      label: 'Kraj',
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller: _deliveryPhoneController,
                                      label: 'Telefon',
                                      required: true,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    _buildTextField(
                                      controller: _cargoCompanyController,
                                      label: 'Preferowana firma transportowa',
                                    ),
                                    _buildTextField(
                                      controller: _cargoCustomerNoController,
                                      label: 'Numer klienta transportu',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 100), // Space for bottom button
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomCheckoutBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: keyboardType,
        validator: required
            ? (value) {
                if (value?.isEmpty ?? true) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    // Ensure the current value is in the items list
    final validValue = items.contains(value) ? value : null;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
        hint: Text('Select $label'),
        isExpanded: true,
      ),
    );
  }

  // New method to build pricing rows
  Widget _buildPricingRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} PLN',
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? CupertinoColors.activeBlue : null,
          ),
        ),
      ],
    );
  }

  // New method for the bottom checkout bar
  Widget _buildBottomCheckoutBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(vertical: 16),
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(8),
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  'Place Order',
                  style: GoogleFonts.poppins(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
