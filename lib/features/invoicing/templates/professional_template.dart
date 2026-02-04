import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

class ProfessionalTemplate with InvoiceTemplateMixin implements InvoiceTemplate {
  @override
  String get name => 'Professionnel';

  @override
  String get description => 'Design sérieux avec barre latérale';

  @override
  IconData get icon => Icons.assignment_turned_in;

  @override
  Color get primaryColor => const Color(0xFF2C3E50);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Row(
      children: [
        Container(width: 15, color: primaryColor),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, width: 40, color: primaryColor),
                const SizedBox(height: 4),
                Container(height: 2, width: 60, color: Colors.grey.shade200),
                const Spacer(),
                Container(height: 2, width: 50, color: Colors.grey.shade100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice, {bool isPremium = false}) {
    return build(context, invoice, isPremium: isPremium);
  }

  @override
  Widget build(BuildContext context, InvoiceModel invoice, {bool isPremium = false}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(invoice),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildParties(invoice),
                const SizedBox(height: 32),
                _buildItems(invoice),
                const SizedBox(height: 24),
                _buildTotals(invoice),
                if (invoice.notes != null) ...[
                  const SizedBox(height: 24),
                  _buildNotes(invoice.notes!),
                ],
                
                // Signature VoxIn pour utilisateurs gratuits
                if (!isPremium) buildVoxInSignature(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) => null;

  Widget _buildHeader(InvoiceModel invoice) {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FACTURE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'N° ${invoice.invoiceNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  invoice.formattedDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (invoice.companyLogo != null && invoice.companyLogo!.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  invoice.companyLogo!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParties(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoGroup('ÉMETTEUR', [
            invoice.companyName,
            invoice.companyAddress,
            if (invoice.companyPhone != null) invoice.companyPhone!,
            if (invoice.companyEmail != null) invoice.companyEmail!,
          ]),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _buildInfoGroup('DESTINATAIRE', [
            invoice.clientName,
            invoice.clientAddress,
          ]),
        ),
      ],
    );
  }

  Widget _buildInfoGroup(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ...lines.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l, style: const TextStyle(fontSize: 14)),
            )),
      ],
    );
  }

  Widget _buildItems(InvoiceModel invoice) {
    return Column(
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              const Expanded(child: Text('QTÉ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              const Expanded(child: Text('PRIX', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),
        ...invoice.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.description, style: const TextStyle(fontSize: 14))),
                  Expanded(child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                  Expanded(child: Text('${item.unitPrice.toStringAsFixed(2)}€', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
                  Expanded(child: Text('${item.total.toStringAsFixed(2)}€', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTotals(InvoiceModel invoice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTotalRow('Sous-total', '${invoice.subtotal.toStringAsFixed(2)}€'),
                if (invoice.taxRate != null)
                  _buildTotalRow('TVA (${invoice.taxRate}%)', '${invoice.taxAmount.toStringAsFixed(2)}€'),
                const Divider(),
                _buildTotalRow('TOTAL', '${invoice.total.toStringAsFixed(2)}€', isGrandTotal: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal, fontSize: isGrandTotal ? 18 : 14)),
          Text(value, style: TextStyle(fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal, fontSize: isGrandTotal ? 18 : 14, color: isGrandTotal ? primaryColor : null)),
        ],
      ),
    );
  }

  Widget _buildNotes(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(notes, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
