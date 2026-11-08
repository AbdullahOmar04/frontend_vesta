import 'dart:convert';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

// A bank text is read on the phone first. Banks word their messages
// differently, but almost all of them are built from the same pieces: an
// amount next to a currency, a balance, a debit or credit word, a masked
// account, a date and a name after "from" or "to". When the phone can't tell
// the amount or the direction, the text goes to Gemini through Firebase AI
// Logic, so the app holds no API key. One-time codes and declined payments
// never leave the phone. Only the message goes to Gemini: accounts, balances
// and masks stay here, and Vesta keeps just the fields it fills in.

/// A transaction read from a bank text, for the user to check before saving.
class BankSms {
  const BankSms({
    required this.type,
    required this.amountText,
    this.currency,
    this.counterparty,
    this.date,
    this.account,
    this.description,
    this.category,
  });

  final TransactionType type;

  /// The amount as the bank wrote it, in Western digits ("3.500").
  final String amountText;

  /// ISO code, e.g. 'JOD'.
  final String? currency;

  /// The shop, or the person on the other side of a transfer.
  final String? counterparty;
  final DateTime? date;

  /// How the bank referred to the account, e.g. "0145*500".
  final String? account;

  /// What kind of transaction it was, e.g. "CliQ transfer".
  final String? description;

  /// One of the user's categories, when Gemini found one that clearly fits.
  final String? category;
}

