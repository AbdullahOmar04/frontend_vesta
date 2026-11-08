import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_vesta/Helpers/bank_sms.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

// The user's real messages (2026-10-12), names kept as the bank wrote them
const purchase =
    'You have a purchase transaction on account 0145*500 from BARGOS amount '
    'JOD 3.500 on 12/10/2026 19:30 . Balance JOD 27.092 .';
const cliqOut =
    'JOD4.000 has been debited from 0145*500 to SALAHALDEEN JAMAL A KHALIL as '
    'CliQ transfer Balance 32.792JOD';
const cliqIn =
    'JOD6.750 has been credited to 0145*500from MIRNA ATEYAH HUSSEIN ABU BAQI '
    'as CliQ transfer Balance 59.022JOD';

// Arabic versions written for the tests, not real bank wording yet
const arPurchase =
    'تم خصم مبلغ 3.500 دينار من حسابك 0145*500 لدى BARGOS بتاريخ '
    '12/10/2026 19:30. الرصيد 27.092 دينار';
const arCliqOut =
    'تم خصم ٤٫٠٠٠ د.أ من حسابك ٠١٤٥*٥٠٠ حوالة كليك إلى صلاح الدين جمال. '
    'الرصيد ٣٢٫٧٩٢ د.أ';
const arCliqIn =
    'تم إيداع 6.750 دينار في حسابك 0145*500 من ميرنا عطية عبر كليك. '
    'الرصيد 59.022 دينار';

({BankSms sms, bool sure}) phone(String text) => readBankSmsOnPhone(text)!;

