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
  SupabaseClient? _supabase;
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
  final FocusNode _passwordFocus = FocusNode();
  static const String _adminPassword = '!tmdgks20'; // TODO: 환경변수로 이동

  // Drawer 메뉴 선택 상태
  int _selectedMenuIndex = 0; // 0: 사용자 목록, 1: 고객센터 문의

  @override
  void initState() {
    super.initState();

    // Supabase 클라이언트 초기화
    try {
      _supabase = Supabase.instance.client;
    } catch (e) {
      debugPrint('⚠️ Supabase 초기화 실패: $e');
      _error = 'Supabase 연결에 실패했습니다';
      _isLoading = false;
    }

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
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
    if (_isLoadingMore || !_hasMoreData || _supabase == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newData = await _supabase!
          .from('user_results')
          .select()
          .order('created_at', ascending: false)
          .range(
            _currentOffset + _pageSize,
            _currentOffset + _pageSize * 2 - 1,
          );

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

  // 비밀번호 확인
  void _checkPassword() {
    if (_passwordController.text == _adminPassword) {
      setState(() {
        _isAuthenticated = true;
      });
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
      _passwordFocus.requestFocus();
    }
  }

  // ✅ FIX 7: 에러 처리 개선
  // ✅ FIX 9: Pagination - limit을 _pageSize로 변경
  Future<void> _fetchUsers() async {
    if (_supabase == null) {
      setState(() {
        _isLoading = false;
        _error = 'Supabase 연결에 실패했습니다';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _users = [];
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final data = await _supabase!
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

  /// 사용자의 궁합 분석 결과 조회
  Future<void> _showCompatibilityResults(
    String userResultId,
    String userName,
  ) async {
    try {
      final compatibilities = await _supabase!
          .from('compatibility_results')
          .select()
          .eq('user_result_id', userResultId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      if (compatibilities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('궁합 분석 기록이 없습니다'),
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }

      // 궁합 결과 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$userName님의 궁합 분석'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: compatibilities.length,
              itemBuilder: (context, index) {
                final compat = compatibilities[index];
                final createdAt = DateTime.parse(
                  compat['created_at'],
                ).toLocal();
                final partnerName = compat['partner_name'] ?? '상대방';
                final overallScore = compat['overall_score'] as int;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getScoreColor(overallScore),
                      child: Text(
                        overallScore.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(partnerName),
                    subtitle: Text(
                      '분석: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _showCompatibilityDetail(compat);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching compatibility results: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('궁합 기록 조회 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 궁합 분석 상세 정보 표시
  void _showCompatibilityDetail(Map<String, dynamic> compat) {
    final partnerName = compat['partner_name'] ?? '상대방';
    final partnerBirthDate = DateTime.parse(
      compat['partner_birth_date'],
    ).toLocal();
    final partnerMbti = compat['partner_mbti'] ?? '미등록';
    final overallScore = compat['overall_score'] as int;
    final sajuScore = compat['saju_score'] as int;
    final mbtiScore = compat['mbti_score'] as int?;
    final insights = compat['insights'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$partnerName님과의 궁합'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '생년월일: ${DateFormat('yyyy-MM-dd').format(partnerBirthDate)}',
              ),
              Text('MBTI: $partnerMbti'),
              const Divider(),
              Text('종합 점수: $overallScore점'),
              Text('사주 점수: $sajuScore점'),
              if (mbtiScore != null) Text('MBTI 점수: $mbtiScore점'),
              if (insights != null) ...[
                const Divider(),
                Text('요약: ${insights['summary']}'),
                const SizedBox(height: 8),
                if (insights['strengths'] != null) ...[
                  const Text(
                    '강점:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...(insights['strengths'] as List).map((s) => Text('• $s')),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Future<List<Map<String, dynamic>>> _fetchSupportTickets() async {
    if (_supabase == null) return [];
    try {
      final response = await _supabase!
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false)
          .limit(200);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  void _showSupportTicketDetail(Map<String, dynamic> ticket) {
    final createdAtRaw = ticket['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw)?.toLocal()
        : null;

    final title = ticket['title']?.toString() ?? '';
    final contact = ticket['contact']?.toString() ?? '';
    final message = ticket['message']?.toString() ?? '';
    final status = ticket['status']?.toString() ?? 'open';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.isNotEmpty ? title : '문의 상세'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('상태: $status'),
                const SizedBox(height: 8),
                Text('연락처: $contact'),
                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '접수: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt)}',
                  ),
                ],
                const Divider(),
                Text(message),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
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
        0, // 분은 원본 값 유지하거나 0으로 설정
        0, // 초는 0
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
        useNightSubhour: useNightSubhour, // ✅ FIX 10: 원본 값 사용
      ),
    );

    context.push('/result');
  }

  // 비밀번호 입력 UI
  Widget _buildPasswordInput() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                '관리자 인증',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '관리자 비밀번호를 입력하세요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: true,
                autofocus: true,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: AppColors.surfaceOf(context),
                ),
                onSubmitted: (_) => _checkPassword(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  '취소',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIX 8: 에러 UI 빌더
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  '관리자 페이지',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('사용자 목록'),
            selected: _selectedMenuIndex == 0,
            onTap: () {
              setState(() => _selectedMenuIndex = 0);
              Navigator.pop(context); // Drawer 닫기
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('고객센터 문의'),
            selected: _selectedMenuIndex == 1,
            onTap: () {
              setState(() => _selectedMenuIndex = 1);
              Navigator.pop(context); // Drawer 닫기
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              setState(() {
                _isAuthenticated = false;
                _selectedMenuIndex = 0;
              });
              Navigator.pop(context);
            },
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
        title: Text(_selectedMenuIndex == 0 ? '사용자 목록' : '고객센터 문의'),
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
      ),
      drawer: _isAuthenticated ? _buildDrawer() : null,
      // ✅ FIX 8: 에러 상태 UI 추가
      // ✅ FIX 9: Pagination - ScrollController 추가, ListView.builder로 변경
      body: !_isAuthenticated
          ? _buildPasswordInput()
          : _selectedMenuIndex == 0
              ? _buildUserListScreen()
              : _buildSupportTicketsScreen(),
    );
  }

  Widget _buildUserListScreen() {
    return _isLoading
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
                      if (index == _users.length)
                        return const SizedBox.shrink();
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
                      final createdAt = DateTime.parse(
                        user['created_at'],
                      ).toLocal();
                      // ✅ FIX 3: toLocal() 추가 - UTC 시간을 로컬 타임존으로 변환
                      final birthDate = DateTime.parse(
                        user['birth_date'],
                      ).toLocal();
                      final name = user['name']?.toString() ?? '';

                      // ✅ FIX 4: 성별 값 유효성 검사
                      final genderDisplay =
                          (user['gender'] == 'male' || user['gender'] == 'M')
                          ? '남'
                          : '여';

                      // ✅ FIX 5: MBTI 유효성 검사 (null 또는 빈 값 처리)
                      final mbtiDisplay =
                          (user['mbti']?.toString() ?? '').isNotEmpty
                          ? user['mbti'].toString().toUpperCase()
                          : '미등록';

                      // 생시 정보
                      final birthHour = user['birth_hour'] as int?;
                      final birthTimeDisplay = birthHour != null
                          ? ' ${birthHour}시'
                          : '';

                      // 음력/양력 정보
                      final isLunar = user['is_lunar'] as bool? ?? false;
                      final calendarType = isLunar ? '음력' : '양력';

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mbtiDisplay,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '생일: ${DateFormat('yyyy-MM-dd').format(birthDate)}$birthTimeDisplay ($calendarType, $genderDisplay)',
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border, size: 20),
                              tooltip: '궁합 분석 조회',
                              onPressed: () {
                                final userId = user['id'] as String;
                                _showCompatibilityResults(
                                  userId,
                                  name.isNotEmpty ? name : '무명',
                                );
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      );
                    },
                  ));
  }

  Widget _buildSupportTicketsScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSupportTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent_outlined,
                  size: 64,
                  color: AppColors.textTertiaryOf(context),
                ),
                const SizedBox(height: 16),
                Text(
                  '문의가 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final t = tickets[index];
            final title = t['title']?.toString() ?? '제목 없음';
            final contact = t['contact']?.toString() ?? '';
            final message = t['message']?.toString() ?? '';
            final status = t['status']?.toString() ?? 'open';

            final createdAtRaw = t['created_at']?.toString();
            final createdAt = createdAtRaw != null
                ? DateTime.tryParse(createdAtRaw)?.toLocal()
                : null;

            // 상태 색상
            Color statusColor;
            switch (status) {
              case 'resolved':
                statusColor = Colors.green;
                break;
              case 'closed':
                statusColor = Colors.grey;
                break;
              default:
                statusColor = Colors.orange;
            }

            return ListTile(
              tileColor: AppColors.surfaceOf(context),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textTertiaryOf(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryOf(context),
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textTertiaryOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MM/dd HH:mm').format(createdAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showSupportTicketDetail(t),
            );
          },
        );
      },
    );
  }
}
