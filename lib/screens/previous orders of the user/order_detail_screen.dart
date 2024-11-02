import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    Key? key,
    required this.orderData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final customerInfo = orderData['customerInfo'] as Map<String, dynamic>;
    final deliveryAddress = orderData['delivery_address'] as Map<String, dynamic>;
    final items = orderData['items'] as List<dynamic>;
    final totals = orderData['total'] as double;

    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          softWrap: true,
          'Order Details',
          style: GoogleFonts.poppins(
            
            fontWeight: FontWeight.w600,
         ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                      softWrap: true,
                      '#${orderData['orderId']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            _buildOrderHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Pozycje',
              child: Column(
                children: [
                  ...items.map((item) => _buildOrderItem(item, screenWidth)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Adres dostawy',
              child: _buildAddressInfo(deliveryAddress),
            ),
            const SizedBox(height: 24),
            // _buildSection(
            //   title: 'Order Summary',
            //   child: _buildOrderSummary(totals),
            // ),
            const SizedBox(height: 24),
            // _buildSection(
            //   title: 'Customer Information',
            //   child: _buildCustomerInfo(customerInfo),
            // ),
            _buildSection(
              title: 'Adres płatności',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        'Adres płatności',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'PL 2596578485484',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (orderData['statusHistory'] != null)
              _buildSection(
                title: 'Historia statusu zamówienia',
                child: _buildStatusHistory(
                  orderData['statusHistory'] as List<dynamic>
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['image'] ?? '',
              width: screenWidth * 0.2,
              height: screenWidth * 0.2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Product',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${item['quantity']}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['price']} ${item['currency']} per unit',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${(item['price'] * item['quantity']).toStringAsFixed(2)} ${item['currency']}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfo(Map<String, dynamic> address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          label: 'Nazwa kontaktowa',
          value: address['name'] ?? '',
        ),
        _buildInfoRow(
          label: 'Adres',
          value: address['adress'] ?? '',
        ),
        _buildInfoRow(
          label: 'Miasto',
          value: address['city'] ?? '',
        ),
        _buildInfoRow(
          label: 'Kraj',
          value: address['country'] ?? '',
        ),
        _buildInfoRow(
          label: 'Kod pocztowy',
          value: address['zip'] ?? '',
        ),
        _buildInfoRow(
          label: 'Telefon',
          value: address['phone'] ?? '',
        ),
        if (address['cargoCompany'] != null && address['cargoCompany'].isNotEmpty)
          _buildInfoRow(
            label: 'Nazwa firmy',
            value: address['cargoCompany'],
          ),
        if (address['cargoCustomerNo'] != null && address['cargoCustomerNo'].isNotEmpty)
          _buildInfoRow(
            label: 'Numer kontaktowy',
            value: address['cargoCustomerNo'],
          ),
      ],
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> totals) {
    return Column(
      children: [
        _buildPriceRow(
          label: 'Subtotal',
          amount: totals['subtotal'] ?? 0,
          currency: totals['currency'] ?? '',
        ),
        const SizedBox(height: 8),
        _buildPriceRow(
          label: 'Shipping',
          amount: totals['shipping'] ?? 0,
          currency: totals['currency'] ?? '',
        ),
        const SizedBox(height: 8),
        _buildPriceRow(
          label: 'Tax',
          amount: totals['tax'] ?? 0,
          currency: totals['currency'] ?? '',
        ),
        const Divider(height: 24),
        _buildPriceRow(
          label: 'Total',
          amount: totals['total'] ?? 0,
          currency: totals['currency'] ?? '',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          label: 'Nazwa kontaktowa',
          value: info['companyName'] ?? '',
        ),
        _buildInfoRow(
          label: 'Osoba kontaktowa',
          value: info['contactName'] ?? '',
        ),
        _buildInfoRow(
          label: 'Email',
          value: info['email'] ?? '',
        ),
        _buildInfoRow(
          label: 'Telefon',
          value: info['phone'] ?? '',
        ),
        _buildInfoRow(
          label: 'Podmiot gospodarczy',
          value: info['businessEntity'] ?? '',
        ),
        _buildInfoRow(
          label: 'Numer NIP',
          value: info['nipNumber'] ?? '',
        ),
        if (info['euVatNo'] != null && info['euVatNo'].isNotEmpty)
          _buildInfoRow(
            label: 'Numer VAT UE',
            value: info['euVatNo'],
          ),
        if (info['taxNo'] != null && info['taxNo'].isNotEmpty)
          _buildInfoRow(
            label: 'Numer podatkowy',
            value: info['taxNo'],
          ),
        _buildInfoRow(
          label: 'Numer rejestracji firmy',
          value: info['companyRegistrationNo'] ?? '',
        ),
      ],
    );
  }

  Widget _buildStatusHistory(List<dynamic> history) {
    return Column(
      children: history.map((status) {
        final timestamp = status['timestamp'] as Timestamp;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status['status'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(timestamp.toDate()),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (status['note'] != null && status['note'].isNotEmpty)
                      Text(
                        status['note'],
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required double amount,
    required String currency,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.black : Colors.grey[600],
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} $currency',
          style: GoogleFonts.poppins(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final orderDate = (orderData['orderDate'] as Timestamp).toDate();
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    const SizedBox(height: 4),
                    Text(
                      'Złożono ${_formatDate(orderDate)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    // {{ edit_1 }} - Added soft trap option
                    const SizedBox(height: 4),
                    Text(
                      'Opcja Soft Trap: ${orderData['softTrap'] ?? 'Niedostępna'}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(orderData['status'] ?? 'pending'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'shipped':
        statusColor = Colors.purple;
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1).toLowerCase(),
            style: GoogleFonts.poppins(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
