import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

/// Template Luxe : Style premium minimaliste avec touches de couleur subtiles
class LuxeTemplate with InvoiceTemplateMixin implements InvoiceTemplate {
  @override
  String get name => 'Luxe';

  @override
  String get description => 'Minimaliste haut de gamme';

  @override
  IconData get icon => Icons.star_outline;

  @override
  Color get primaryColor => const Color(0xFF2C2C2C);

  Color get accentColor => const Color(0xFF8B7355);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 16, height: 16, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
              const Spacer(),
              Container(height: 2, width: 30, color: primaryColor),
            ],
          ),
          const Spacer(),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Container(height: 3, width: 40, color: accentColor),
        ],
      ),
    );
  }

  @override
  Widget buildInvoice(BuildContext context, InvoiceModel invoice, {bool isPremium = false}) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFFAF9F7),
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            _buildHeader(invoice),
            const SizedBox(height: 48),
            _buildParties(invoice),
            const SizedBox(height: 48),
            _buildItems(invoice),
            const SizedBox(height: 40),
            _buildTotals(invoice),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 40),
              _buildNotes(invoice.notes!),
            ],
            const SizedBox(height: 48),
            _buildFooter(invoice),
            
            // Signature VoxIn pour utilisateurs gratuits
            if (!isPremium) buildVoxInSignature(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, InvoiceModel invoice, {bool isPremium = false}) {
    return buildInvoice(context, invoice, isPremium: isPremium);
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) => null;

  Widget _buildHeader(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invoice.companyLogo != null && invoice.companyLogo!.isNotEmpty) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.network(
                      invoice.companyLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.business, color: accentColor, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                invoice.companyName.toUpperCase(),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                invoice.companyAddress,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'FACTURE',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 1, width: 60, color: accentColor),
              const SizedBox(height: 8),
              Text(
                invoice.invoiceNumber,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                invoice.formattedDate,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParties(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('De', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(invoice.companyName, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis),
                if (invoice.companyPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(invoice.companyPhone!, style: TextStyle(color: Colors.grey.shade500, fontSize: 10), overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: accentColor.withOpacity(0.5), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('À', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(invoice.clientName, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(invoice.clientAddress, style: TextStyle(color: Colors.grey.shade500, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems(InvoiceModel invoice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Colors.grey, fontSize: 9))),
                const SizedBox(width: 24, child: Text('Qté', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 9))),
                const SizedBox(width: 40, child: Text('Prix', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 9))),
                const SizedBox(width: 45, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 9))),
              ],
            ),
          ),
          ...invoice.items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == invoice.items.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade50)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.description, style: TextStyle(color: primaryColor, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 2)),
                  SizedBox(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 11))),
                  SizedBox(width: 40, child: Text('${item.unitPrice.toStringAsFixed(0)}€', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey.shade600, fontSize: 11))),
                  SizedBox(width: 45, child: Text('${item.total.toStringAsFixed(0)}€', textAlign: TextAlign.right, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotals(InvoiceModel invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTotalRow('Sous-total', invoice.subtotal),
        if (invoice.hasTax) ...[
          const SizedBox(height: 4),
          _buildTotalRow('TVA ${invoice.taxRate}%', invoice.taxAmount),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total ',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
              Text(
                '${invoice.total.toStringAsFixed(2)}€',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        const SizedBox(width: 12),
        Text('${amount.toStringAsFixed(2)}€', style: TextStyle(color: primaryColor, fontSize: 10)),
      ],
    );
  }

  Widget _buildNotes(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_outlined, size: 14, color: accentColor),
              const SizedBox(width: 6),
              const Text('Notes', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(notes, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFooter(InvoiceModel invoice) {
    return Column(
      children: [
        Container(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                invoice.companyName,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 5, height: 5, decoration: BoxDecoration(color: accentColor.withOpacity(0.5), shape: BoxShape.circle)),
          ],
        ),
      ],
    );
  }
}
