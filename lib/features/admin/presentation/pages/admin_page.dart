import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await _supabase
          .from('user_results')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _replayResult(Map<String, dynamic> user) {
    HapticFeedback.mediumImpact();
    
    final birthDate = DateTime.parse(user['birth_date']);
    
    // 시간 정보 처리
    DateTime finalBirthDate = birthDate;
    if (user['birth_hour'] != null) {
      finalBirthDate = DateTime(
        birthDate.year,
        birthDate.month,
        birthDate.day,
        user['birth_hour'],
      );
    }

    context.read<DestinyBloc>().add(
      AnalyzeFortune(
        birthDateTime: finalBirthDate,
        isLunar: user['is_lunar'] ?? false,
        mbtiType: user['mbti'],
        gender: user['gender'],
        name: user['name'], // 이름 전달
        useNightSubhour: true,
      ),
    );

    context.push('/result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('관리자 페이지'),
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                final createdAt = DateTime.parse(user['created_at']).toLocal();
                final birthDate = DateTime.parse(user['birth_date']);
                final name = user['name']?.toString() ?? '';
                
                return ListTile(
                  onTap: () => _replayResult(user),
                  tileColor: AppColors.surfaceOf(context),
                  title: Row(
                    children: [
                      Text(
                        name.isNotEmpty ? name : '무명',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: name.isNotEmpty
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textTertiaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user['mbti'] ?? '',
                          style: AppTypography.caption.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '생일: ${DateFormat('yyyy-MM-dd').format(birthDate)} (${user['gender'] == 'male' ? '남' : '여'})',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      Text(
                        '조회: ${DateFormat('MM/dd HH:mm').format(createdAt)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryOf(context),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                );
              },
            ),
    );
  }
}