/// Why a text can't become a transaction, worded for the user.
class BankSmsException implements Exception {
  const BankSmsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads [text] on the phone, and with Gemini when the phone isn't sure of
/// the amount or whether money came in or went out. Gemini may also pick one
/// of [categories]. Throws [BankSmsException] when the text isn't a
/// transaction, and other errors when it needed Gemini and Gemini couldn't be
/// reached.
Future<BankSms> readBankSms(
  String text, {
  List<String> categories = const [],
}) async {
  final local = readBankSmsOnPhone(text);
  if (local != null && local.sure) return local.sms;

  try {
    return await _readWithGemini(text, categories);
  } on BankSmsException {
    rethrow;
  } catch (_) {
    // Offline, out of credit or refused: what the phone found beats nothing,
    // unless the payment may not have gone through
    if (local == null) rethrow;
    if (_declined.hasMatch(westernDigits(text).toLowerCase())) {
      throw BankSmsException(
        l10nNow.smsMaybeDeclined,
      );
    }
    return local.sms;
  }
}

// ---------------------------------------------------------------------------
// On the phone

const _currency =
    r'(?<![A-Za-z])(?:JOD|JD|USD|EUR|GBP|SAR|AED)(?![A-Za-z])'
    r'|دينار|دنانير|د\.أ|د\.ا|دولار';
const _number = r'\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?';

/// A number next to a currency, on either side: "JOD 3.500", "32.792JOD",
/// "3.500 دينار".
final _money = RegExp(
  '($_currency)'
  r'\s*'
  '($_number)'
  '|'
  '($_number)'
  r'\s*'
  '($_currency)',
  caseSensitive: false,
);

final _balanceWord = RegExp(
  r'balance|(?<![a-z])bal(?![a-z])|avail|رصيد',
  caseSensitive: false,
);

final _debitWord = RegExp(
  r'(?<![a-z])(?:debited|debit|purchased?|paid|withdrawal|withdrawn|withdraw'
  r'|charged|deducted|spent|sent|transferred to|transfer to|pos)(?![a-z])'
  r'|خصم|شراء|سحب|دفع|تسديد|صادر',
);

final _creditWord = RegExp(
  r'(?<![a-z])(?:credited|credit|deposited|deposit|received|salary|refunded'
  r'|refund|reversal|reversed|incoming|transferred from)(?![a-z])'
  r'|إيداع|ايداع|إضافة|اضافة|راتب|استرداد|وارد',
);

/// "Debit card" and "credit card" name the card, not the direction.
final _cardName = RegExp(r'(?:debit|credit)\s+card');

final _codeWord = RegExp(
  r'otp|one[- ]time|verification code|passcode|activation code|security code'
  r'|رمز التحقق|رمز التفعيل|لمرة واحدة',
);

/// A 4 to 8 digit number on its own, once money, accounts, dates and times
/// have been taken out: the code itself.
final _code = RegExp(r'(?<![\d.,])\d{4,8}(?![\d]|[.,]\d)');

final _date = RegExp(
  r'(?<!\d)\d{1,4}[/.\-]\d{1,2}[/.\-]\d{2,4}(?!\d)|(?<!\d)\d{1,2}:\d{2}(?!\d)',
);

/// Words a declined or failed payment uses. Footers use some of them too, so
/// they only send the message to Gemini rather than rejecting it here.
final _declined = RegExp(
  r'(?<![a-z])(?:declined|rejected|unsuccessful|failed|not completed'
  r'|insufficient)(?![a-z])|مرفوض|رفض|لم تتم|لم يتم|غير ناجح|فشل|غير كاف',
);

final _accountRef = RegExp(
  r'\d+\s*[*xX•]+\s*\d+|[*xX•]{2,}\s*\d{3,4}'
  r'|(?:ending(?: with| in)?|ends with|last digits)\s*\d{3,4}'
  r'|(?:المنتهية|المنتهي|ينتهي)\s*(?:بـ|ب|بالرقم|بالأرقام|بالارقام)?\s*\d{3,4}',
  caseSensitive: false,
);

/// Where a name starts: after "from", "at" or "to", or their Arabic forms.
final _partyStart = RegExp(
  r'(?<![A-Za-z])(?:from|at|to)\s+|(?:^|\s)(?:لدى|إلى|الى|لصالح|من)\s+',
  caseSensitive: false,
);

/// Where it ends: the next keyword, punctuation, currency or line.
final _partyEnd = RegExp(
  r'\s+(?:amount|on|as|via|for|with|using|ref|reference|balance|bal|is|was'
  r'|has)(?![A-Za-z])|\s*[.,;:،؛](?:\s|$)|\s*\(|\s+(?:JOD|JD|USD)(?![A-Za-z])'
  r'|\s+(?:بمبلغ|مبلغ|بتاريخ|في|على|عبر|بواسطة|الرصيد|رصيد)|\n|$',
  caseSensitive: false,
);

/// Words that start an account reference rather than a name.
const _notAName = [
  'your', 'account', 'acc', 'a/c', 'card', //
  'حساب', 'الحساب', 'بطاقة', 'البطاقة', 'رصيد',
];

const _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

/// What the phone could read from [text] by itself, and whether it is sure
/// of the amount and direction. Null when it found no amount at all. Throws
/// [BankSmsException] for one-time codes, which never leave the phone.
({BankSms sms, bool sure})? readBankSmsOnPhone(String text) {
  final t = westernDigits(text);
  final lower = t.toLowerCase();

  if (_isOneTimeCode(lower)) {
    throw BankSmsException(
      l10nNow.smsOneTimeCode,
    );
  }

  // Every amount except the balance left afterwards
  final amounts = _money.allMatches(t).where((m) {
    final before = t.substring(max(0, m.start - 25), m.start);
    return !_balanceWord.hasMatch(before);
  }).toList();
  if (amounts.isEmpty) return null;
  // A foreign price usually comes with the JOD actually charged; take that
  final first = amounts.firstWhere(
    (m) => _currencyCode(m[1] ?? m[4]!) == 'JOD',
    orElse: () => amounts.first,
  );
  final amountText = (first[2] ?? first[3]!).replaceAll(',', '');
  if ((double.tryParse(amountText) ?? 0) <= 0) return null;

  final words = lower.replaceAll(_cardName, '');
  final debit = _debitWord.hasMatch(words);
  final credit = _creditWord.hasMatch(words);

  return (
    sms: BankSms(
      type: credit && !debit ? TransactionType.credit : TransactionType.debit,
      amountText: amountText,
      currency: _currencyCode(first[1] ?? first[4]!),
      counterparty: _counterparty(t),
      date: _dateIn(lower),
      account: _accountRef.firstMatch(t)?[0],
      description: _kindOf(lower),
    ),
    // Two amounts (a foreign price and its JOD charge), mixed signals or a
    // possible decline are for Gemini to untangle
    sure: amounts.length == 1 && debit != credit && !_declined.hasMatch(lower),
  );
}

/// Code wording plus a bare 4 to 8 digit number. "Never share your OTP" in a
/// purchase message's footer has no such number.
bool _isOneTimeCode(String lower) {
  if (!_codeWord.hasMatch(lower)) return false;
  final rest = lower
      .replaceAll(_money, ' ')
      .replaceAll(_accountRef, ' ')
      .replaceAll(_date, ' ');
  return _code.hasMatch(rest);
}

String _currencyCode(String token) {
  final upper = token.toUpperCase();
  if (upper == 'JD' || !RegExp('[A-Z]').hasMatch(upper)) {
    return upper.startsWith('دولار') ? 'USD' : 'JOD';
  }
  return upper;
}

/// The first name after "from", "at" or "to" that isn't the user's own account.
String? _counterparty(String t) {
  for (final start in _partyStart.allMatches(t)) {
    final rest = t.substring(start.end);
    final end = _partyEnd.firstMatch(rest)!.start;
    final name = rest.substring(0, end).trim();
    final lower = name.toLowerCase();
    if (name.isEmpty ||
        name.length > 40 ||
        RegExp(r'^[\d*xX•]').hasMatch(name) ||
        _notAName.any(lower.startsWith)) {
      continue;
    }
    return name;
  }
  return null;
}

/// The date and time in the message, day first. Null when there is none or
/// it isn't a date the bank could have meant.
DateTime? _dateIn(String lower) {
  int? year, month, day;
  final ymd = RegExp(
    r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)',
  ).firstMatch(lower);
  final dmy = RegExp(
    r'(?<!\d)(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})(?!\d)',
  ).firstMatch(lower);
  final named = RegExp(
    r'(?<!\d)(\d{1,2})[\s\-]?(' +
        _months.join('|') +
        r')[a-z]*[\s\-,]*(\d{4}|\d{2})(?!\d)',
  ).firstMatch(lower);

