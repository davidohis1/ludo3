import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/constants/colors.dart';
import '/cubits/user/user_cubit.dart';
import '/services/database_service.dart';
import '/utils/toast_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final DatabaseService databaseService = DatabaseService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _transactionsFuture = databaseService.getUserTransactionsOnce(userId!);
    }
  }

  Future<void> _refreshTransactions() async {
    if (userId == null) return;
    
    if (mounted) {
      setState(() {
        _transactionsFuture = databaseService.getUserTransactionsOnce(userId!);
      });
    }
  }

  Future<void> _launchFundingWebsite() async {
    const url = 'https://dynamic360tech.name.ng/ludo/login.php'; // Replace with your actual funding URL
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ToastUtils.showError(context, 'Could not open funding website');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Please login to view your wallet',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          final user = userState is UserLoaded ? userState.currentUser : null;

          if (user == null) {
            if (userState is UserError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Error: ${userState.message}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.read<UserCubit>().loadUserData(userId!);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _refreshTransactions();
              if (mounted) {
                final userCubit = context.read<UserCubit>();
                userCubit.refreshUserData();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryRed,
                          AppColors.primaryPink,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 48,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${user.totalCoins?.toStringAsFixed(0) ?? '0'} Coins',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Available for gaming',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fund Wallet Button
                  ElevatedButton(
                    onPressed: _launchFundingWebsite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(width: 12),
                        Text(
                          'Fund Wallet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Transaction History Header
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppColors.primaryRed),
                      SizedBox(width: 12),
                      Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Transaction List
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _transactionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 100,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'Unable to load transactions',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: _refreshTransactions,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Your transaction history will appear here',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final transaction = snapshot.data![index];
                          return _buildTransactionItem(transaction);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = transaction['amount'] as int;
    final description = transaction['description'] as String;
    final timestamp = transaction['timestamp'];

    IconData icon;
    Color iconColor;
    Color textColor;
    String displayAmount;

    switch (type) {
      case 'win':
        icon = Icons.emoji_events;
        iconColor = Colors.green;
        textColor = Colors.green;
        displayAmount = '+$amount';
        break;
      case 'loss':
        icon = Icons.sports_esports;
        iconColor = AppColors.primaryRed;
        textColor = AppColors.primaryRed;
        displayAmount = '-${amount.abs()}';
        break;
      case 'purchase':
        icon = Icons.shopping_cart;
        iconColor = Colors.orange;
        textColor = Colors.orange;
        displayAmount = '+$amount';
        break;
      case 'withdrawal':
        icon = Icons.money_off;
        iconColor = Colors.grey;
        textColor = Colors.grey;
        displayAmount = '-${amount.abs()}';
        break;
      default:
        icon = Icons.account_balance_wallet;
        iconColor = Colors.blue;
        textColor = Colors.blue;
        displayAmount = '$amount';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp != null
                      ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp.toDate())
                      : 'Date not available',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            displayAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
