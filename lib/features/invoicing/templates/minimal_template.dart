import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';
import 'invoice_design_system.dart';
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
        color: InvoiceDesignSystem.card,
        borderRadius: InvoiceDesignSystem.borderRadius,
        boxShadow: InvoiceDesignSystem.subtleShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              color: InvoiceDesignSystem.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 2, width: 80, color: InvoiceDesignSystem.textSecondary.withOpacity(0.2)),
          const Spacer(),
          Container(height: 2, width: 60, color: InvoiceDesignSystem.textSecondary.withOpacity(0.1)),
        ],
      ),
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice) {
    return SingleChildScrollView(
      child: Container(
        color: InvoiceDesignSystem.background,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: InvoiceDesignSystem.card,
              borderRadius: InvoiceDesignSystem.borderRadius,
              boxShadow: InvoiceDesignSystem.subtleShadow,
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header centré
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 4,
                      width: 48,
                      decoration: BoxDecoration(
                        color: InvoiceDesignSystem.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('FACTURE', style: InvoiceDesignSystem.titleLarge.copyWith(fontSize: 32, letterSpacing: -1)),
                    const SizedBox(height: 10),
                    Text(invoice.invoiceNumber, style: InvoiceDesignSystem.label, textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text(_formatDate(invoice.invoiceDate), style: InvoiceDesignSystem.label, textAlign: TextAlign.center),
                  ],
                ),
                const SizedBox(height: 32),
                // Bloc parties
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('De', style: InvoiceDesignSystem.label),
                          const SizedBox(height: 8),
                          Text(invoice.companyName, style: InvoiceDesignSystem.titleMedium),
                          if (invoice.companyPhone != null) ...[
                            const SizedBox(height: 2),
                            Text(invoice.companyPhone!, style: InvoiceDesignSystem.body),
                          ],
                          const SizedBox(height: 2),
                          Text(invoice.companyAddress, style: InvoiceDesignSystem.body),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: InvoiceDesignSystem.border,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pour', style: InvoiceDesignSystem.label),
                          const SizedBox(height: 8),
                          Text(invoice.clientName, style: InvoiceDesignSystem.titleMedium),
                          const SizedBox(height: 2),
                          Text(invoice.clientAddress, style: InvoiceDesignSystem.body),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Tableau items
                _buildItemsList(invoice),
                const SizedBox(height: 24),
                // Totaux
                _buildTotals(invoice),
                if (invoice.notes != null) ...[
                  const SizedBox(height: 32),
                  _buildNotes(invoice.notes!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          width: 64,
          decoration: BoxDecoration(
            color: InvoiceDesignSystem.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'FACTURE',
          style: InvoiceDesignSystem.titleLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              invoice.invoiceNumber,
              style: InvoiceDesignSystem.label,
            ),
            Text(
              '•',
              style: InvoiceDesignSystem.label,
            ),
            Text(
              _formatDate(invoice.invoiceDate),
              style: InvoiceDesignSystem.label,
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
              Text('De', style: InvoiceDesignSystem.label),
              const SizedBox(height: 10),
              Text(invoice.companyName, style: InvoiceDesignSystem.titleMedium),
              const SizedBox(height: 4),
              Text(invoice.companyAddress, style: InvoiceDesignSystem.body),
              if (invoice.companyPhone != null) ...[
                const SizedBox(height: 2),
                Text(invoice.companyPhone!, style: InvoiceDesignSystem.body),
              ],
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pour', style: InvoiceDesignSystem.label),
              const SizedBox(height: 10),
              Text(invoice.clientName, style: InvoiceDesignSystem.titleMedium),
              const SizedBox(height: 4),
              Text(invoice.clientAddress, style: InvoiceDesignSystem.body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(InvoiceModel invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Description', style: InvoiceDesignSystem.label, textAlign: TextAlign.left),
              ),
              Expanded(
                flex: 2,
                child: Text('Qté', style: InvoiceDesignSystem.label, textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 2,
                child: Text('Prix', style: InvoiceDesignSystem.label, textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: Text('Total', style: InvoiceDesignSystem.label, textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        Container(height: 1, color: InvoiceDesignSystem.border),
        // Items
        ...invoice.items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: InvoiceDesignSystem.border.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    item.description,
                    style: InvoiceDesignSystem.body,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: InvoiceDesignSystem.body,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '€${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: InvoiceDesignSystem.body,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '€${item.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: InvoiceDesignSystem.amount,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
        _buildTotalRow('Sous-total', invoice.subtotal, false),
        const SizedBox(height: 8),
        _buildTotalRow('TVA (20%)', invoice.taxAmount, false),
        const SizedBox(height: 16),
        Container(
          height: 2,
          color: InvoiceDesignSystem.primary,
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
        Expanded(
          flex: 2,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: isTotal ? InvoiceDesignSystem.titleMedium : InvoiceDesignSystem.body,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Text(
            '€${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: isTotal ? InvoiceDesignSystem.amountTotal : InvoiceDesignSystem.amount,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: InvoiceDesignSystem.label),
        const SizedBox(height: 12),
        Text(notes, style: InvoiceDesignSystem.body.copyWith(height: 1.6)),
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

  @override
  Widget build(BuildContext context, InvoiceModel invoice) {
    // TODO: implement build
    throw UnimplementedError();
  }
}