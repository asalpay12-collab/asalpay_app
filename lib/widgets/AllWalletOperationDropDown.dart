import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/providers/TransferOperations.dart';
import 'package:asalpay/providers/WalletOperations.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
class AllWalletOperationDropDown extends StatefulWidget {
  final String hintxt;
  final String maintext;
  final IconData? icn;
  final TextEditingController? SearchCtr;
  final List<WalletOperationModel>? items;
  final List<TransferOperationModel>? TransferItems;
  final ValueChanged<dynamic> onChanged;
  final TextInputType? keyboardType;
  final String? dropdownValue;
  const AllWalletOperationDropDown({
    super.key,
    required this.hintxt,
    required this.onChanged,
    required this.maintext,
    this.SearchCtr,
    this.keyboardType,
    this.items,
    this.TransferItems,
    this.icn,
    this.dropdownValue,
  });

  @override
  State<AllWalletOperationDropDown> createState() => _AllWalletOperationDropDownState();
}

class _AllWalletOperationDropDownState extends State<AllWalletOperationDropDown> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    // Set the default selected value to the value of dropdownValue
      // if (widget.items!.isNotEmpty) {
      //   selectedValue = widget.dropdownValue;
      // }

        if (widget.TransferItems!.isNotEmpty) {
        selectedValue = widget.dropdownValue;
      }
  }

  // final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        // color: secondryColor.withOpacity(0.1),
        border: Border.all(color: Colors.grey, width: 1.5),
        // borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            widget.maintext,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor,
            ),
          ),
          items: widget.TransferItems!.isNotEmpty
              ? widget.TransferItems!
              .map(
                (item) => DropdownMenuItem(
              value: item.currency_id,
              child: Text(
                item.currency_name!,
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
          buttonStyleData: const ButtonStyleData(
            height: 45,
            width: 350,
          ),

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
                final myItem = widget.TransferItems!
                    .firstWhere((element) => element.currency_id == item.value);
                return myItem.currency_name!.contains(searchValue) || (item.child.toString().toLowerCase().contains(searchValue) || item.child.toString().toUpperCase().contains(searchValue));
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
      ),
    );
  }
}