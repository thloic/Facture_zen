import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

/// Template Executive : Style premium épuré avec accents dorés
class ExecutiveTemplate implements InvoiceTemplate {
  @override
  String get name => 'Executive';

  @override
  String get description => 'Premium avec accents dorés';

  @override
  IconData get icon => Icons.workspace_premium;

  @override
  Color get primaryColor => const Color(0xFF1A1A2E);

  Color get goldAccent => const Color(0xFFD4A574);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, width: 30, color: goldAccent),
          const SizedBox(height: 8),
          Container(height: 3, width: 50, color: Colors.white24),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(height: 4, width: 40, color: goldAccent),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(invoice),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  _buildParties(invoice),
                  const SizedBox(height: 40),
                  _buildItems(invoice),
                  const SizedBox(height: 32),
                  _buildTotals(invoice),
                  if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildNotes(invoice.notes!),
                  ],
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, InvoiceModel invoice) {
    return buildInvoice(context, invoice);
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) => null;

  Widget _buildHeader(InvoiceModel invoice) {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoice.companyLogo != null && invoice.companyLogo!.isNotEmpty) ...[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  invoice.companyLogo!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.business, color: primaryColor, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2, width: 40, color: goldAccent),
                const SizedBox(height: 12),
                const Text(
                  'FACTURE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  invoice.companyName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'N° ${invoice.invoiceNumber}',
                  style: TextStyle(
                    color: goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.formattedDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                'ÉMETTEUR',
                style: TextStyle(
                  color: goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(invoice.companyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(invoice.companyAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (invoice.companyPhone != null) ...[
                const SizedBox(height: 2),
                Text(invoice.companyPhone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DESTINATAIRE',
                style: TextStyle(
                  color: goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(invoice.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(invoice.clientAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItems(InvoiceModel invoice) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: goldAccent, width: 2)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('DESCRIPTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1))),
              const SizedBox(width: 30, child: Text('QTÉ', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              const SizedBox(width: 50, child: Text('P.U.', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              const SizedBox(width: 60, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        ...invoice.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.description, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2)),
                  SizedBox(width: 30, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  SizedBox(width: 50, child: Text('${item.unitPrice.toStringAsFixed(0)}€', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  SizedBox(width: 60, child: Text('${item.total.toStringAsFixed(0)}€', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTotals(InvoiceModel invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTotalRow('Sous-total', '${invoice.subtotal.toStringAsFixed(2)}€'),
        if (invoice.hasTax) _buildTotalRow('TVA (${invoice.taxRate}%)', '${invoice.taxAmount.toStringAsFixed(2)}€'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                invoice.hasTax ? 'TOTAL TTC  ' : 'TOTAL  ',
                style: TextStyle(color: goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '${invoice.total.toStringAsFixed(2)}€',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(width: 16),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNotes(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: goldAccent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTES', style: TextStyle(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(notes, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(height: 2, width: 60, color: goldAccent),
      ),
    );
  }
}
