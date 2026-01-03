import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/auth/auth_manager.dart';
import '../../data/services/supabase_support_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final service = getIt.tryGet<SupabaseSupportService>();
    if (service == null) {
      _showSnackBar('현재 환경에서는 고객센터를 이용할 수 없습니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authManager = AuthManager();
      final id = await service.createTicket(
        title: _titleController.text.trim(),
        contact: _contactController.text.trim(),
        message: _messageController.text.trim(),
        userId: authManager.userProfile?.id,
        firebaseUid: authManager.firebaseUser?.uid,
      );

      if (!mounted) return;

      if (id == null) {
        _showSnackBar('문의 접수에 실패했습니다. 잠시 후 다시 시도해주세요.');
        return;
      }

      _showSnackBar('문의가 접수되었습니다. 감사합니다.');
      context.pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimaryOf(context),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '고객센터',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowOf(
                          context,
                          lightOpacity: 0.04,
                          darkOpacity: 0.12,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '문의 남기기',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: '제목',
                        controller: _titleController,
                        hintText: '예) 결제가 실패했어요',
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return '제목을 입력해주세요.';
                          if (v.length < 2) return '제목은 2자 이상 입력해주세요.';
                          return null;
                        },
                        maxLines: 1,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: '연락처(휴대폰 또는 이메일)',
                        controller: _contactController,
                        hintText: '예) 010-1234-5678 또는 email@example.com',
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return '연락처를 입력해주세요.';
                          if (v.length < 5) return '연락처를 정확히 입력해주세요.';
                          return null;
                        },
                        maxLines: 1,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: '내용',
                        controller: _messageController,
                        hintText: '상세 내용을 적어주세요',
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return '내용을 입력해주세요.';
                          if (v.length < 5) return '내용은 5자 이상 입력해주세요.';
                          return null;
                        },
                        maxLines: 8,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('문의 접수'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.surfaceVariantOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
