import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../providers/FillDropdownbyRegistreration.dart';
class AllinOneDropdownSearch extends StatefulWidget {
  final String hintxt;
  final String maintext;
  final IconData? icn;
  final TextEditingController? SearchCtr;
  final List<DDownModel>? items;
  final ValueChanged<dynamic> onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? dropdownValue;
  const AllinOneDropdownSearch({
    super.key,
    required this.hintxt,
    required this.onChanged,
    required this.maintext,
    this.SearchCtr,
    this.keyboardType,
    this.items,
    this.icn,
    this.dropdownValue,
    this.validator,
  });

  @override
  State<AllinOneDropdownSearch> createState() => _AllinOneDropdownSearchState();
}

class _AllinOneDropdownSearchState extends State<AllinOneDropdownSearch> {

  String? selectedValue;
  @override
  void initState() {
    super.initState();
    // Set your "default" value here. This example sets it to items[0]
    if (widget.items!.isNotEmpty) {
      selectedValue = widget.dropdownValue;
    }
  }
  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField2<String>(
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: secondryColor,
              width: 1.5,
            ),
          ),
          // prefixIcon: InkWell(
          //   // onTap: widget.onTap,
          //   child: Icon(widget.icn, color: primaryColor),
          // ),
          hintText: widget.hintxt,
          hintStyle: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.black45),
          contentPadding: const EdgeInsets.only(top: 16),
        ),
        isExpanded: true,
        hint: Text(
          widget.maintext,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        items: widget.items!.isNotEmpty
            ? widget.items!
            .map(
              (item) => DropdownMenuItem(
            value: item.id,
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        )
            .toList()
            : [],
        value: widget.dropdownValue,
        onChanged: (v) => widget.onChanged(v),
        validator: widget.validator,
        // onChanged: (v) {
        //   widget.onChanged(v);
        // } ,

        // buttonStyleData: const ButtonStyleData(
        //   height: 45,
        //   width: 350,
        // ),

        dropdownStyleData: const DropdownStyleData(
          maxHeight: 200,
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
        ),
        dropdownSearchData: DropdownSearchData(
            searchController: widget.SearchCtr,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
                height: 50,
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 4,
                  right: 8,
                  left: 8,
                ),
                // child: AllformFields(

                //   hintxt: widget.hintxt,
                //   icn: Icons.search,
                //   ctr: widget.SearchCtr,
                // )

                child: AllformFields(
                  hintxt: widget.hintxt,
                  icn: Icons.search,
                  ctr: widget.SearchCtr ?? TextEditingController(), // Provide a default controller
                ),
                
                ),
            //old one;
            // searchMatchFn: (item, searchValue) {
            //   return (item.value.toString().contains(searchValue));
            // },
            //new one;
            searchMatchFn: (item, searchValue) {
              final myItem = widget.items!
                  .firstWhere((element) => element.id == item.value);
              return myItem.name.contains(searchValue) || (item.child.toString().toLowerCase().contains(searchValue) || item.child.toString().toUpperCase().contains(searchValue));
              //return (item.child.toString().toLowerCase().contains(searchValue) || item.child.toString().toUpperCase().contains(searchValue));
            }),
        iconStyleData: const IconStyleData(
          iconSize: 30,
          iconEnabledColor: primaryColor,
          icon: Icon(
            Icons.arrow_drop_down_circle,
          ),
        ),
        //This to clear the search value when you close the menu
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            widget.SearchCtr!.clear();
          }
        },
      ),
    );
  }
}
