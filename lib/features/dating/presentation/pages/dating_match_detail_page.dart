import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../data/models/dating_profile.dart';
import '../../data/services/dating_service.dart';

class DatingMatchDetailPage extends StatefulWidget {
  final String matchId;

  const DatingMatchDetailPage({super.key, required this.matchId});

  @override
  State<DatingMatchDetailPage> createState() => _DatingMatchDetailPageState();
}

class _DatingMatchDetailPageState extends State<DatingMatchDetailPage> {
  bool _isLoading = true;
  String? _error;
  DatingMatch? _match;

  String? _currentUserProfileId;

  final _openChatController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _openChatController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentUserProfileId ??= await DatingService.getCurrentUserProfileId();
      if (!mounted) return;

      if (_currentUserProfileId == null) {
        setState(() {
          _match = null;
          _error = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      final match = await DatingService.getMatchById(widget.matchId);
      if (!mounted) return;

      if (match == null) {
        setState(() {
          _match = null;
          _error = '매치를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final currentUserId = _currentUserProfileId;
      final isUser1 = currentUserId != null && match.user1Id == currentUserId;
      final isUser2 = currentUserId != null && match.user2Id == currentUserId;

      if (!isUser1 && !isUser2) {
        setState(() {
          _match = null;
          _error = '권한이 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final myUrl = isUser1 ? match.user1OpenChatUrl : match.user2OpenChatUrl;
      _openChatController.text = myUrl ?? '';

      setState(() {
        _match = match;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _accept() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final ok = await DatingService.acceptMatch(widget.matchId);
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('승락 처리에 실패했습니다.')));
        return;
      }

      await _load();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _saveOpenChatUrl() async {
    if (_isSubmitting) return;

    final url = _openChatController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오픈채팅 URL을 입력해주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ok = await DatingService.setOpenChatUrl(
        matchId: widget.matchId,
        openChatUrl: url,
      );
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('URL 저장에 실패했습니다.')));
        return;
      }

      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오픈채팅 URL을 저장했습니다.')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('매치'),
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _match == null
          ? _buildError(message: '매치를 찾을 수 없습니다.')
          : _buildBody(_match!),
    );
  }

  Widget _buildError({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? _error ?? '오류가 발생했습니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DatingMatch match) {
    final currentUserId = _currentUserProfileId;
    final isUser1 = currentUserId != null && match.user1Id == currentUserId;

    final myAccepted = isUser1 ? match.user1Accepted : match.user2Accepted;
    final otherAccepted = isUser1 ? match.user2Accepted : match.user1Accepted;

    final myUrl = isUser1 ? match.user1OpenChatUrl : match.user2OpenChatUrl;
    final otherUrl = isUser1 ? match.user2OpenChatUrl : match.user1OpenChatUrl;

    final isAccepted = match.acceptedAt != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '승락 상태',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),
                _StatusRow(label: '나', value: myAccepted ? '승락' : '대기'),
                const SizedBox(height: 8),
                _StatusRow(label: '상대', value: otherAccepted ? '승락' : '대기'),
                const SizedBox(height: 12),
                if (!myAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _accept,
                      child: const Text('승락하기'),
                    ),
                  )
                else
                  Text(
                    isAccepted ? '상호 승락 완료' : '상대의 승락을 기다리는 중입니다.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오픈카카오톡 오픈채팅 1:1 링크',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '카카오톡 접속 → 채팅 탭 → 우측상단 + → 새로운채팅(오픈채팅) → 오픈채팅 만들기 → 1:1 오픈채팅 링크를 복사해서 등록해주세요.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (!isAccepted)
                  Text(
                    '상호 승락 후에 링크를 등록할 수 있어요.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _openChatController,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: '내 오픈채팅 URL',
                      hintText: 'https://open.kakao.com/...',
                      suffixIcon: myUrl != null && myUrl.isNotEmpty
                          ? IconButton(
                              onPressed: () => _launch(myUrl),
                              icon: const Icon(Icons.open_in_new),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _saveOpenChatUrl,
                      child: const Text('내 링크 저장'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '상대 링크',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (otherUrl == null || otherUrl.isEmpty)
                    Text(
                      '상대가 아직 링크를 등록하지 않았습니다.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUrl,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _launch(otherUrl),
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
