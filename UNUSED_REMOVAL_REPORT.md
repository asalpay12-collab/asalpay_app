# Unused Packages & Files – Report & Removal Summary

## REMOVED PACKAGES (from pubspec.yaml)

- searchfield, rflutter_alert, logger, get, get_storage, progress_loader_overlay
- shimmer_pro, responsive_framework, dropdown_search, page_transition, curved_navigation_bar
- dio, universal_io, app_set_id, flutter_device_type, flutter_background, chat_bubbles
- tflite_flutter, pointycastle, pie_chart, bottom_sheet, carousel_slider, firebase_auth
- google_nav_bar (buttonNavigationbar2 was unused)
- fluttertoast, lottie, camera (if present – verify; some may have been in original)

## REMOVED FILES

- lib/transactions/AllTransaction.dart
- lib/providers/WalletOperations1.dart
- lib/notification_helper.dart
- lib/ButtomNavigation/buttonNavigationbar2.dart
- lib/filter/filter_screen.dart
- lib/filter/filteredTransactions.dart
- lib/filter/styled_transaction_widget.dart

---

## Original UNUSED PACKAGES (reference)

| Package | Reason |
|---------|--------|
| `searchfield` | No import found in lib/ |
| `rflutter_alert` | No import found |
| `logger` | No import found |
| `get` | No import found |
| `get_storage` | No import found |
| `progress_loader_overlay` | No import found |
| `shimmer_pro` | No import found |
| `responsive_framework` | No import found |
| `dropdown_search` | No import found (dropdown_button2 is used) |
| `page_transition` | No import found |
| `curved_navigation_bar` | No import found |
| `dio` | No import found (http is used) |
| `universal_io` | No import found |
| `app_set_id` | No import found |
| `flutter_device_type` | No import found |
| `flutter_background` | No import found |
| `chat_bubbles` | No import found |
| `tflite_flutter` | No import found |
| `pointycastle` | No import found (crypto package used instead) |
| `pie_chart` | No import found |
| `bottom_sheet` | No import found |
| `carousel_slider` | No import found |
| `firebase_auth` | No import found |

## UNUSED FILES (to remove)

| File | Reason |
|------|--------|
| `lib/transactions/AllTransaction.dart` | Never imported (duplicate of SeeAllTransactions) |
| `lib/providers/WalletOperations1.dart` | Never imported |
| `lib/notification_helper.dart` | Fully commented out, never imported |
| `lib/ButtomNavigation/buttonNavigationbar2.dart` | Never imported |
| `lib/filter/filter_screen.dart` | FilterScreen is commented out in mostusedservices |
| `lib/filter/filteredTransactions.dart` | Only used by filter_screen.dart |
| `lib/filter/styled_transaction_widget.dart` | Only used by filteredTransactions.dart |

## PACKAGES KEPT (in use)

- animations, liquid_swipe (Registration2)
- quickalert (login)
- dropdown_button2 (banktransfer, etc.)
- page_view_indicators (pageviewscr)
- flutter_markdown (policyDialog)
- google_nav_bar (buttonNavigationbar2 – but that file is unused, so google_nav_bar could be removed if we delete buttonNavigationbar2)
- iconsax, flutter_animate (chat_screen)
- mobile_scanner (MerchantAccount)
- collection (HomeSliderandTransaction)
- crypto (deviceInfo for JWT)
