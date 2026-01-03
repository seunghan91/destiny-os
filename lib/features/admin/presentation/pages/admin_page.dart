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
  // ✅ FIX 6: 에러 상태 추가
  String? _error;

  // ✅ FIX 9: Pagination 추가
  static const int _pageSize = 50;
  int _currentOffset = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  late ScrollController _scrollController;

  // 비밀번호 인증 상태
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  static const String _adminPassword = '!tmdgks20'; // TODO: 환경변수로 이동

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 인증되지 않았으면 비밀번호 입력 다이얼로그 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAuthenticated) {
        _showPasswordDialog();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ FIX 9: 스크롤 끝 감지 - 더 많은 데이터 로드
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 끝에서 500px 이내에 도달하면 다음 데이터 로드
    if (currentScroll >= (maxScroll - 500)) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreUsers();
      }
    }
  }

  // ✅ FIX 9: 더 많은 데이터 로드
  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newData = await _supabase
          .from('user_results')
          .select()
          .order('created_at', ascending: false)
          .range(_currentOffset + _pageSize, _currentOffset + _pageSize * 2 - 1);

      setState(() {
        if (newData.isEmpty) {
          _hasMoreData = false;
        } else {
          _users.addAll(List<Map<String, dynamic>>.from(newData));
          _currentOffset += _pageSize;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more users: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // 비밀번호 입력 다이얼로그
  Future<void> _showPasswordDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('관리자 인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리자 비밀번호를 입력하세요'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) => _checkPassword(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              context.pop(); // 관리자 페이지에서 나가기
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: _checkPassword,
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true && mounted) {
      // 인증 실패 시 페이지에서 나가기
      context.pop();
    }
  }

  // 비밀번호 확인
  void _checkPassword() {
    if (_passwordController.text == _adminPassword) {
      setState(() {
        _isAuthenticated = true;
      });
      Navigator.of(context).pop(true);
      _fetchUsers(); // 인증 성공 시 데이터 로드
    } else {
      // 비밀번호 틀림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 올바르지 않습니다'),
          backgroundColor: Colors.red,
        ),
      );
      _passwordController.clear();
    }
  }

  // ✅ FIX 7: 에러 처리 개선
  // ✅ FIX 9: Pagination - limit을 _pageSize로 변경
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _users = [];
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final data = await _supabase
          .from('user_results')
          .select()
          .order('created_at', ascending: false)
          .limit(_pageSize);

      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _replayResult(Map<String, dynamic> user) {
    HapticFeedback.mediumImpact();

    // ✅ FIX 1: toLocal() 추가 - UTC → 로컬 타임존 변환
    // DB의 birth_date는 UTC로 저장되므로 로컬 타임존으로 변환 필수
    final birthDate = DateTime.parse(user['birth_date']).toLocal();

    // ✅ FIX 2: birth_hour 정보가 있으면 시간을 정확히 설정
    // birth_hour는 이미 로컬 시간 기준이므로, 기존 시간 정보를 교체
    DateTime finalBirthDate = birthDate;
    if (user['birth_hour'] != null && user['birth_hour'] is int) {
      finalBirthDate = DateTime(
        birthDate.year,
        birthDate.month,
        birthDate.day,
        user['birth_hour'] as int,
        0,  // 분은 원본 값 유지하거나 0으로 설정
        0,  // 초는 0
      );
    }

    // ✅ FIX 10: use_night_subhour 원본 값 복원
    final useNightSubhour = user['use_night_subhour'] as bool? ?? false;

    // ✅ 수정된 데이터로 DestinyBloc 호출
    context.read<DestinyBloc>().add(
      AnalyzeFortune(
        birthDateTime: finalBirthDate,
        isLunar: user['is_lunar'] ?? false,
        mbtiType: user['mbti'],
        gender: user['gender'],
        name: user['name'],
        useNightSubhour: useNightSubhour,  // ✅ FIX 10: 원본 값 사용
      ),
    );

    context.push('/result');
  }

  // ✅ FIX 8: 에러 UI 빌더
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            '데이터 로드 실패',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error ?? '알 수 없는 오류가 발생했습니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
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
      // ✅ FIX 8: 에러 상태 UI 추가
      // ✅ FIX 9: Pagination - ScrollController 추가, ListView.builder로 변경
      body: !_isAuthenticated
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : (_users.isEmpty
                  ? Center(
                      child: Text(
                        '조회할 데이터가 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) {
                        // 마지막 로딩 인디케이터 이전에는 divider 표시
                        if (index == _users.length) return const SizedBox.shrink();
                        return const Divider(height: 1);
                      },
                      itemBuilder: (context, index) {
                        // 마지막 항목이 로딩 인디케이터면 표시
                        if (index == _users.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final user = _users[index];
                        final createdAt = DateTime.parse(user['created_at']).toLocal();
                        // ✅ FIX 3: toLocal() 추가 - UTC 시간을 로컬 타임존으로 변환
                        final birthDate = DateTime.parse(user['birth_date']).toLocal();
                        final name = user['name']?.toString() ?? '';

                        // ✅ FIX 4: 성별 값 유효성 검사
                        final genderDisplay = (user['gender'] == 'male' || user['gender'] == 'M') ? '남' : '여';

                        // ✅ FIX 5: MBTI 유효성 검사 (null 또는 빈 값 처리)
                        final mbtiDisplay = (user['mbti']?.toString() ?? '').isNotEmpty
                            ? user['mbti'].toString().toUpperCase()
                            : '미등록';

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
                                  mbtiDisplay,
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
                                '생일: ${DateFormat('yyyy-MM-dd').format(birthDate)} ($genderDisplay)',
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
                    )),
    );
  }
}