  if (ymd != null) {
    (year, month, day) = (
      int.parse(ymd[1]!),
      int.parse(ymd[2]!),
      int.parse(ymd[3]!),
    );
  } else if (dmy != null) {
    (day, month, year) = (
      int.parse(dmy[1]!),
      int.parse(dmy[2]!),
      int.parse(dmy[3]!),
    );
  } else if (named != null) {
    day = int.parse(named[1]!);
    month = _months.indexOf(named[2]!) + 1;
    year = int.parse(named[3]!);
  }
  if (year == null || month == null || day == null) return null;
  if (year < 100) year += 2000;

  final time = RegExp(
    r'(?<!\d)([01]?\d|2[0-3]):([0-5]\d)(?!\d)',
  ).firstMatch(lower);
  final date = DateTime(
    year,
    month,
    day,
    time == null ? 0 : int.parse(time[1]!),
    time == null ? 0 : int.parse(time[2]!),
  );
  // DateTime rolls 31/02 over into March; that was never a real date
  if (date.month != month || date.day != day) return null;
  return _plausible(date) ? date : null;
}

bool _plausible(DateTime date) =>
    date.year >= 2020 &&
    date.isBefore(DateTime.now().add(const Duration(days: 1)));

String? _kindOf(String lower) {
  if (RegExp(r'cliq|كليك').hasMatch(lower)) return 'CliQ transfer';
  if (RegExp(r'(?<![a-z])atm(?![a-z])|withdraw|سحب').hasMatch(lower)) {
    return 'ATM withdrawal';
  }
  if (RegExp(r'salary|راتب').hasMatch(lower)) return 'Salary';
  if (RegExp(r'refund|revers|استرداد').hasMatch(lower)) return 'Refund';
  if (RegExp(r'purchase|(?<![a-z])pos(?![a-z])|شراء').hasMatch(lower)) {
    return 'Card purchase';
  }
  if (RegExp(r'transfer|حوالة|تحويل').hasMatch(lower)) return 'Transfer';
  return null;
}

// ---------------------------------------------------------------------------
// With Gemini

/// The cheapest Gemini that Firebase AI Logic offers new projects, and kept
/// by Google until at least May 2027.
const _model = 'gemini-3.1-flash-lite';

const _instructions = '''
You read the text messages banks in Jordan send about account activity, in
English or Arabic, and report the transaction the message describes.
- Report only what the message says. Never guess an amount, a date or a name.
- The amount is the money that moved, never the balance left afterwards.
- debit: money left the account (purchase, payment, withdrawal, transfer out,
  fee). credit: money came in (salary, deposit, transfer in, refund, reversal).
- Dates in these messages are day first: 12/10/2026 is 12 October 2026.
- Write names as the message does; do not translate them.
- isTransaction is false for one-time passwords and verification codes,
  declined or failed payments, promotions, and balance-only notices.''';

Future<BankSms> _readWithGemini(String text, List<String> categories) async {
  final model = FirebaseAI.googleAI().generativeModel(
    model: _model,
    systemInstruction: Content.system(_instructions),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: _schema(categories),
      // Copying fields out of a short message needs no reasoning
      thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.minimal),
    ),
  );
  final response = await model.generateContent([Content.text(text)]);
  final json = jsonDecode(response.text ?? '{}') as Map<String, dynamic>;
  return bankSmsFromJson(json, text, categories: categories);
}

