import 'dart:convert';
import 'package:asalpay/services/api_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


const _apiKey   = '39913b5d5937728da1834df0b5d639b2';
const _primary  = Color(0xFF005653);
const _secondary = Color(0xFFEFF6F5);

Map<String, String> _headers() => {
      'Content-Type': 'application/json',
      'API-KEY'     : _apiKey,
    };


class Service {
  final String name, icon;
  final List<SubService> sub;
  Service({required this.name, required this.icon, required this.sub});
}

class SubService {
  final String id, name, icon;
  SubService({required this.id, required this.name, required this.icon});
}

class MerchantBrief {
  final String id, name, account, currencyId, currencyName, phone;
  const MerchantBrief(
      {required this.id,
      required this.name,
      required this.account,
      required this.currencyId,
      required this.currencyName,
      required this.phone});
}


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext ctx) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Merchant Pay Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _primary),
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
        home: const ServicePaymentScreen(walletAccountsId: '252615837893'),
      );
}


class ServicePaymentScreen extends StatefulWidget {
  const ServicePaymentScreen({super.key, required this.walletAccountsId});
  final String walletAccountsId;

  @override
  State<ServicePaymentScreen> createState() => _ServicePaymentScreenState();
}

class _ServicePaymentScreenState extends State<ServicePaymentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final List<Service> _saved = [];
  List<Service> _services = [];
  List<MerchantBrief> _merchants = [];



  Service? _selService;
  SubService? _selSub;
  bool _busyServices = true, _busyMerchants = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetchMerchantTypes();
  }


  Future<void> _fetchMerchantTypes() async {
    const url =
        'https://production.asalxpress.com/Wallet_merchant_transfer/fill_merchant_type';
    _log('GET', url);
    try {
      final r = await http.get(Uri.parse(url), headers: _headers());
      _logRes(r);
      final d = jsonDecode(r.body);
      if (d['status'] == 'True') {
        setState(() {
          _services = [
            Service(
              name: 'Merchant Services',
              icon: '',
              sub: (d['result'] as List)
                  .map((e) => SubService(
                        id: e['m_sub_type_id'].toString(),
                        name: e['sub_type_name'],
                        icon: '',
                      ))
                  .toList(),
            )
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _busyServices = false);
    }
  }

  Future<void> _fetchMerchantList(SubService sub) async {
    setState(() {
      _busyMerchants = true;
      _merchants = [];
      _selSub = sub;
    });
    // const url ='https://production.asalxpress.com/Wallet_merchant_transfer/fill_merchant_lists';

    var url ='${ApiUrls.BASE_URL}/Wallet_merchant_transfer/fill_merchant_lists';


        
    _log('POST', url, body: {'m_sub_type_id': sub.id});
    try {
      final r = await http.post(Uri.parse(url),
          headers: _headers(), body: jsonEncode({'m_sub_type_id': sub.id}));
      _logRes(r);
      final d = jsonDecode(r.body);
      if (d['status'] == 'True') {
        setState(() {
          _merchants = (d['result'] as List)
              .map((m) => MerchantBrief(
                    id          : m['merchant_id'] ?? '',
                    name        : m['merchant_name'] ?? '',
                    account     : m['merchant_account'] ?? '',
                    currencyId  : m['currency_id'] ?? '',
                    currencyName: m['currency_name'] ?? '',
                    phone       : m['contact_person_tel'] ?? '',
                  ))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _busyMerchants = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          scaffoldBackgroundColor: _secondary,
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: _primary,
            title: const Text('Service Payments'),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.bookmark_border), text: 'Saved'),
                Tab(icon: Icon(Icons.add_circle_outline), text: 'New'),
              ],
            ),
          ),
          body: TabBarView(controller: _tab, children: [_savedTab(), _flow()]),
        ),
      );

  Widget _savedTab() =>
      _saved.isEmpty ? _centerTxt('No saved bills') : const Center(child: Text('…'));

  Widget _flow() {
    if (_selSub != null)     return _merchantList();
    if (_selService != null) return _subList();
    return _serviceGrid();
  }

  Widget _serviceGrid() {
    if (_busyServices) return const Center(child: CircularProgressIndicator());
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18),
      itemBuilder: (_, i) {
        final s = _services[i];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selService = s),
          child: Container(
            decoration: _gradCard(),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _circle(s.icon, radius: 34),
              const SizedBox(height: 14),
              Text(s.name,
                  style:
                      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      },
    );
  }

  Widget _subList() => ListView(
        padding: const EdgeInsets.all(20),
        children: _selService!.sub
            .map((sub) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: _gradCard(),
                  child: ListTile(
                    leading: _circle(sub.icon),
                    title: Text(sub.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _fetchMerchantList(sub),
                  ),
                ))
            .toList(),
      );

  Widget _merchantList() {
    if (_busyMerchants) return const Center(child: CircularProgressIndicator());
    if (_merchants.isEmpty) return _centerTxt('No merchants found');
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _merchants.length,
      itemBuilder: (_, i) {
        final m = _merchants[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: _gradCard(),
          child: ListTile(
            title: Text(m.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            subtitle:
                Text('Acct: ${m.account}', style: const TextStyle(fontSize: 13)),
            trailing: ElevatedButton(
              child: const Text('Pay'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MerchantPayScreen(walletId: widget.walletAccountsId, merchant: m))),
            ),
          ),
        );
      },
    );
  }


  Widget _centerTxt(String t) =>
      Center(child: Text(t, style: GoogleFonts.poppins()));

  Widget _circle(String emoji, {double radius = 28}) => CircleAvatar(
        radius: radius,
        backgroundColor: _primary.withOpacity(.12),
        child: Text(emoji, style: TextStyle(fontSize: radius)),
      );

  BoxDecoration _gradCard() => BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            colors: [_primary.withOpacity(.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      );

  void _log(String m, String u, {Map<String, dynamic>? body}) {
    if (kDebugMode) debugPrint('➡️ $m $u ${body ?? ''}');
  }

  void _logRes(http.Response r) {
    if (!kDebugMode) return;
    final body = r.body.length > 180 ? '${r.body.substring(0, 180)}…' : r.body;
    debugPrint('⬅️ ${r.statusCode} $body');
  }
}

