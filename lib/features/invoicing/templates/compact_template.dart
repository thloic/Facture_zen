import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'invoice_template_base.dart';

class CompactTemplate implements InvoiceTemplate {
  @override
  String get name => 'Compact';

  @override
  String get description => 'Efficace et dense';

  @override
  IconData get icon => Icons.compress;

  @override
  Color get primaryColor => const Color(0xFF43A047);

  @override
  Widget buildThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 20, height: 20, color: primaryColor),
              const SizedBox(width: 4),
              Container(height: 3, width: 30, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 20, width: double.infinity, color: Colors.grey.shade50),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Container(height: 5, width: 20, color: primaryColor)],
          )
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopBar(invoice),
            const Divider(height: 32),
            _buildAddresses(invoice),
            const SizedBox(height: 24),
            _buildItemsTable(invoice),
            const SizedBox(height: 16),
            _buildBottomSection(invoice),
          ],
        ),
      ),
    );
  }

  @override
  Future<void>? generatePDF(InvoiceModel invoice) => null;

  Widget _buildTopBar(InvoiceModel invoice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (invoice.companyLogo != null && invoice.companyLogo!.isNotEmpty)
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(invoice.companyLogo!, fit: BoxFit.contain),
          )
        else
          Container(width: 50, height: 50, decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.business, color: primaryColor)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('FACTURE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
              Text('N° ${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text(invoice.formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddresses(InvoiceModel invoice) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.companyName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(invoice.companyAddress, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(invoice.clientName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(invoice.clientAddress, style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(InvoiceModel invoice) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FixedColumnWidth(40),
        2: FixedColumnWidth(80),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: [
            _tableCell('Article', isHeader: true),
            _tableCell('Qté', isHeader: true, align: TextAlign.center),
            _tableCell('Total', isHeader: true, align: TextAlign.right),
          ],
        ),
        ...invoice.items.map((item) => TableRow(
              children: [
                _tableCell(item.description),
                _tableCell('${item.quantity}', align: TextAlign.center),
                _tableCell('${item.total.toStringAsFixed(2)}€', align: TextAlign.right),
              ],
            )),
      ],
    );
  }

  Widget _tableCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomSection(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: invoice.notes != null
              ? Text('Note: ${invoice.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey))
              : const SizedBox(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Net à payer:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${invoice.total.toStringAsFixed(2)}€', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
      ],
    );
  }
}