void main() {
  group('on the phone', () {
    test('purchase', () {
      final r = phone(purchase);
      expect(r.sure, isTrue);
      expect(r.sms.type, TransactionType.debit);
      expect(r.sms.amountText, '3.500');
      expect(r.sms.currency, 'JOD');
      expect(r.sms.counterparty, 'BARGOS');
      expect(r.sms.date, DateTime(2026, 10, 12, 19, 30));
      expect(r.sms.account, '0145*500');
      expect(r.sms.description, 'Card purchase');
    });

    test('CliQ out', () {
      final r = phone(cliqOut);
      expect(r.sure, isTrue);
      expect(r.sms.type, TransactionType.debit);
      expect(r.sms.amountText, '4.000');
      expect(r.sms.counterparty, 'SALAHALDEEN JAMAL A KHALIL');
      expect(r.sms.description, 'CliQ transfer');
      expect(r.sms.date, isNull);
    });

    test('CliQ in, with the account glued to "from"', () {
      final r = phone(cliqIn);
      expect(r.sure, isTrue);
      expect(r.sms.type, TransactionType.credit);
      expect(r.sms.amountText, '6.750');
      expect(r.sms.counterparty, 'MIRNA ATEYAH HUSSEIN ABU BAQI');
      expect(r.sms.account, '0145*500');
    });

    test('Arabic purchase', () {
      final r = phone(arPurchase);
      expect(r.sure, isTrue);
      expect(r.sms.type, TransactionType.debit);
      expect(r.sms.amountText, '3.500');
      expect(r.sms.currency, 'JOD');
      expect(r.sms.counterparty, 'BARGOS');
      expect(r.sms.date, DateTime(2026, 10, 12, 19, 30));
    });

    test('Arabic CliQ out, Arabic digits', () {
      final r = phone(arCliqOut);
      expect(r.sure, isTrue);
      expect(r.sms.type, TransactionType.debit);
      expect(r.sms.amountText, '4.000');
      expect(r.sms.counterparty, 'صلاح الدين جمال');
      expect(r.sms.account, '0145*500');
      expect(r.sms.description, 'CliQ transfer');
    });

    test('Arabic CliQ in', () {
      final r = phone(arCliqIn);
      expect(r.sure, isTrue);
      expect(r.sms.type, TransactionType.credit);
      expect(r.sms.amountText, '6.750');
      expect(r.sms.counterparty, 'ميرنا عطية');
    });

    test("the app's sample message", () {
      final r = phone(
        'A purchase transaction from Corner Market amount JOD 18.750 was made '
        'with your card ending 7754 on 11/10/2026 14:05.',
      );
      expect(r.sure, isTrue);
      expect(r.sms.amountText, '18.750');
      expect(r.sms.counterparty, 'Corner Market');
      expect(accountForReference(r.sms.account, {'a': '7754'}), 'a');
    });

    test('one-time codes are refused and never sent on', () {
      for (final code in [
        'Your OTP is 482913. Do not share it with anyone.',
        'Your OTP for the purchase of JOD 25.000 at AMAZON is 482913',
        'رمز التحقق الخاص بك هو 482913',
      ]) {
        expect(
          () => readBankSmsOnPhone(code),
          throwsA(isA<BankSmsException>()),
        );
      }
    });

    test('a footer warning about OTPs is still a purchase', () {
      final r = phone('$purchase Never share your OTP with anyone.');
      expect(r.sure, isTrue);
      expect(r.sms.amountText, '3.500');
    });

    test('a decline goes to Gemini', () {
      final r = phone(
        'Your purchase of JOD 15.000 at ZAIN SHOP was declined due to '
        'insufficient funds.',
      );
      expect(r.sure, isFalse);
    });

    test('without Gemini, a decline is refused rather than filled', () async {
      // No Firebase in tests, so the Gemini call fails like being offline
      await expectLater(
        readBankSms(
          'Your purchase of JOD 15.000 at ZAIN SHOP was declined due to '
          'insufficient funds.',
        ),
        throwsA(isA<BankSmsException>()),
      );
    });

    test('a foreign price with its JOD charge goes to Gemini', () {
      final r = phone(
        'Purchase of USD 12.99 at STEAM GAMES (JOD 9.210) with card ending '
        '7754 on 05/11/2026 21:10',
      );
      expect(r.sure, isFalse);
      // What the phone offers if Gemini can't be reached: the JOD charge
      expect(r.sms.amountText, '9.210');
      expect(r.sms.currency, 'JOD');
      expect(r.sms.counterparty, 'STEAM GAMES');
    });

    test('no amount at all', () {
      expect(readBankSmsOnPhone('Welcome to online banking!'), isNull);
    });

    test('readBankSms answers sure messages without Gemini', () async {
      final sms = await readBankSms(cliqIn);
      expect(sms.type, TransactionType.credit);
      expect(sms.amountText, '6.750');
    });
  });

  group("checking Gemini's answer", () {
    test('purchase', () {
      final sms = bankSmsFromJson(
        {
          'isTransaction': true,
          'direction': 'debit',
          'amount': '3.500',
          'currency': 'JOD',
          'counterparty': 'BARGOS',
          'date': '2026-10-12T19:30',
          'account': '0145*500',
          'category': 'Food And Drinks',
        },
        purchase,
        categories: ['Food And Drinks', 'Groceries'],
      );
      expect(sms.type, TransactionType.debit);
      expect(sms.date, DateTime(2026, 10, 12, 19, 30));
      expect(sms.category, 'Food And Drinks');
    });

    test('an amount not in the text is refused', () {
      expect(
        () => bankSmsFromJson({
          'isTransaction': true,
          'amount': '5.000',
        }, cliqOut),
        throwsA(isA<BankSmsException>()),
      );
    });

    test('not a transaction is refused', () {
      expect(
        () =>
            bankSmsFromJson({'isTransaction': false}, 'Your card was declined'),
        throwsA(isA<BankSmsException>()),
      );
    });

    test('future dates and unknown categories are dropped', () {
      final sms = bankSmsFromJson(
        {
          'isTransaction': true,
          'amount': '3.500',
          'date': '2099-01-01T10:00',
          'category': 'Made up',
        },
        purchase,
        categories: ['Groceries'],
      );
      expect(sms.date, isNull);
      expect(sms.category, isNull);
    });
  });

  test('account matching by mask', () {
    expect(accountForReference('0145*500', {'a': '1500', 'b': '7754'}), 'a');
    expect(accountForReference('0145*500', {'a': '500'}), 'a');
    expect(accountForReference('٠١٤٥*٥٠٠', {'a': '1500'}), 'a');
    expect(accountForReference('ending 7754', {'a': '1500', 'b': '7754'}), 'b');
    // Two candidates: let the user choose
    expect(accountForReference('0145*500', {'a': '1500', 'b': '2500'}), isNull);
    expect(accountForReference('0145*500', {'a': '7754'}), isNull);
    expect(accountForReference(null, {'a': '1500'}), isNull);
  });
}
