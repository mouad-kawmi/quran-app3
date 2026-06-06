import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/core/theme.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  // 🔴 تم إعداد الرابط الخاص بك بنجاح
  static const String _formspreeUrl = 'https://formspree.io/f/maqzqyez';

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    if (_formspreeUrl.contains('YOUR_FORM_ID_HERE')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إعداد رابط Formspree في الكود أولاً (contact_us_screen.dart)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_formspreeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
          // 'email': 'optional_email@example.com', // إذا أردت أن يكتب المستخدم إيميله لترد عليه
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _isSuccess = true);
        _subjectController.clear();
        _messageController.clear();
      } else {
        throw Exception('Failed to send');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الإرسال، تحقق من اتصالك بالإنترنت.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تواصل معنا',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'هل لديك اقتراح أو واجهتك مشكلة؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نسعد باستقبال ملاحظاتك لتطوير التطبيق وتقديم تجربة أفضل.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: dark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isSuccess)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'تم الإرسال بنجاح!\nشكراً لك على تواصلك معنا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الرسالة (اقتراح / تبليغ عن خطأ)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'مثال: مشكلة في تلاوة سورة الكهف...',
                          filled: true,
                          fillColor: dark ? AppTheme.darkElevatedSurfaceColor : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'نص الرسالة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'اكتب تفاصيل الرسالة هنا...',
                          filled: true,
                          fillColor: dark ? AppTheme.darkElevatedSurfaceColor : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'إرسال رسالة الآن',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