class MerchantPayScreen extends StatefulWidget {
  const MerchantPayScreen({
    super.key,
    required this.walletId,
    required this.merchant,
  });
  final String walletId;
  final MerchantBrief merchant;

  @override
  State<MerchantPayScreen> createState() => _MerchantPayScreenState();
}

class _MerchantPayScreenState extends State<MerchantPayScreen> {
  final _form = GlobalKey<FormState>();
  final _custNameCtl = TextEditingController();
  final _amountSendCtl = TextEditingController();
  final _amountRecvCtl = TextEditingController();
  final _custAccCtl = TextEditingController();

final _customerIdCtl = TextEditingController();
final _customerCodeCtl = TextEditingController();

  bool _busyLookup = false;
  bool _busyFx = false;
  bool _busyPay = false;
  String? _custCurrencyId, _custCurrencyName, _customerId;
  String? _fxAmountTo;
  String pinNumber = '';

  @override
  void initState() {
    super.initState();
    _custAccCtl.text = widget.walletId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _lookupCustomer());
  }

  @override
  void dispose() {
    _custNameCtl.dispose();
    _amountSendCtl.dispose();
    _amountRecvCtl.dispose();
    _custAccCtl.dispose();
    super.dispose();
  }

Widget _textField(String label, TextEditingController ctl) => TextFormField(
  controller: ctl,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
  ),
  validator: (v) => v?.isEmpty ?? true ? 'Required field' : null,
);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _secondary,
        appBar: AppBar(title: const Text('Merchant Pay'), backgroundColor: _primary),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _header(),
            const SizedBox(height: 24),
            Form(
              key: _form,
              child: Column(children: [
                _readOnly('Customer Account', _custAccCtl), 
                const SizedBox(height: 14),
                _readOnly('Customer Name', _custNameCtl),
                const SizedBox(height: 14),

                 _textField('Customer ID', _customerIdCtl),
                const SizedBox(height: 14),
                _textField('Customer Code', _customerCodeCtl),
                const SizedBox(height: 14),
                
                _amountSendField(),
                const SizedBox(height: 14),
                _readOnly('Amount Receive', _amountRecvCtl),
                const SizedBox(height: 26),
                _busyPay
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            style: _btnStyle(),
                            icon : const Icon(Icons.payment),
                            label: const Text('Pay Merchant'),
                            onPressed: _showMyDialogConfirmPin),
                            )
              ]),
            )
          ]),
        ),
      );

  Widget _header() => Container(
        decoration: _card(),
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          CircleAvatar(
              radius: 40,
              backgroundColor: _primary.withOpacity(.12),
              child: const Icon(Icons.store, size: 42, color: _primary)),
          const SizedBox(height: 14),
          Text(widget.merchant.name,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Acct: ${widget.merchant.account}',
              style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          //Text('Currency: $_merCurName',
            //  style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          Text('Phone: ${widget.merchant.phone}',
              style: GoogleFonts.poppins(color: Colors.grey.shade700)),
        ]),
      );

  Widget _custAccountField() => TextFormField(
        controller: _custAccCtl,
        decoration: const InputDecoration(
          labelText: 'Customer Account ID',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: (v) => v == null || v.isEmpty ? 'Enter account ID' : null,
        onFieldSubmitted: (_) => _lookupCustomer(),
      );

  Widget _amountSendField() => TextFormField(
        controller: _amountSendCtl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Amount Send ${_custCurrencyName ?? ""}',
          prefixIcon: const Icon(Icons.attach_money),
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final n = double.tryParse(v ?? '');
          if (n == null || n <= 0) return 'Invalid amount';
          return null;
        },
        onChanged: (_) => _convertFx(),
      );

  Widget _readOnly(String lbl, TextEditingController c) => TextFormField(
        controller: c,
        enabled: false,
        decoration: InputDecoration(labelText: lbl, border: const OutlineInputBorder()),
      );

  Future<void> _lookupCustomer() async {
    if (widget.walletId == widget.merchant.account) {
      _toast('Cannot pay to your own merchant account');
      return;
    }

    setState(() => _busyLookup = true);
    // const url = 'https://production.asalxpress.com/Wallet_transfer/fill_customer_currency';

    var url = '${ApiUrls.BASE_URL}/Wallet_transfer/fill_customer_currency';

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode({'account_no': widget.walletId}),
      );
      
      if (!mounted) return;
      final d = jsonDecode(res.body);

      if (res.statusCode == 200 && d['result'] != null && d['result'].isNotEmpty) {
        final r = d['result'][0];
        setState(() {
          _custNameCtl.text = '${r['f_name']} ${r['m_name']}'.trim();
          _custCurrencyId = r['currency_id'].toString();
          _custCurrencyName = r['currency_name'];
          _customerId = r['wallet_customers_id'].toString();
        });
        _convertFx();
      } else {
        _toast(d['message'] ?? 'Customer details not found');
      }
    } catch (e) {
      _toast('Error fetching customer: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _busyLookup = false);
    }
  }


  //21/05/25


