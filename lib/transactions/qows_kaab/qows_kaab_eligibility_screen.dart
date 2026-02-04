import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/252pay_api_service.dart';
import 'qows_kaab_application_screen.dart';

class QowsKaabEligibilityScreen extends StatefulWidget {
  final String? walletAccountId;

  const QowsKaabEligibilityScreen({
    super.key,
    required this.walletAccountId,
  });

  @override
  State<QowsKaabEligibilityScreen> createState() =>
      _QowsKaabEligibilityScreenState();
}

class _QowsKaabEligibilityScreenState extends State<QowsKaabEligibilityScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();

  String? selectedServiceModel; // "monthly_pack" or "daily_credit"
  final TextEditingController monthlyIncomeController = TextEditingController();
  final TextEditingController familySizeController = TextEditingController();
  String? usageType;
  bool isLoading = false;
  Map<String, dynamic>? eligibilityResult;

  @override
  void dispose() {
    monthlyIncomeController.dispose();
    familySizeController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    if (selectedServiceModel == null) {
      _showError('Please select a service model');
      return;
    }

    setState(() {
      isLoading = true;
      eligibilityResult = null;
    });

    try {
      final result = await api.checkQowsKaabEligibility(
        walletAccount: widget.walletAccountId ?? '',
        serviceModel: selectedServiceModel!,
        monthlyIncome: double.tryParse(monthlyIncomeController.text),
        familySize: familySizeController.text.isNotEmpty
            ? int.tryParse(familySizeController.text)
            : null,
        usageType: usageType,
      );

      setState(() {
        eligibilityResult = result;
        isLoading = false;
      });

      if (result['eligible'] == true) {
        // Navigate to application screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QowsKaabApplicationScreen(
              walletAccountId: widget.walletAccountId,
              serviceModel: selectedServiceModel!,
              eligibilityData: result,
              monthlyIncome: double.tryParse(monthlyIncomeController.text),
            ),
          ),
        );
      } else {
        // Show backend message so user sees exact reason (e.g. "You already have an application", "Minimum income is $300 from eligibility rules")
        final message = result['message']?.toString().trim() ?? result['reason']?.toString().trim();
        _showError(message?.isNotEmpty == true ? message! : 'You are not eligible for QOWS KAAB.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'QOWS KAAB Eligibility',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: br12,
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'QOWS KAAB Service Models',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildServiceModelOption(
                    'Monthly Pack',
                    'Take a full food package, payment due next month',
                    'monthly_pack',
                    Icons.shopping_cart,
                  ),
                  const SizedBox(height: 12),
                  _buildServiceModelOption(
                    'Daily Credit',
                    'Take daily food items on credit, payment at end of month',
                    'daily_credit',
                    Icons.credit_card,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Monthly Income (Required)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: monthlyIncomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter your monthly income',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Family Size (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: familySizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter number of family members',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Usage Type (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: usageType,
              decoration: InputDecoration(
                hintText: 'Select usage type',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
              items: ['household', 'business'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  usageType = value;
                });
              },
            ),
            if (eligibilityResult != null && eligibilityResult!['eligible'] != true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: br12,
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        eligibilityResult!['message']?.toString().trim() ??
                            eligibilityResult!['reason']?.toString().trim() ??
                            'You are not eligible for QOWS KAAB.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _checkEligibility,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: br12),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Check Eligibility',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceModelOption(
    String title,
    String description,
    String value,
    IconData icon,
  ) {
    final isSelected = selectedServiceModel == value;
    return InkWell(
      onTap: () {
        setState(() {
          selectedServiceModel = value;
        });
      },
      borderRadius: br12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: br12,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
