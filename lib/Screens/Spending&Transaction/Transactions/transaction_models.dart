// lib/models/transaction_model.dart

class TransactionModel {
  final String accountId;
  final String id;
  final double amount;
  final String currency;
  final TransactionType type;
  final TransactionStatus status;
  final String channel;
  final String? note;
  final String fromName;
  final String toName;
  final DateTime date;
  String? category;

  TransactionModel({
    required this.accountId,
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.channel,
    required this.fromName,
    required this.toName,
    required this.date,
    this.category,
    this.note,
  });

  bool get isDebit => type == TransactionType.debit;

  factory TransactionModel.fromFirestore(
    String accountId,
    String id,
    Map<String, dynamic> data,
  ) {
    // Parse amount and currency
    final amtString = (data["transactionAmount"]?["amount"] ?? 0).toString();
    final amount = double.tryParse(amtString) ?? 0.0;
    final currency = data["transactionAmount"]?["currency"] ?? "JOD";
    final category = data['category'] as String?;

    // Parse type and status
    final typeString = (data["transactionType"] ?? "").toString().toLowerCase();
    final type = typeString == "debit"
        ? TransactionType.debit
        : TransactionType.credit;

    final statusString = (data["transactionStatus"] ?? "")
        .toString()
        .toLowerCase();
    final status = _parseStatus(statusString);

    // Parse channel
    final channel =
        (data["transactionChannel"]?["name"] ??
                data["transactionChannel"]?["code"] ??
                "")
            .toString();

    // Parse note
    String? note;
    final rmt = data["rmtInf"];
    if (rmt is Map &&
        rmt["unstructured"] is List &&
        (rmt["unstructured"] as List).isNotEmpty) {
      note = rmt["unstructured"][0].toString();
    }

    // Parse names
    final debtorName = (data["debtor"]?["debtorPersonal"]?["name"] ?? "")
        .toString();
    final creditorName = (data["creditor"]?["creditorPersonal"]?["name"] ?? "")
        .toString();

    // Parse date
    DateTime parsed = DateTime.fromMillisecondsSinceEpoch(0);
    final dateString = data["settlementDateTime"];
    if (dateString is String && dateString.isNotEmpty) {
      try {
        parsed = DateTime.parse(dateString).toLocal();
      } catch (_) {
        // Keep default date if parsing fails
      }
    }

    return TransactionModel(
      accountId: accountId,
      id: id,
      amount: amount,
      currency: currency,
      type: type,
      status: status,
      channel: channel,
      note: note,
      fromName: debtorName,
      toName: creditorName,
      date: parsed,
      category: category,
    );
  }

  static TransactionStatus _parseStatus(String status) {
    switch (status) {
      case "accepted":
      case "completed":
      case "success":
      case "settled":
        return TransactionStatus.accepted;
      case "rejected":
      case "failed":
      case "declined":
        return TransactionStatus.rejected;
      default:
        return TransactionStatus.pending;
    }
  }
}

enum TransactionType { debit, credit }

enum TransactionStatus { accepted, rejected, pending }

class AccountInfo {
  final String id;
  final String name;

  AccountInfo({required this.id, required this.name});
}

// lib/models/transaction_model.dart

class HouseholdTransactionModel {
  final String accountId;
  final String id;
  final double amount;
  final String currency;
  final TransactionType type;
  final TransactionStatus status;
  final String channel;
  final String? note;
  final String fromName;
  final String toName;
  final DateTime date;
  final String? assignedBy;
  String? category;

  HouseholdTransactionModel({
    required this.accountId,
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.channel,
    required this.fromName,
    required this.toName,
    required this.date,
    this.assignedBy,
    this.category,
    this.note,
  });

  bool get isDebit => type == TransactionType.debit;

  factory HouseholdTransactionModel.fromFirestore(
    String accountId,
    String id,
    Map<String, dynamic> data,
  ) {
    // Parse amount and currency
    final amtString = (data["transactionAmount"]?["amount"] ?? 0).toString();
    final amount = double.tryParse(amtString) ?? 0.0;
    final currency = data["transactionAmount"]?["currency"] ?? "JOD";
    final category = data['category'] as String?;

    // Parse type and status
    final typeString = (data["transactionType"] ?? "").toString().toLowerCase();
    final type = typeString == "debit"
        ? TransactionType.debit
        : TransactionType.credit;

    final statusString = (data["transactionStatus"] ?? "")
        .toString()
        .toLowerCase();
    final status = _parseStatus(statusString);

    // Parse channel
    final channel =
        (data["transactionChannel"]?["name"] ??
                data["transactionChannel"]?["code"] ??
                "")
            .toString();

    // Parse note
    String? note;
    final rmt = data["rmtInf"];
    if (rmt is Map &&
        rmt["unstructured"] is List &&
        (rmt["unstructured"] as List).isNotEmpty) {
      note = rmt["unstructured"][0].toString();
    }

    // Parse names
    final debtorName = (data["debtor"]?["debtorPersonal"]?["name"] ?? "")
        .toString();
    final creditorName = (data["creditor"]?["creditorPersonal"]?["name"] ?? "")
        .toString();

    // Parse date
    DateTime parsed = DateTime.fromMillisecondsSinceEpoch(0);
    final dateString = data["settlementDateTime"];
    if (dateString is String && dateString.isNotEmpty) {
      try {
        parsed = DateTime.parse(dateString).toLocal();
      } catch (_) {
        // Keep default date if parsing fails
      }
    }
    final assignedBy = data["assignedBy"]?.toString();

    return HouseholdTransactionModel(
      accountId: accountId,
      id: id,
      amount: amount,
      currency: currency,
      type: type,
      status: status,
      channel: channel,
      note: note,
      fromName: debtorName,
      toName: creditorName,
      date: parsed,
      category: category,
      assignedBy: assignedBy,
    );
  }

  static TransactionStatus _parseStatus(String status) {
    switch (status) {
      case "accepted":
      case "completed":
      case "success":
      case "settled":
        return TransactionStatus.accepted;
      case "rejected":
      case "failed":
      case "declined":
        return TransactionStatus.rejected;
      default:
        return TransactionStatus.pending;
    }
  }
}