Schema _schema(List<String> categories) => Schema.object(
  properties: {
    'isTransaction': Schema.boolean(
      description: 'Whether the message reports money that moved.',
    ),
    'direction': Schema.enumString(enumValues: ['debit', 'credit']),
    'amount': Schema.string(
      description:
          'The amount exactly as written, digits and decimal point only, in '
          'Western digits, e.g. "3.500".',
    ),
    'currency': Schema.string(description: 'ISO 4217 code, e.g. "JOD".'),
    'counterparty': Schema.string(
      description: 'The shop, merchant or person on the other side.',
    ),
    'date': Schema.string(
      description: 'When it happened, as YYYY-MM-DDTHH:mm.',
    ),
    'account': Schema.string(
      description:
          'The account or card as the message refers to it, e.g. "0145*500".',
    ),
    'description': Schema.string(
      description:
          'A short English label for the kind of transaction, e.g. "Card '
          'purchase", "CliQ transfer", "ATM withdrawal", "Salary".',
    ),
    if (categories.isNotEmpty)
      'category': Schema.enumString(
        enumValues: categories,
        description: "The user's category it clearly belongs to, if any.",
      ),
  },
  optionalProperties: [
    'direction',
    'amount',
    'currency',
    'counterparty',
    'date',
    'account',
    'description',
    if (categories.isNotEmpty) 'category',
  ],
);

/// Turns Gemini's answer about [text] into a [BankSms], checking it against
/// the message rather than trusting it.
BankSms bankSmsFromJson(
  Map<String, dynamic> json,
  String text, {
  List<String> categories = const [],
}) {
  if (json['isTransaction'] != true) {
    throw BankSmsException(
      l10nNow.smsNotAPayment,
    );
  }

  final amountText = westernDigits(
    '${json['amount'] ?? ''}',
  ).replaceAll(',', '').trim();
  final amount = double.tryParse(amountText);
  // The amount must be one the bank wrote, not one Gemini made up
  if (amount == null ||
      amount <= 0 ||
      !numbersIn(text).any((n) => (n - amount).abs() < 0.0005)) {
    throw BankSmsException(
      l10nNow.smsNoAmount,
    );
  }

  final date = DateTime.tryParse('${json['date'] ?? ''}');
  final currency = '${json['currency'] ?? ''}'.trim().toUpperCase();
  final category = json['category'];

  return BankSms(
    type: json['direction'] == 'credit'
        ? TransactionType.credit
        : TransactionType.debit,
    amountText: amountText,
    currency: RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : null,
    counterparty: _text(json['counterparty']),
    // A date no bank would send is left for the user to pick
    date: date != null && _plausible(date) ? date : null,
    account: _text(json['account']),
    description: _text(json['description']),
    category: category is String && categories.contains(category)
        ? category
        : null,
  );
}

String? _text(Object? value) {
  final s = value?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

// ---------------------------------------------------------------------------
// Shared

/// [s] with Arabic-Indic and Persian digits, and the Arabic decimal and
/// thousands marks, swapped for their Western forms.
String westernDigits(String s) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final out = StringBuffer();
  for (final ch in s.split('')) {
    final i = arabic.indexOf(ch);
    final j = persian.indexOf(ch);
    out.write(
      i >= 0
          ? '$i'
          : j >= 0
          ? '$j'
          : ch == '٫'
          ? '.'
          : ch == '٬'
          ? ','
          : ch,
    );
  }
  return out.toString();
}

/// Every number written in [text]: "JOD4.000 ... Balance 32.792JOD" gives
/// 4.0 and 32.792.
Iterable<double> numbersIn(String text) => RegExp(r'\d[\d,]*(?:\.\d+)?')
    .allMatches(westernDigits(text))
    .map((m) => double.tryParse(m[0]!.replaceAll(',', '')))
    .whereType<double>();

/// The id of the one account in [masks] (id → last digits) that the bank's
/// [reference] points to: a mask of "1500" or "500" matches "0145*500". Null
/// when none or several match.
String? accountForReference(String? reference, Map<String, String> masks) {
  if (reference == null) return null;
  final groups = RegExp(r'\d+').allMatches(westernDigits(reference)).toList();
  if (groups.isEmpty) return null;
  final last = groups.last[0]!;
  if (last.length < 3) return null;

  final matches = masks.entries.where((e) {
    final mask = e.value.trim();
    return mask.length >= 3 && (mask.endsWith(last) || last.endsWith(mask));
  }).toList();
  return matches.length == 1 ? matches.first.key : null;
}
