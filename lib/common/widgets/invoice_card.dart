
import 'package:flutter/material.dart';

import '../../features/invoicing/models/invoice_model.dart';

/// Carte d'affichage d'une facture
/// Design fidèle avec icône rouge et fond gris clair
class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    Key? key,
    required this.invoice,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icône de facture avec fond rose
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_outlined,
              color: const Color(0xFFEF4444),
              size: screenWidth * 0.06,
            ),
          ),

          SizedBox(width: screenWidth * 0.03),

          // Informations de la facture
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.clientName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  invoice.formattedDate,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: const Color(0xFF9CA3AF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu trois points
          IconButton(
            onPressed: onTap,
            icon: Icon(
              Icons.more_vert,
              color: const Color(0xFF6B7280),
              size: screenWidth * 0.055,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}