Future<void> _convertFx() async {
  if (_amountSendCtl.text.isEmpty || _custCurrencyId == null) return;

  if (_custCurrencyId == widget.merchant.currencyId) {
    setState(() {
      _fxAmountTo = _amountSendCtl.text;
      _amountRecvCtl.text = NumberFormat.currency(
        symbol: widget.merchant.currencyName,
        decimalDigits: 2,
      ).format(double.tryParse(_amountSendCtl.text) ?? 0);
    });
    return;
  }

  setState(() => _busyFx = true);

  final url = '${ApiUrls.BASE_URL}/Wallet_merchant_transfer/get_exchange';
  final body = {
    'amount_fro'     : _amountSendCtl.text,
    'currency_to_id' : widget.merchant.currencyId,
    'currency_fro_id': _custCurrencyId!,
  };

  try {
    final res = await http.post(Uri.parse(url),
        headers: _headers(), body: jsonEncode(body));

    final d = jsonDecode(res.body);

    if (d['status'] != 'True') {
      _toast(d['message'] ?? d['messages'] ?? 'Unknown error');
      return;
    }

    final raw = d['result']?['amount_to_usds']?.toString() ?? d['result']?['amount_to']?.toString();
    if (raw == null) {
      _toast('Conversion failed');
      return;
    }

    final normalised = raw.startsWith('.') ? '0$raw' : raw;
    final amtTo = double.tryParse(normalised);
    if (amtTo == null) {
      _toast('Invalid rate');
      return;
    }

    final formatted =
        NumberFormat.currency(symbol: widget.merchant.currencyName, decimalDigits: 2).format(amtTo);

    setState(() {
      _fxAmountTo = amtTo.toString();
      _amountRecvCtl.text = formatted;
    });
  } catch (e) {
    _toast('Network error');
  } finally {
    if (mounted) setState(() => _busyFx = false);
  }
}


