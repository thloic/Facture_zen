import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

/// Template Classique : Style professionnel traditionnel
class ClassicTemplate implements InvoiceTemplate {
  @override
  String get name => 'Classique';

  @override
  String get description => 'Design professionnel et traditionnel';

  @override
  IconData get icon => Icons.article;

  @override
  Color get primaryColor => const Color(0xFF1F2937);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête bleu foncé
          Container(
            height: 30,
            color: primaryColor,
            child: const Center(
              child: Text(
                'FACTURE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Contenu simulé
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 4, width: 50, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Container(height: 3, width: 70, color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  Container(height: 3, width: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 2),
                  Container(height: 3, width: 80, color: Colors.grey.shade200),
                ],
              ),
            ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec logo et titre
            _buildHeader(invoice),
            const SizedBox(height: 32),

            // Informations entreprise et client
            _buildPartiesInfo(invoice),
            const SizedBox(height: 32),

            // Tableau des items
            _buildItemsTable(invoice),
            const SizedBox(height: 24),

            // Totaux
            _buildTotals(invoice),
            const SizedBox(height: 32),

            // Notes
            if (invoice.notes != null) _buildNotes(invoice.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Flexible(
            child: Text(
              'FACTURE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'N° ${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDate(invoice.invoiceDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesInfo(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Entreprise
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                invoice.companyName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                invoice.companyAddress,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (invoice.companyPhone != null) ...[
                const SizedBox(height: 2),
                Text(
                  invoice.companyPhone!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (invoice.companySiret != null) ...[
                const SizedBox(height: 2),
                Text(
                  'SIRET: ${invoice.companySiret!}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Client
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FACTURÉ À',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                invoice.clientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                invoice.clientAddress,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(InvoiceModel invoice) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête du tableau
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'QTÉ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PRIX U.',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'TOTAL',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Lignes du tableau
          ...invoice.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.unitPrice.toStringAsFixed(2)} €',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.total.toStringAsFixed(2)} €',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTotals(InvoiceModel invoice) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(
              width: 120,
              child: Text(
                'Sous-total:',
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '${invoice.subtotal.toStringAsFixed(2)} €',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        if (invoice.hasDiscount) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  invoice.discountLabel ?? 'Réduction:',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '-${invoice.discountAmount.toStringAsFixed(2)} €',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
        if (invoice.hasTax) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'TVA (${invoice.taxRate}%):',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '${invoice.taxAmount.toStringAsFixed(2)} €',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  invoice.hasTax ? 'TOTAL TTC:' : 'TOTAL:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '${invoice.total.toStringAsFixed(2)} €',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) {
    // TODO: implement generatePDF
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context, InvoiceModel invoice) {
    // TODO: implement build
    throw UnimplementedError();
  }
}