import 'package:asalpay/constants/Constant.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';

class DropdownCountryCode extends StatefulWidget {
  final ValueChanged<String>?  onChanged;
  final FormFieldSetter<String>? onsave;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onCountrySelected;

  const DropdownCountryCode({
    super.key,
    this.validator,
    this.onChanged,
    this.onsave,
    this.onCountrySelected,
  });
  @override
  State<DropdownCountryCode> createState() => _DropdownCountryCodeState();
}
class _DropdownCountryCodeState extends State<DropdownCountryCode> {
  late FlCountryCodePicker countryPicker;
  late final TextEditingController countryCodeController = TextEditingController();
  CountryCode? countryCode;
  @override
  //when it loads first  fill it's favorite;
  void initState() {
    // TODO: favorite first lists;
    final favoriteCountries = ['SO', 'KE', 'UG', 'US', 'CN'];
    countryPicker = FlCountryCodePicker(
      favorites: favoriteCountries,
      favoritesIcon: const Icon(
        Icons.star,
        color: primaryColor,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextFormField(
            onSaved: widget.onsave,
            validator: widget.validator,
            onChanged: widget.onChanged,
            autovalidateMode: AutovalidateMode.always,
            controller: countryCodeController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.done,
            maxLines: 1,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(top: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: secondryColor,
                  width: 1.5,
                ),
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final code = await countryPicker.showPicker(context: context);
                        setState(() {
                          countryCode = code;
                        });
                        widget.onCountrySelected?.call(code!.name);
                      },
                      child: Row(
                        children: [
                          // Container(
                          //   child: countryCode != null
                          //       ? countryCode!.flagImage
                          //       : null,
                          // ),
                          Container(
                            child: const Icon(
                              Icons.verified_user,
                              color:primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      countryCode?.name ?? "Somalia",
                      style: const TextStyle(
                        color: secondryColor,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
