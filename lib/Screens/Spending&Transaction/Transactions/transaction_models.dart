// lib/models/transaction_model.dart

enum TransactionType { debit, credit }

enum TransactionSource { openBanking, smsPaste, manual }

class TransactionModel {
  final String id;
  final String accountId;
  final double amount;
  final String currency;
  final TransactionType type;
  final DateTime date;

  final String? merchantName;
  final String? description;

  final String? accountLabel;

  String? category;
  final TransactionSource source;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.date,
    required this.source,
    this.merchantName,
    this.description,
    this.accountLabel,
    this.category,
  });

  bool get isDebit => type == TransactionType.debit;

  // ---------- Firestore <-> Model (flattened doc) ----------

  factory TransactionModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final typeString = (data['type'] ?? 'debit').toString().toLowerCase();
    final sourceString = (data['source'] ?? TransactionSource.manual.name)
        .toString();

    final amountNum = data['amount'];
    final amount = amountNum is num ? amountNum.toDouble() : 0.0;

    final dateString = data['date'] as String?;
    DateTime date = DateTime.fromMillisecondsSinceEpoch(0);
    if (dateString != null && dateString.isNotEmpty) {
      date = DateTime.tryParse(dateString) ?? date;
    }

    return TransactionModel(
      id: docId,
      accountId: data['accountId'] as String,
      amount: amount,
      currency: (data['currency'] ?? 'JOD') as String,
      type: typeString == 'debit'
          ? TransactionType.debit
          : TransactionType.credit,
      date: date,
      merchantName: data['merchantName'] as String?,
      description: data['description'] as String?,
      accountLabel: data['accountLabel'] as String?,
      category: data['category'] as String?,
      source: TransactionSource.values.firstWhere(
        (s) => s.name == sourceString,
        orElse: () => TransactionSource.manual,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'date': date.toIso8601String(),
      'merchantName': merchantName,
      'description': description,
      'accountLabel': accountLabel,
      'category': category,
      'source': source.name,
    };
  }

  // ---------- Open Banking / Bank API JSON ----------

  factory TransactionModel.fromOpenBankingJson({
    required String firestoreAccountId,
    required Map<String, dynamic> data,
  }) {
    // transactionId from API
    final String id = data['transactionId'].toString();

    // amount + currency
    final amtString = (data['transactionAmount']?['amount'] ?? 0).toString();
    final double amount = double.tryParse(amtString) ?? 0.0;
    final String currency =
        data['transactionAmount']?['currency']?.toString() ?? 'JOD';

    // type
    final typeString = (data['transactionType'] ?? '').toString().toLowerCase();
    final type = typeString == 'debit'
        ? TransactionType.debit
        : TransactionType.credit;

    // date
    DateTime date = DateTime.fromMillisecondsSinceEpoch(0);
    final dateString = data['settlementDateTime'];
    if (dateString is String && dateString.isNotEmpty) {
      try {
        date = DateTime.parse(dateString).toLocal();
      } catch (_) {}
    }

    // merchant / "from where"
    final rawMerchant =
        (data['creditor']?['creditorPersonal']?['name'] ??
                data['debtor']?['debtorPersonal']?['name'] ??
                '')
            .toString();
    final merchantName = rawMerchant.trim().isEmpty ? null : rawMerchant.trim();

    // description / note (e.g. rmtInf.unstructured[0])
    String? description;
    final rmt = data['rmtInf'];
    if (rmt is Map &&
        rmt['unstructured'] is List &&
        (rmt['unstructured'] as List).isNotEmpty) {
      description = rmt['unstructured'][0].toString();
    }

    // account label from IBAN last 4 digits if present
    final iban = data['debtor']?['debtorAccount']?['mainRoute']?['address']
        ?.toString();
    String? accountLabel;
    if (iban != null && iban.length >= 4) {
      accountLabel = '•••• ${iban.substring(iban.length - 4)}';
    }

    final category = data['category'] as String?;

    return TransactionModel(
      id: id,
      accountId: firestoreAccountId,
      amount: amount,
      currency: currency,
      type: type,
      date: date,
      merchantName: merchantName,
      description: description,
      accountLabel: accountLabel,
      category: category,
      source: TransactionSource.openBanking,
    );
  }

  // ---------- SMS (paste) ----------

  factory TransactionModel.fromSmsPaste({
    required String firestoreAccountId,
    required String id, // e.g. Firestore doc id or hash
    required double amount,
    required String currency,
    required TransactionType type,
    required DateTime date,
    String? merchantName,
    String? description, // full SMS text or cleaned
    String? accountLabel,
    String? category,
  }) {
    return TransactionModel(
      id: id,
      accountId: firestoreAccountId,
      amount: amount,
      currency: currency,
      type: type,
      date: date,
      merchantName: merchantName,
      description: description,
      accountLabel: accountLabel,
      category: category,
      source: TransactionSource.smsPaste,
    );
  }

  // ---------- MANUAL TRANSACTION ----------

  factory TransactionModel.manual({
    required String firestoreAccountId,
    required String id, // Firestore doc id or UUID
    required double amount,
    required String currency,
    required TransactionType type,
    required DateTime date,
    String? merchantName,
    String? description,
    String? accountLabel,
    String? category,
  }) {
    return TransactionModel(
      id: id,
      accountId: firestoreAccountId,
      amount: amount,
      currency: currency,
      type: type,
      date: date,
      merchantName: merchantName,
      description: description,
      accountLabel: accountLabel,
      category: category,
      source: TransactionSource.manual,
    );
  }
}

// Simple helper model you already had

class AccountInfo {
  final String id;
  final String name;

  AccountInfo({required this.id, required this.name});
}

// ---------- Household Transactions ----------

class HouseholdTransactionModel extends TransactionModel {
  final String? assignedBy;

  HouseholdTransactionModel({
    required super.id,
    required super.accountId,
    required super.amount,
    required super.currency,
    required super.type,
    required super.date,
    required super.source,
    this.assignedBy,
    super.merchantName,
    super.description,
    super.accountLabel,
    super.category,
  });

  factory HouseholdTransactionModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final base = TransactionModel.fromFirestore(docId, data);

    return HouseholdTransactionModel(
      id: base.id,
      accountId: base.accountId,
      amount: base.amount,
      currency: base.currency,
      type: base.type,
      date: base.date,
      source: base.source,
      merchantName: base.merchantName,
      description: base.description,
      accountLabel: base.accountLabel,
      category: base.category,
      assignedBy: data['assignedBy'] as String?,
    );
  }

  factory HouseholdTransactionModel.fromOpenBankingJson({
    required String firestoreAccountId,
    required Map<String, dynamic> data,
    String? assignedBy,
  }) {
    final base = TransactionModel.fromOpenBankingJson(
      firestoreAccountId: firestoreAccountId,
      data: data,
    );

    return HouseholdTransactionModel(
      id: base.id,
      accountId: base.accountId,
      amount: base.amount,
      currency: base.currency,
      type: base.type,
      date: base.date,
      source: base.source,
      merchantName: base.merchantName,
      description: base.description,
      accountLabel: base.accountLabel,
      category: base.category,
      assignedBy: assignedBy,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['assignedBy'] = assignedBy;
    return map;
  }
}
