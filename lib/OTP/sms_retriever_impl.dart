// sms_retriever_impl.dart
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

class SmsRetrieverImpl implements SmsRetriever {
  SmsRetrieverImpl({
    required this.useUserConsentApi,
    this.listenForMultipleSms = false,
  }) : _smartAuth = SmartAuth.instance;  

  final bool useUserConsentApi;

  @override
  final bool listenForMultipleSms;

  final SmartAuth _smartAuth;

  @override
  Future<String?> getSmsCode() async {
    SmartAuthResult<SmartAuthSms> res;

    if (useUserConsentApi) {
      res = await _smartAuth.getSmsWithUserConsentApi();              
    } else {
      res = await _smartAuth.getSmsWithRetrieverApi();               
    }

    return res.hasData ? res.data?.code : null;
  }

  @override
  Future<void> dispose() {
    return useUserConsentApi
        ? _smartAuth.removeUserConsentApiListener()
        : _smartAuth.removeSmsRetrieverApiListener();
  }
}
