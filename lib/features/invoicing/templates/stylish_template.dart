import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

class StylishTemplate implements InvoiceTemplate {
  @override
  String get name => 'Épure';

  @override
  String get description => 'Moderne et élégante';

  @override
  IconData get icon => Icons.auto_awesome_mosaic;

  @override
  Color get primaryColor => const Color(0xFF6C5CE7);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle)),
              Container(height: 4, width: 30, color: Colors.grey.shade300),
            ],
          ),
          const Spacer(),
          Container(height: 40, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice) {
    return build(context, invoice);
  }

  @override
  Widget build(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF9FAFB),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildHeader(invoice),
            const SizedBox(height: 24),
            _buildAddresses(invoice),
            const SizedBox(height: 24),
            _buildItemList(invoice),
            const SizedBox(height: 16),
            _buildFooter(invoice),
          ],
        ),
      ),
    );
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) => null;

  Widget _buildHeader(InvoiceModel invoice) {
    return Row(
      children: [
        if (invoice.companyLogo != null && invoice.companyLogo!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(invoice.companyLogo!, width: 48, height: 48, fit: BoxFit.cover),
          )
        else
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.business, color: Colors.white, size: 24),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('FACTURE', style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -1), overflow: TextOverflow.ellipsis),
              Text('N° ${invoice.invoiceNumber}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 12), overflow: TextOverflow.ellipsis),
              Text(invoice.formattedDate, style: TextStyle(color: Colors.grey.shade400, fontSize: 11), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddresses(InvoiceModel invoice) {
    return Row(
      children: [
        _addressBox('Facturé par', invoice.companyName, invoice.companyAddress),
        const SizedBox(width: 8),
        _addressBox('Facturé à', invoice.clientName, invoice.clientAddress),
      ],
    );
  }

  Widget _addressBox(String title, String name, String address) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
            const SizedBox(height: 2),
            Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(InvoiceModel invoice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ...invoice.items.map((item) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                          Text('${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}€', style: TextStyle(color: Colors.grey.shade400, fontSize: 10), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.total.toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFooter(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Total à régler', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text('${invoice.total.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