Future<void> _showMyDialogConfirmPin() async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Confirmation Pin",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontSize: 20)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, color: _primary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text("Enter 4-digit Pin To Send Money",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(fontSize: 16),
                  textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextFormField(
                  maxLength: 4,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary),
                    ),
                    hintText: '••••',
                    hintStyle: const TextStyle(letterSpacing: 4),
                  ),
                  onChanged: (v) => pinNumber = v,
                  onFieldSubmitted: (_) {
                    if (pinNumber.length == 4) {
                      if (_custCurrencyId == null || _custCurrencyId!.isEmpty) {
                        Navigator.pop(context);
                        _toast('Please enter a valid Customer Account ID first');
                      } else {
                        Navigator.pop(context);
                        _pay(pinNumber);
                      }
                    }
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  if (pinNumber.length == 4) {
                    
                    if (_custCurrencyId == null || _custCurrencyId!.isEmpty) {

                    await _lookupCustomer();
                    if (_custCurrencyId == null || _custCurrencyId!.isEmpty) {
                      _toast('Customer account not valid. Try again.');
                      setState(() => _busyPay = false);
                      return;
                    }
                  }


                      Navigator.pop(context);
                      _pay(pinNumber);
                    
                  } else {
                    _toast('Enter full 4-digit pin');
                  }
                },
                child: const Text("Confirm Pin", style: TextStyle(color: _primary)),
              ),
            ],
          );
        },
      );
    });
}


Future<void> _pay(String pin) async {
  if (pin.length != 4) {
    _toast('Invalid PIN');
    return;
  }

  if (_custCurrencyId == null || _customerId == null) {
    _toast('Please validate customer account first');
    return;
  }

  setState(() => _busyPay = true);
  // const url = 'https://production.asalxpress.com/Wallet_merchant_transfer/merchant_transfer_registration';

    var url = '${ApiUrls.BASE_URL}/Wallet_merchant_transfer/merchant_transfer_registration';


    // var url = "${ApiUrls.BASE_URL}/Walletremit/get_remit_sourceOfFunds";


  final body = {
    'account_no_from'     : widget.walletId,
    'merchant_account_no' : widget.merchant.account,
    // 'merchant_account_no' : 788177,
    'currency_fro_id'     : _custCurrencyId!,
    'amount_fro'          : _amountSendCtl.text.trim(),
    'currency_to_id'      : widget.merchant.currencyId,
    'amount_to'           : _fxAmountTo ?? _amountSendCtl.text.trim(),
    'merchant_id'         : widget.merchant.id,
    'customer_id'         : _customerIdCtl.text.trim(),
    'customer_code'       : _customerCodeCtl.text.trim(),
    'is_billing_service'  : true
  };

  print('➡️ POST $url');
  print('➡️ Request Body: $body');

  try {
    final res = await http.post(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(body),
    );

    print('Response Status: ${res.statusCode}');
    print('Response Body: ${res.body}');

    if (!mounted) return;
    final d = jsonDecode(res.body);

    if (d['status'] == 'True') {
      _toast('Payment Successful!');
      Navigator.pop(context);
    } else {
      _toast(d['messages'] ?? 'Payment failed');
    }
  } catch (e) {
    print('Error in _pay(): $e');
    _toast('Payment error: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _busyPay = false);
  }
}

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0, 4))
        ],
      );

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600));

  void _log(String m, String u, {Map<String, dynamic>? body}) {
    if (kDebugMode) debugPrint('➡️ $m $u ${body ?? ''}');
  }

  void _logRes(http.Response r) {
    if (!kDebugMode) return;
    final txt = r.body.length > 180 ? '${r.body.substring(0, 180)}…' : r.body;
    debugPrint('⬅️ ${r.statusCode} $txt');
  }



}


