import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';
import 'package:shop_app/screens/home/home_screen.dart';

class ExpandableWholesalerInfo extends StatefulWidget {
  final WholesalerModel wholesalerData;
  
   ExpandableWholesalerInfo({
    Key? key,
    required this.wholesalerData,
  }) : super(key: key);

  @override
  State<ExpandableWholesalerInfo> createState() => _ExpandableWholesalerInfoState();
}

class _ExpandableWholesalerInfoState extends State<ExpandableWholesalerInfo> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              image: DecorationImage(
                image: NetworkImage(widget.wholesalerData.logoUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Basic info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Company Information',
                      style: AppTypography.heading2,
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _toggleExpand,
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: const Icon(
                          CupertinoIcons.chevron_down,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Basic company info
                _buildInfoTile(
                  icon: CupertinoIcons.building_2_fill,
                  title:'Company Name' ,
                  subtitle: widget.wholesalerData.name ?? "unknown",
                ),
                
                _buildInfoTile(
                  icon: CupertinoIcons.location_solid,
                  title: 'Address',
                  subtitle: widget.wholesalerData.address.addressOfCompany,
                ),
                
                // Expandable detailed information
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        title: 'Business Details',
                        items: [
                          _buildDetailItem('E-mail', widget.wholesalerData.email),
                          _buildDetailItem('Country', widget.wholesalerData.address.country),
                          _buildDetailItem('Member for', '${DateTime.now().difference(widget.wholesalerData.createdAt).inDays} days'),
                        ],
                      ),
                      // const SizedBox(height: 16),
                      // _buildDetailCard(
                      //   title: 'Contact Information',
                      //   items: [
                      //     _buildDetailItem('Phone', widget.wholesalerData.),
                      //     _buildDetailItem('Email', widget.wholesalerData.),
                      //     _buildDetailItem('Website', widget.wholesalerData.website),
                      //   ],
                      // ),
                      
                      const SizedBox(height: 16),
                      // _buildDetailCard(
                      //   title: 'Additional Information',
                      //   items: [
                      //     _buildDetailItem('Business Type', widget.wholesalerData.businessType),
                      //     _buildDetailItem('Year Established', widget.wholesalerData.yearEstablished),
                      //     _buildDetailItem('Number of Employees', widget.wholesalerData.employeeCount),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body),
                Text(subtitle, style: AppTypography.bodyLight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading3),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyLight,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}