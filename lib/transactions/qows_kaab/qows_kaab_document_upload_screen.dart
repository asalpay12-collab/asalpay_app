import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/qows_kaab_api_service.dart';
import 'qows_kaab_tracking_screen.dart';

class QowsKaabDocumentUploadScreen extends StatefulWidget {
  /// When null, application is created on "Submit Application" (formData must be set).
  final int? qowsKaabId;
  final String walletAccountId;
  /// When set, application is not yet created; Submit Application will create it then go to tracking.
  final Map<String, dynamic>? applicationFormData;

  const QowsKaabDocumentUploadScreen({
    super.key,
    this.qowsKaabId,
    required this.walletAccountId,
    this.applicationFormData,
  });

  @override
  State<QowsKaabDocumentUploadScreen> createState() =>
      _QowsKaabDocumentUploadScreenState();
}

class _QowsKaabDocumentUploadScreenState
    extends State<QowsKaabDocumentUploadScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final QowsKaabApiService _api = QowsKaabApiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool isLoading = true;
  List<Map<String, dynamic>> _documentTypes = [];
  Set<String> _existingDocumentTypes = {};
  String? _selectedDocumentKey;
  File? _pickedFile;
  String _pickedFileName = '';
  final TextEditingController _documentNumberController = TextEditingController();
  bool isUploading = false;
  bool isSubmitting = false;
  /// Pending file uploads when application not yet created (will upload after create on Submit).
  final List<Map<String, dynamic>> _pendingUploads = [];

  bool get _createOnSubmit => widget.applicationFormData != null && widget.qowsKaabId == null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadDocumentTypes(),
        _loadCustomerDocuments(),
      ]);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadDocumentTypes() async {
    final list = await _api.getDocumentTypes();
    if (mounted) setState(() => _documentTypes = list);
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerDocuments() async {
    final res = await _api.getCustomerDocuments(
        walletAccount: widget.walletAccountId);
    final data = res['data'];
    final documents =
        data != null ? (data['documents'] as List?) ?? [] : [];
    final Set<String> existing = {};
    for (final d in documents) {
      if (d is Map && (d['is_expired'] == 0 || d['is_expired'] == false)) {
        final type = d['document_type']?.toString();
        if (type != null && type.isNotEmpty) existing.add(type);
      }
    }
    if (mounted) setState(() => _existingDocumentTypes = existing);
  }

  bool _alreadyHasDocument(String typeKey) =>
      _existingDocumentTypes
          .any((t) => t.toLowerCase() == typeKey.toLowerCase());

  String _docLabel(Map<String, dynamic> doc) =>
      (doc['document_type_label'] ?? doc['label'] ?? doc['document_type_key'] ?? '')?.toString() ?? '';
  String _docSubtitle(Map<String, dynamic> doc) =>
      (doc['document_type_description'] ?? doc['subtitle'] ?? doc['document_type_label'] ?? '')?.toString() ?? '';
  String _docKey(Map<String, dynamic> doc) =>
      (doc['document_type_key'] ?? doc['key'] ?? '')?.toString() ?? '';

  Map<String, dynamic>? _getSelectedDocument() {
    if (_selectedDocumentKey == null) return null;
    try {
      return _documentTypes.firstWhere(
        (e) => _docKey(e) == _selectedDocumentKey,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFile() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select document type', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF005653)),
              title: const Text('Image (JPG/PNG)'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF005653)),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedFile = File(result.files.single.path!);
          _pickedFileName = result.files.single.name.isNotEmpty
              ? result.files.single.name
              : 'document.pdf';
        });
        _showSuccess('PDF selected');
      }
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _pickedFile = File(image.path);
        _pickedFileName = image.name;
      });
      _showSuccess('Image selected');
    }
  }

  Future<void> _uploadDocument() async {
    final key = _selectedDocumentKey;
    final doc = _getSelectedDocument();
    if (key == null || doc == null) {
      _showError('Please select a document type');
      return;
    }
    if (_pickedFile == null || !await _pickedFile!.exists()) {
      _showError('Please select a file first');
      return;
    }
    String name = _pickedFileName;
    if (name.isEmpty) name = 'document';
    String? ext = name.contains('.') ? name.split('.').last.toLowerCase() : null;
    if (ext == null || ext.isEmpty) ext = 'pdf';
    if (ext != 'pdf' && ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      ext = 'jpg';
    }
    final docNumber = _documentNumberController.text.trim();

    if (_createOnSubmit) {
      final bytes = await _pickedFile!.readAsBytes();
      // One document per type per customer: replace existing pending of same type
      final hadSameType = _pendingUploads.any((e) => e['typeKey'] == key);
      _pendingUploads.removeWhere((e) => e['typeKey'] == key);
      _pendingUploads.add({
        'typeKey': key,
        'documentName': name,
        'documentFile': base64Encode(bytes),
        'fileExtension': ext,
        'documentNumber': docNumber.isEmpty ? null : docNumber,
      });
      _showSuccess(
        hadSameType
            ? 'Same document type replaced. Will upload when you submit.'
            : 'Document will be uploaded when you submit.',
      );
      setState(() {
        _pickedFile = null;
        _pickedFileName = '';
        _documentNumberController.clear();
      });
      return;
    }

    final qowsKaabId = widget.qowsKaabId;
    if (qowsKaabId == null) return;

    setState(() => isUploading = true);
    try {
      final bytes = await _pickedFile!.readAsBytes();
      final base64File = base64Encode(bytes);
      await _api.uploadDocument(
        qowsKaabId: qowsKaabId,
        documentType: key,
        documentName: name,
        documentFile: base64File,
        fileExtension: ext,
        documentNumber: docNumber.isEmpty ? null : docNumber,
      );
      _showSuccess('${_docLabel(doc)} uploaded successfully');
      setState(() {
        _existingDocumentTypes.add(key);
        _pickedFile = null;
        _pickedFileName = '';
        _documentNumberController.clear();
        isUploading = false;
      });
    } catch (e) {
      setState(() => isUploading = false);
      _showError(e.toString());
    }
  }

  Future<void> _submitApplication() async {
    if (_createOnSubmit) {
      final formData = widget.applicationFormData;
      if (formData == null) return;
      setState(() => isSubmitting = true);
      try {
        // If user picked a file but did not tap "Upload", add it to pending now
        if (_pickedFile != null &&
            await _pickedFile!.exists() &&
            _selectedDocumentKey != null) {
          final key = _selectedDocumentKey!;
          String name = _pickedFileName;
          if (name.isEmpty) name = 'document';
          String? ext = name.contains('.') ? name.split('.').last.toLowerCase() : null;
          if (ext == null || ext.isEmpty) ext = 'pdf';
          if (ext != 'pdf' && ext != 'jpg' && ext != 'jpeg' && ext != 'png') ext = 'jpg';
          final bytes = await _pickedFile!.readAsBytes();
          final docNumber = _documentNumberController.text.trim();
          _pendingUploads.removeWhere((e) => e['typeKey'] == key);
          _pendingUploads.add({
            'typeKey': key,
            'documentName': name,
            'documentFile': base64Encode(bytes),
            'fileExtension': ext,
            'documentNumber': docNumber.isEmpty ? null : docNumber,
          });
          if (mounted) {
            setState(() {
              _pickedFile = null;
              _pickedFileName = '';
            });
          }
        }
        final result = await _api.createApplication(applicationData: formData);
        if (!mounted) return;
        final data = result['data'];
        final qowsKaabId = data != null && data['qows_kaab_id'] != null
            ? int.tryParse(data['qows_kaab_id'].toString())
            : null;
        if (qowsKaabId != null && _pendingUploads.isNotEmpty) {
          final uploadErrors = <String>[];
          for (final p in _pendingUploads) {
            try {
              await _api.uploadDocument(
                qowsKaabId: qowsKaabId,
                documentType: p['typeKey'] as String,
                documentName: p['documentName'] as String,
                documentFile: p['documentFile'] as String,
                fileExtension: p['fileExtension'] as String,
                documentNumber: p['documentNumber'] as String?,
              );
            } catch (e) {
              uploadErrors.add('${p['typeKey']}: ${e.toString()}');
            }
          }
          if (uploadErrors.isNotEmpty && mounted) {
            _showError('Some documents could not be uploaded: ${uploadErrors.join('; ')}');
          }
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QowsKaabTrackingScreen(
              walletAccountId: widget.walletAccountId,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) _showError(e.toString());
      } finally {
        if (mounted) setState(() => isSubmitting = false);
      }
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QowsKaabTrackingScreen(
          walletAccountId: widget.walletAccountId,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Daily Credit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Documents (Optional) - isla designka Screenshot 140512 ---
                  Text(
                    'Documents (Optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can upload supporting documents to verify your application. If you already have documents uploaded, they will be shown below. Documents are optional – upload if needed or tap Submit Application to continue.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Select Document Type (Optional)
                  Text(
                    'Select Document Type (Optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedDocumentKey,
                    decoration: InputDecoration(
                      hintText: 'Select Document Type (Optional)',
                      prefixIcon: const Icon(Icons.description_outlined,
                          color: Color(0xFF005653)),
                      suffixIcon: _selectedDocumentKey != null
                          ? Icon(Icons.check_circle,
                              color: Colors.green.shade700, size: 22)
                          : const Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(borderRadius: br12),
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    items: _documentTypes
                        .where((t) => _docKey(t).isNotEmpty)
                        .map((t) => DropdownMenuItem<String>(
                              value: _docKey(t),
                              child: Text(_docLabel(t), overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedDocumentKey = v;
                        _pickedFile = null;
                        _pickedFileName = '';
                        _documentNumberController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can upload documents to verify your application.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // When a document type is selected: show card (already uploaded) or upload area
                  if (_selectedDocumentKey != null) ...[
                    _buildSelectedDocumentContent(),
                    const SizedBox(height: 24),
                  ],

                  // Submit Application – only action that saves to database; documents optional
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: br12),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Submit Application',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            ),
    );
  }

  Widget _buildSelectedDocumentContent() {
    final doc = _getSelectedDocument();
    if (doc == null) return const SizedBox.shrink();
    final key = _docKey(doc);
    final label = _docLabel(doc);
    final subtitle = _docSubtitle(doc).isEmpty ? label : _docSubtitle(doc);
    final alreadyHas = _alreadyHasDocument(key);

    // Already uploaded: card like Screenshot 140534
    if (alreadyHas) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: br12,
          border: Border.all(color: Colors.green.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Already Uploaded',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: br12,
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 22, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You already have this document uploaded. You can upload a new one if needed.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : _pickFile,
                icon: const Icon(Icons.upload_file, size: 22),
                label: Text(
                  'Upload Document',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: br12),
                ),
              ),
            ),
            // After picking file, show upload submit
            if (_pickedFile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: $_pickedFileName',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isUploading ? null : _uploadDocument,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: br12),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Not yet uploaded: upload form (file + optional doc number + Upload)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: br12,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Document number (optional) - la xariiri karo',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _documentNumberController,
            decoration: InputDecoration(
              hintText: 'e.g. ID or passport number (optional)',
              border: OutlineInputBorder(borderRadius: br12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (_pickedFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Selected: $_pickedFileName',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: isUploading ? null : _pickFile,
                icon: const Icon(Icons.attach_file, size: 20),
                label: const Text('Choose file'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: br12),
                ),
              ),
              const SizedBox(width: 12),
              if (_pickedFile != null)
                ElevatedButton(
                  onPressed: isUploading ? null : _uploadDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: br12),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Upload',
                          style: GoogleFonts.poppins(color: Colors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
