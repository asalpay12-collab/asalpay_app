import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../providers/Walletremit.dart';
class AllinOneRemitDropdownSearch extends StatefulWidget {
  final String hintxt;
  final String maintext;
  final IconData? icn;
  final TextEditingController? SearchCtr;
  final List<RemitChannelTypeModel>? items;
  final ValueChanged<dynamic> onChanged;
  final TextInputType? keyboardType;
  final String? dropdownValue;

  // Change the type of itemAsString to a function
  final String Function(RemitChannelTypeModel)? itemAsString;

  const AllinOneRemitDropdownSearch({
    super.key,
    required this.hintxt,
    required this.onChanged,
    required this.maintext,
    this.SearchCtr,
    this.keyboardType,
    this.items,
    this.icn,
    this.dropdownValue,

    this.itemAsString,
  });

  @override
  State<AllinOneRemitDropdownSearch> createState() => _AllinOneRemitDropdownSearchState();




}

class _AllinOneRemitDropdownSearchState extends State<AllinOneRemitDropdownSearch> {
  // final List<String> items = [
  //   'A_Item1',
  //   'A_Item2',
  //   'A_Item3',
  //   'A_Item4',
  //   'B_Item1',
  //   'B_Item2',
  //   'B_Item3',
  //   'B_Item4',
  // ];
  String? selectedValue;
  @override
  void initState() {
    super.initState();
    // Set your "default" value here. This example sets it to items[0]
    if (widget.items!.isNotEmpty) {
      selectedValue = widget.dropdownValue;
    }
  }

  // final TextEditingController textEditingController = TextEditingController();

// Use itemAsString if provided, otherwise use a default implementation
  String displayItemAsString(RemitChannelTypeModel item) {
    return widget.itemAsString != null ? widget.itemAsString!(item) : item.type_name ?? item.toString();
  }
  


  @override

@override
  Widget build(BuildContext context) {
    debugPrint("AllinOneRemitDropdownSearch - Building widget with dropdownValue: ${widget.dropdownValue}");

    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey, width: 1.5),
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
          items: widget.items != null && widget.items!.isNotEmpty
              ? widget.items!.map(
                  (item) {
                    debugPrint("Mapping item: ${item.sub_partiners_name} (${item.channel_type_id})");
                    return DropdownMenuItem(
                      value: item.channel_type_id,
                      child: Text(
                        displayItemAsString(item), // Use the helper method
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ).toList()
              : [],
          value: widget.dropdownValue,
          onChanged: (value) {
            debugPrint("Dropdown onChanged triggered with value: $value");
            widget.onChanged(value);
          },
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
              child: AllformFields(
                hintxt: widget.hintxt,
                icn: Icons.search,
                ctr: widget.SearchCtr ?? TextEditingController(),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              final myItem = widget.items!.firstWhere(
                (element) => element.channel_type_id == item.value,
              );
              return myItem.type_name.contains(searchValue) ||
                  item.child.toString().toLowerCase().contains(searchValue) ||
                  item.child.toString().toUpperCase().contains(searchValue);
            },
          ),
          iconStyleData: const IconStyleData(
            iconSize: 30,
            iconEnabledColor: primaryColor,
            icon: Icon(
              Icons.arrow_drop_down_circle,
            ),
          ),
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


//   Widget build(BuildContext context) {


//     // Use itemAsString if provided, otherwise use a default implementation
//   String displayItemAsString(RemitChannelTypeModel item) {
//     return widget.itemAsString != null ? widget.itemAsString!(item) : item.type_name ?? item.toString();
//   }

//     return Container(
//       padding: const EdgeInsets.only(left: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         // color: secondryColor.withOpacity(0.1),
//         border: Border.all(color: Colors.grey, width: 1.5),
//         // borderSide: BorderSide(color: primaryColor, width: 1.5),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton2<String>(
//           isExpanded: true,
//           hint: Text(
//             widget.maintext,
//             style: TextStyle(
//               fontSize: 14,
//               color: Theme.of(context).hintColor,
//             ),
//           ),
//           items: widget.items!.isNotEmpty
//               ? widget.items!
//               .map(
//                 (item) => DropdownMenuItem(
//               value: item.channel_type_id,
//               child: Text(
//                 item.type_name,
//                 style: const TextStyle(
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           )
//               .toList()
//               : [],
//           value: widget.dropdownValue,
//           onChanged: (v) => widget.onChanged(v),
//           // onChanged: (v) {
//           //   widget.onChanged(v);
//           // } ,

//           buttonStyleData: const ButtonStyleData(
//             height: 45,
//             width: 350,
//           ),

//           dropdownStyleData: const DropdownStyleData(
//             maxHeight: 200,
//           ),
//           menuItemStyleData: const MenuItemStyleData(
//             height: 40,
//           ),
//           dropdownSearchData: DropdownSearchData(
//               searchController: widget.SearchCtr,
//               searchInnerWidgetHeight: 50,
//               searchInnerWidget: Container(
//                   height: 50,
//                   padding: const EdgeInsets.only(
//                     top: 8,
//                     bottom: 4,
//                     right: 8,
//                     left: 8,
//                   ),
//                   // child: AllformFields(
//                   //   hintxt: widget.hintxt,
//                   //   icn: Icons.search,
//                   //   ctr: widget.SearchCtr,
//                   // )

//                   child: AllformFields(
//                   hintxt: widget.hintxt,
//                   icn: Icons.search,
//                   ctr: widget.SearchCtr ?? TextEditingController(), 
//                 ),

//                   ),
//               //old one;
//               // searchMatchFn: (item, searchValue) {
//               //   return (item.value.toString().contains(searchValue));
//               // },
//               //new one;
//               searchMatchFn: (item, searchValue) {
//                 final myItem = widget.items!
//                     .firstWhere((element) => element.channel_type_id == item.value);
//                 return myItem.type_name.contains(searchValue) || (item.child.toString().toLowerCase().contains(searchValue) || item.child.toString().toUpperCase().contains(searchValue));
//                 //return (item.child.toString().toLowerCase().contains(searchValue) || item.child.toString().toUpperCase().contains(searchValue));
//               }),

//           iconStyleData: const IconStyleData(
//             iconSize: 30,
//             iconEnabledColor: primaryColor,
//             icon: Icon(
//               Icons.arrow_drop_down_circle,
//             ),
//           ),
//           //This to clear the search value when you close the menu
//           onMenuStateChange: (isOpen) {
//             if (!isOpen) {
//               widget.SearchCtr!.clear();
//             }
//           },
//         ),
//       ),
//     );
//   }
// }