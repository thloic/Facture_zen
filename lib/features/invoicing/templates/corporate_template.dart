import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

/// Template Corporate : Style entreprise avec bande latérale bleue
class CorporateTemplate implements InvoiceTemplate {
  @override
  String get name => 'Corporate';

  @override
  String get description => 'Style professionnel avec bande bleue';

  @override
  IconData get icon => Icons.business;

  @override
  Color get primaryColor => const Color(0xFF0066CC);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, color: primaryColor),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, width: 60, color: primaryColor),
                const SizedBox(height: 4),
                Container(height: 3, width: 80, color: Colors.grey.shade300),
                const Spacer(),
                Container(height: 2, width: 70, color: Colors.grey.shade200),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice) {
    return build(context, invoice);
  }

  Widget build(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bande latérale
          Container(
            width: 12,
            color: primaryColor,
            height: MediaQuery.of(context).size.height,
          ),

          // Contenu
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(invoice),
                  const SizedBox(height: 32),
                  _buildParties(invoice),
                  const SizedBox(height: 32),
                  _buildItems(invoice),
                  const SizedBox(height: 24),
                  _buildTotals(invoice),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FACTURE',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          'N° ${invoice.invoiceNumber}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          invoice.formattedDate,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildParties(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPartyBox('DE', [
            invoice.companyName,
            invoice.companyAddress,
            if (invoice.companyPhone != null) invoice.companyPhone!,
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPartyBox('À', [
            invoice.clientName,
            invoice.clientAddress,
          ]),
        ),
      ],
    );
  }

  Widget _buildPartyBox(String label, List<String> lines) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildItems(InvoiceModel invoice) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'QTÉ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'TOTAL',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items
        ...invoice.items.map((item) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '×${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${item.total.toStringAsFixed(2)}€',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTotals(InvoiceModel invoice) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTotalRow('Sous-total', invoice.subtotal, false),
        if (invoice.hasDiscount) ...[
          const SizedBox(height: 8),
          _buildTotalRow(
            invoice.discountLabel ?? 'Réduction',
            -invoice.discountAmount,
            false,
            isDiscount: true,
          ),
        ],
        if (invoice.hasTax) ...[
          const SizedBox(height: 8),
          _buildTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount, false),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.hasTax ? 'TOTAL TTC' : 'TOTAL',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${invoice.total.toStringAsFixed(2)}€',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isBold, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.red : Colors.black87,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)}€',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) {
    // TODO: implement generatePDF
    throw UnimplementedError();
  }
}