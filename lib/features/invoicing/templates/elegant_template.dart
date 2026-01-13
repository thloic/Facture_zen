import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

class ElegantTemplate implements InvoiceTemplate {
  @override
  String get name => 'Élégant';

  @override
  String get description => 'Design raffiné et luxueux';

  @override
  IconData get icon => Icons.diamond_outlined;

  @override
  Color get primaryColor => const Color(0xFF2D3436);

  Color get goldColor => const Color(0xFFD4AF37);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: goldColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 3, height: 20, color: goldColor),
              const SizedBox(width: 6),
              Expanded(child: Container(height: 3, color: primaryColor)),
            ],
          ),
          const Spacer(),
          Container(height: 2, width: 60, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFFAFAFA),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildHeader(invoice),
            const SizedBox(height: 40),
            _buildParties(invoice),
            const SizedBox(height: 40),
            _buildItems(invoice),
            const SizedBox(height: 32),
            _buildTotals(invoice),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [goldColor, goldColor.withOpacity(0.3)],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FACTURE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: primaryColor,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.invoiceNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [goldColor, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParties(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'De',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: goldColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                invoice.companyName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                invoice.companyAddress,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'À',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: goldColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                invoice.clientName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                invoice.clientAddress,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItems(InvoiceModel invoice) {
    return Column(
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: goldColor, width: 2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(
                width: 40,
                child: Text(
                  'Qté',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(
                width: 70,
                child: Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Items
        ...invoice.items.map((item) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.description,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${item.total.toStringAsFixed(2)}€',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
      children: [
        if (invoice.hasDiscount)
          _buildTotalRow('Réduction', -invoice.discountAmount),
        if (invoice.hasTax)
          _buildTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: goldColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${invoice.total.toStringAsFixed(2)}€',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: goldColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              '${amount.toStringAsFixed(2)}€',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) {
    // TODO: implement generatePDF
    throw UnimplementedError();
  }
}