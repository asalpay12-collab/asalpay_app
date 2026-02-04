// lib/PinPopUp.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/widgets/commonBtn2.dart';
import './widgets/logoSpinner2.dart';
import 'package:asalpay/services/api_urls.dart';

  Widget _buildInfoRow(String label, String value, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  


class PinPopUp {
  static Future<void> show({

    required BuildContext context,
    required String account,
    required String merchantNo,
    required double amount,
    required String description,
    required String reference,
    required String callbackUrl,
    required int currencyFrom,
    required int currencyTo,
    required String merchantName,
  }) async {


    debugPrint('🔐 Attempting to show PinPopUp - Context: ${context != null ? "Available" : "NULL"}');
  debugPrint('🔐 Wallet ID: $account, Amount: $amount');
  

    if (account.isEmpty || merchantNo.isEmpty || amount <= 0) {
      debugPrint('⛔ Invalid parameters for PinPopUp');
      return;
    }

    debugPrint('🔐 Showing PinPopUp – acc=$account, merch=$merchantNo');

    String pin = '';
    bool isLoading = false;
    String error = '';

    const Color primaryColor = Color(0xFF00529B);
    final Color primaryColorLight = primaryColor.withOpacity(0.85);
    final Color subtleTextColor = Colors.grey.shade600;
    final Color subtleBgColor = Colors.grey.shade100;
    final Color borderColor = Colors.grey.shade300;





await showDialog(
  context: context,
  barrierDismissible: false,
  builder: (BuildContext ctx) {
    final screenWidth = MediaQuery.of(ctx).size.width;
    final viewInsets = MediaQuery.of(ctx).viewInsets;
Timer? expireTimer;
Timer? countdownTimer;
int remainingSeconds = 60;

return StatefulBuilder(
  builder: (ctx, setState) {
    if (countdownTimer == null && expireTimer == null) {
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds <= 1) {
          timer.cancel();
          expireTimer?.cancel();
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ PIN entry expired. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          setState(() => remainingSeconds--);
        }
      });

      expireTimer = Timer(const Duration(seconds: 60), () {
        if (Navigator.canPop(ctx)) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏳ PIN entry expired. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }


Future<void> _submit() async {

  expireTimer?.cancel();
  countdownTimer?.cancel();

  if (pin.length != 4) {
    setState(() => error = 'PIN must be 4 digits');
    return;
  }

  setState(() {
    isLoading = true;
    error = '';
  });

  final Uri endpoint = Uri.parse('${ApiUrls.BASE_URL}/merchantPurchase/completePurchase');

    // final Uri endpoint = Uri.parse("http://192.168.100.85/asalpay_erp/merchantPurchase/completePurchase");


  final body = {
    'account': account,
    'amountFrom': amount,
    'merchantNo': merchantNo,
    'amountTo': amount,
    'description': description,
    'reference': reference,
    'pin': pin,
    'callback_url': callbackUrl,
    'currencyFrom': currencyFrom,
    'currencyTo': currencyTo,
    'merchantName': merchantName,
  };

  try {
    // 🔍 Log full request payload
    debugPrint('📤 Sending to $endpoint');
    debugPrint('📦 Payload: ${jsonEncode(body)}');

    final res = await http.post(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'API-KEY': 'ASAL-0014480cb3f2eed05b6c2a4',
      },
      body: jsonEncode(body),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      debugPrint('✅ Response JSON: $decoded');

      if (decoded['status'] == true) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final statusCode = decoded['status_code'];
        final msg = decoded['message'] ?? 'Transaction failed';

        if (statusCode == 402 && decoded.containsKey('balance')) {
          final balance = (decoded['balance'] as num).toStringAsFixed(2);
          final required = (decoded['required'] as num).toStringAsFixed(2);
          setState(() => error = 'Insufficient balance: $balance / Required: $required');
        } else {
          setState(() => error = msg);
        }
      }
    } else {
      debugPrint('❌ Error Response [${res.statusCode}]: ${res.body}');
      debugPrint('📤 Sent Payload: ${jsonEncode(body)}');

      String errorMsg = 'Failed [${res.statusCode}]';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMsg += ' – ${decoded['message']}';
        } else {
          errorMsg += ' – ${res.body}';
        }
      } catch (_) {
        errorMsg += ' – ${res.body}';
      }
      setState(() => error = errorMsg);
    }
  } catch (e) {
    debugPrint('❗ Network/Decode error: $e');
    debugPrint('📤 Sent Payload (before crash): ${jsonEncode(body)}');
    setState(() {
      isLoading = false;
      error = 'Network error. Please check connection.';
    });
  }
}

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 24.0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, primaryColor.withOpacity(0.85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Confirm Purchase',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  merchantName.isEmpty ? 'Merchant' : merchantName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: InkWell(
                              onTap: () {
                                expireTimer?.cancel();
                                countdownTimer?.cancel();
                                Navigator.of(ctx).pop();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 20, color: Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter Your 4-Digit PIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OtpTextField(
                              numberOfFields: 4,
                              fieldWidth: 55,
                              borderRadius: BorderRadius.circular(10),
                              showFieldAsBox: true,
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: primaryColor,
                              enabledBorderColor: Colors.grey.shade300,
                              filled: true,
                              fillColor: Colors.grey.shade100.withOpacity(0.5),
                              obscureText: true,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              onSubmit: (code) => pin = code,
                              onCodeChanged: (code) {
                                pin = code;
                                if (error.isNotEmpty && code.length == 4) {
                                  setState(() => error = '');
                                }
                              },
                            ),
                            if (remainingSeconds > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 12),
                                child: Text(
                                  '🕒 You have $remainingSeconds seconds remaining until the order expires',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow('Merchant:', merchantNo, Colors.grey.shade600),
                                  const SizedBox(height: 6),
                                  _buildInfoRow('Description:', description, Colors.grey.shade600),
                                  _buildInfoRow('Reference:', reference, Colors.grey.shade600),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (error.isNotEmpty)
                              Center(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: CommonBtn(
                          txt: 'Confirm Purchase',
                          onPressed: isLoading ? () {} : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Logospinner2(
                        imageAssets: 'assets/asalicon.png',
                        arcColor: primaryColor,
                        spinnerRadius: 160,
                        spinSpeed: Duration(milliseconds: 500),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  },
);
  

//     await showDialog(
//       context: context,
//       barrierDismissible: false,


//       builder: (BuildContext ctx) {

//       Timer? expireTimer;
//       Timer? countdownTimer;
//       int remainingSeconds = 60;
        
//           // Start expiry timer when dialog builds
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     // Prevent duplicate timers
//     if (expireTimer != null || countdownTimer != null) return;

//     // ⏳ Countdown UI timer
//     countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (remainingSeconds <= 1) {
//         timer.cancel();
//       } else {
//         setState(() => remainingSeconds--);
//       }
//     });

//         // 🕒 Expiry action after 60s
//     expireTimer = Timer(const Duration(seconds: 60), () {
//       if (Navigator.of(ctx).canPop()) {
//         Navigator.of(ctx).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('⏳ PIN entry expired. Please try again.'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     });
//   });

//         final screenWidth = MediaQuery.of(ctx).size.width;
//         final viewInsets = MediaQuery.of(ctx).viewInsets;

//         return StatefulBuilder(
//           builder: (ctx, setState) {



// Future<void> _submit() async {

//   expireTimer?.cancel();
//   countdownTimer?.cancel();


//   if (pin.length != 4) {
//     setState(() => error = 'PIN must be 4 digits');
//     return;
//   }

//   setState(() {
//     isLoading = true;
//     error = '';
//   });

//   final Uri endpoint = Uri.parse('${ApiUrls.BASE_URL}/merchantPurchase/completePurchase');

//   final body = {
//     'account': account,
//     'amountFrom': amount,
//     'merchantNo': merchantNo,
//     'amountTo': amount,
//     'description': description,
//     'reference': reference,
//     'pin': pin,
//     'callback_url': callbackUrl,
//     'currencyFrom': currencyFrom,
//     'currencyTo': currencyTo,
//     'merchantName': merchantName,
//   };

//   try {
//     final res = await http.post(
//       endpoint,
//       headers: {
//         'Content-Type': 'application/json',
//         'API-KEY': 'ASAL-0014480cb3f2eed05b6c2a4',
//       },
//       body: jsonEncode(body),
//     );

//     setState(() => isLoading = false);

//     if (res.statusCode == 200) {
//       final decoded = jsonDecode(res.body);
//       debugPrint('✅ Response JSON: $decoded');

//       if (decoded['status'] == true) {
//         Navigator.pop(ctx);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Purchase successful'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         final statusCode = decoded['status_code'];
//         final msg = decoded['message'] ?? 'Transaction failed';

//         if (statusCode == 402 && decoded.containsKey('balance')) {
//           final balance = (decoded['balance'] as num).toStringAsFixed(2);
//           final required = (decoded['required'] as num).toStringAsFixed(2);
//           setState(() => error = 'Insufficient balance: $balance / Required: $required');
//         } else {
//           setState(() => error = msg);
//         }
//       }
//     } else {
//       debugPrint('❌ Error Response [${res.statusCode}]: ${res.body}');

//       String errorMsg = 'Failed [${res.statusCode}]';
//       try {
//         final decoded = jsonDecode(res.body);
//         if (decoded is Map && decoded.containsKey('message')) {
//           errorMsg += ' – ${decoded['message']}';
//         } else {
//           errorMsg += ' – ${res.body}';
//         }
//       } catch (_) {
//         errorMsg += ' – ${res.body}';
//       }

//       setState(() => error = errorMsg);
//     }
//   } catch (e) {
//     debugPrint('❗ Network/Decode error: $e');
//     setState(() {
//       isLoading = false;
//       error = 'Network error. Please check connection.';
//     });
//   }
// }



//             final horizontalPadding = screenWidth * 0.05;

//             return Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 8,
//               insetPadding: EdgeInsets.symmetric(
//                 horizontal: horizontalPadding,
//                 vertical: 24.0,
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Stack(
//                   children: [
//                     // Main Content
//                     SingleChildScrollView(
//                       padding: EdgeInsets.only(bottom: viewInsets.bottom),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Stack(
//                             children: [
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [primaryColor, primaryColorLight],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                 ),
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       'Confirm Purchase',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         color: Colors.white.withOpacity(0.95),
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Text(
//                                       merchantName.isEmpty
//                                           ? 'Merchant'
//                                           : merchantName,
//                                       style: const TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.white,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     const SizedBox(height: 12),
//                                     Text(
//                                       '${amount.toStringAsFixed(2)}',
//                                       style: const TextStyle(
//                                         fontSize: 28,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Positioned(
//                                 top: 12,
//                                 right: 12,
//                                 child: InkWell(
//                                   onTap: () => Navigator.of(ctx).pop(),
//                                   borderRadius: BorderRadius.circular(20),
//                                   child: Container(
//                                     width: 36,
//                                     height: 36,
//                                     decoration: const BoxDecoration(
//                                       color: Colors.white,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.close,

                                      
//                                       size: 20,
//                                       color: Colors.black54,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),

//                           // Body Section
//                           Padding(
//                             padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   'Enter Your 4-Digit PIN',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 OtpTextField(
//                                   numberOfFields: 4,
//                                   fieldWidth: 55,
//                                   borderRadius: BorderRadius.circular(10),
//                                   showFieldAsBox: true,
//                                   borderWidth: 1.0,
//                                   borderColor: borderColor,
//                                   focusedBorderColor: primaryColor,
//                                   enabledBorderColor: borderColor,
//                                   filled: true,
//                                   fillColor: subtleBgColor.withOpacity(0.5),
//                                   obscureText: true,
//                                   textStyle: const TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black87,
//                                   ),
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   onSubmit: (code) {
//                                     pin = code;
//                                   },
//                                   onCodeChanged: (code) {
//                                     pin = code;
//                                     if (error.isNotEmpty && code.length == 4) {
//                                       setState(() => error = '');
//                                     }
//                                   },
//                                 ),
//                                 const SizedBox(height: 20),
//                                 Container(
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: subtleBgColor,
//                                     borderRadius: BorderRadius.circular(10),
//                                     border:
//                                         Border.all(color: borderColor, width: 0.5),
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       _buildInfoRow(
//                                           'Merchant:', merchantNo, subtleTextColor),
//                                       const SizedBox(height: 6),
//                                        _buildInfoRow('Description:', description,
//                                           subtleTextColor),
//                                       _buildInfoRow('Reference:', reference,
//                                           subtleTextColor),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 if (error.isNotEmpty)
//                                   Center(
//                                     child: Padding(
//                                       padding:
//                                           const EdgeInsets.only(bottom: 8.0),
//                                       child: Text(
//                                         error,
//                                         style: const TextStyle(
//                                           color: Colors.redAccent,
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ),


//                           if (remainingSeconds > 0)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
//                               child: Text(
//                                 '🕒 You have $remainingSeconds seconds remaining until the order expires',
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   color: Colors.redAccent,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),


//                           // Confirm Button
//                           Padding(
//                             padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
//                             child: CommonBtn(
//                               txt: 'Confirm Purchase',
//                               onPressed: isLoading ? () {} : _submit,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // Loading Overlay
//                     if (isLoading)
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.5),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Center(
//                           child: Logospinner2(
//                             imageAssets: 'assets/asalicon.png',
//                             arcColor: primaryColor,
//                             spinnerRadius: 160,
//                             spinSpeed: Duration(milliseconds: 500),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

 
}
}