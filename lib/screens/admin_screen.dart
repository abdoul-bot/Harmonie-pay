import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  void _loadAllTransactions() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.fetchAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingTransactions = transactionProvider.transactions
              .where((t) => t.status == TransactionStatus.pending)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'En attente',
                        value: pendingTransactions.length.toString(),
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total',
                        value: transactionProvider.transactions.length.toString(),
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Demandes en attente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (pendingTransactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: AppTheme.successColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Toutes les demandes sont traitées',
                            style: TextStyle(
                              color: AppTheme.lightText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = pendingTransactions[index];
                      return _AdminTransactionCard(
                        transaction: transaction,
                        onApprove: () => _approveTransaction(context, transaction.id),
                        onReject: () => _rejectTransaction(context, transaction.id),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _approveTransaction(BuildContext context, String transactionId) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    bool success = await transactionProvider.updateTransactionStatus(
      transactionId: transactionId,
      status: TransactionStatus.validated,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction validée'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _loadAllTransactions();
    }
  }

  void _rejectTransaction(BuildContext context, String transactionId) async {
    showDialog(
      context: context,
      builder: (context) => _RejectDialog(
        onReject: (comment) async {
          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
          
          bool success = await transactionProvider.updateTransactionStatus(
            transactionId: transactionId,
            status: TransactionStatus.rejected,
            adminComment: comment,
          );

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction refusée'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            _loadAllTransactions();
          }
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminTransactionCard({
    required this.transaction,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isDeposit = transaction.type == TransactionType.deposit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeposit ? 'Dépôt' : 'Retrait',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.platform,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightText,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${transaction.amount.toStringAsFixed(2)} XOF',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Date: ${dateFormat.format(transaction.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.lightText,
              ),
            ),
            if (isDeposit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Compte: ${transaction.accountNumber}',
                  style: const TextStyle(fontSize: 12),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mobile Money: ${transaction.mobileMoneyNumber}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  final Function(String) onReject;

  const _RejectDialog({required this.onReject});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refuser la transaction'),
      content: TextField(
        controller: _commentController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Raison du refus...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onReject(_commentController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
          ),
          child: const Text('Refuser'),
        ),
      ],
    );
  }
}
