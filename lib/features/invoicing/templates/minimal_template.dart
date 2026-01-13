import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';
/// Template Minimaliste : Style épuré et simple
class MinimalTemplate implements InvoiceTemplate {
  @override
  String get name => 'Minimaliste';

  @override
  String get description => 'Design épuré et simple';

  @override
  IconData get icon => Icons.minimize;

  @override
  Color get primaryColor => Colors.black87;

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.black87,
          ),
          const SizedBox(height: 8),
          Container(height: 3, width: 40, color: Colors.black87),
          const SizedBox(height: 4),
          Container(height: 2, width: 60, color: Colors.grey.shade400),
          const Spacer(),
          Container(height: 2, width: 70, color: Colors.grey.shade300),
          const SizedBox(height: 2),
          Container(height: 2, width: 50, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(invoice),
            const SizedBox(height: 48),
            _buildPartiesInfo(invoice),
            const SizedBox(height: 48),
            _buildItemsList(invoice),
            const SizedBox(height: 32),
            _buildTotals(invoice),
            if (invoice.notes != null) ...[
              const SizedBox(height: 48),
              _buildNotes(invoice.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 2,
          width: 60,
          color: primaryColor,
        ),
        const SizedBox(height: 16),
        const Text(
          'INVOICE',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              invoice.invoiceNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '•',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Text(
              _formatDate(invoice.invoiceDate),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartiesInfo(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                invoice.companyName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.companyAddress,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              if (invoice.companyPhone != null) ...[
                const SizedBox(height: 2),
                Text(
                  invoice.companyPhone!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                invoice.clientName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.clientAddress,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(InvoiceModel invoice) {
    return Column(
      children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),

        // Items
        ...invoice.items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '€${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text(
                    '€${item.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotals(InvoiceModel invoice) {
    return Column(
      children: [
        _buildTotalRow('Subtotal', invoice.subtotal, false),
        const SizedBox(height: 8),
        _buildTotalRow('Tax (20%)', invoice.taxAmount, false),
        const SizedBox(height: 16),
        Container(
          height: 2,
          color: primaryColor,
          margin: const EdgeInsets.only(bottom: 16),
        ),
        _buildTotalRow('Total', invoice.total, true),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 32),
        SizedBox(
          width: 100,
          child: Text(
            '€${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          notes,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) {
    // TODO: implement generatePDF
    throw UnimplementedError();
  }
}