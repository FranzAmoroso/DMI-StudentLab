import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/public_news_api_service.dart';
import '../../theme/nightTheme.dart';
import '../social_models.dart';
import 'models/public_news.dart';
import 'public_news_editor_page.dart';

class InstitutionalNewsPage extends StatefulWidget {
  final bool embedded;

  const InstitutionalNewsPage({
    super.key,
    this.embedded = false,
  });

  @override
  State<InstitutionalNewsPage> createState() =>
      _InstitutionalNewsPageState();
}

class _InstitutionalNewsPageState extends State<InstitutionalNewsPage> {
  final PublicNewsApiService _newsApi = PublicNewsApiService();
  final ApiService _apiService = ApiService();
  final AuthSession _session = AuthSession.instance;
  final TextEditingController _searchController = TextEditingController();

  List<PublicNews> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _total = 0;
  int _offset = 0;
  static const int _limit = 30;

  bool _useAcademicFilter = true;
  String _city = '';
  String _university = '';
  String _department = '';
  String _course = '';
  int? _subjectId;

  SocialUser? get _currentUser => _session.currentUser;
  bool get _isGuest => _session.isGuest || !_session.isAuthenticated;

  bool get _canPublish {
    final SocialUser? user = _currentUser;
    if (user == null || !user.isActive) {
      return false;
    }

    final String role = user.role.trim().toLowerCase();
    return role == 'admin' ||
        role == 'creator' ||
        (user.isTeacher && user.isVerifiedTeacher);
  }

  bool get _isAdminPublisher {
    final String role = _currentUser?.role.trim().toLowerCase() ?? '';
    return role == 'admin' || role == 'creator';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _session.addListener(_onSessionChanged);
    _applyDefaultAcademicFilter();
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _session.removeListener(_onSessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(_applyDefaultAcademicFilter);
    _load();
  }

  void _applyDefaultAcademicFilter() {
    final SocialUser? user = _currentUser;

    if (user == null) {
      _useAcademicFilter = false;
      _city = '';
      _university = '';
      _department = '';
      _course = '';
      _subjectId = null;
      return;
    }

    _useAcademicFilter = true;
    _university = user.university.trim();
    _department = user.department.trim();
    _course = user.course.trim();
    _city = '';
    _subjectId = null;
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
    });

    try {
      final PublicNewsFeedResult result = await _newsApi.getFeed(
        search: _searchController.text,
        city: _useAcademicFilter ? _city : '',
        university: _useAcademicFilter ? _university : '',
        department: _useAcademicFilter ? _department : '',
        course: _useAcademicFilter ? _course : '',
        subjectId: _useAcademicFilter ? _subjectId : null,
        limit: _limit,
        offset: 0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = result.items;
        _total = result.total;
        _offset = result.items.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _items.length >= _total) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final PublicNewsFeedResult result = await _newsApi.getFeed(
        search: _searchController.text,
        city: _useAcademicFilter ? _city : '',
        university: _useAcademicFilter ? _university : '',
        department: _useAcademicFilter ? _department : '',
        course: _useAcademicFilter ? _course : '',
        subjectId: _useAcademicFilter ? _subjectId : null,
        limit: _limit,
        offset: _offset,
      );

      if (!mounted) {
        return;
      }

      final Map<int, PublicNews> merged = {
        for (final PublicNews item in _items) item.id: item,
      };

      for (final PublicNews item in result.items) {
        merged[item.id] = item;
      }

      final List<PublicNews> values = merged.values.toList()
        ..sort(
          (PublicNews a, PublicNews b) =>
              b.createdAt.compareTo(a.createdAt),
        );

      setState(() {
        _items = values;
        _total = result.total;
        _offset = result.offset + result.items.length;
      });
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _openPublisher() async {
    if (!_canPublish) {
      return;
    }

    bool? created;

    if (_isAdminPublisher) {
      created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const PublicNewsEditorPage.admin(),
        ),
      );
    } else {
      List<Map<String, dynamic>> subjects = [];

      try {
        subjects = await _apiService.getTeacherSubjects();
      } catch (_) {
        _showMessage(
          'Non è stato possibile caricare le materie verificate.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PublicNewsEditorPage.teacher(
            subjects: subjects,
          ),
        ),
      );
    }

    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete(PublicNews news) async {
    final bool confirmed = await _confirm(
      title: 'Elimina news',
      message: 'Vuoi eliminare questa news?',
      action: 'Elimina',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _newsApi.delete(news.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _items.removeWhere((PublicNews item) => item.id == news.id);
        if (_total > 0) {
          _total--;
        }
      });
      _showMessage('News eliminata.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _moderate(PublicNews news) async {
    final TextEditingController controller = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? validationError;

        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: AppColors.eleganceDeepNavy,
              title: const Text(
                'Rimuovi news',
                style: TextStyle(color: AppColors.pureWhite),
              ),
              content: TextField(
                controller: controller,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                style: const TextStyle(color: AppColors.pureWhite),
                decoration: InputDecoration(
                  labelText: 'Motivo',
                  errorText: validationError,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annulla'),
                ),
                TextButton(
                  onPressed: () {
                    final String value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(() {
                        validationError = 'Inserisci il motivo';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text(
                    'Rimuovi',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    try {
      await _newsApi.moderate(
        newsId: news.id,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items.removeWhere((PublicNews item) => item.id == news.id);
        if (_total > 0) {
          _total--;
        }
      });

      _showMessage('News rimossa.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _report(PublicNews news) async {
    final _ReportDraft? draft = await showModalBottomSheet<_ReportDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.eleganceDeepNavy,
      builder: (_) => const _PublicNewsReportSheet(),
    );

    if (draft == null) {
      return;
    }

    try {
      await _newsApi.report(
        newsId: news.id,
        reason: draft.reason,
        description: draft.description,
      );
      _showMessage('Segnalazione inviata.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _block(PublicNews news) async {
    final bool confirmed = await _confirm(
      title: 'Blocca utente',
      message:
          'Non vedrai più le news pubblicate da ${news.author.fullName}. Vuoi continuare?',
      action: 'Blocca',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _newsApi.blockAuthor(news.authorUserId);
      _showMessage('Utente bloccato.');
      await _load();
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _openFilters() async {
    bool enabled = _useAcademicFilter;
    String city = _city;
    String university = _university;
    String department = _department;
    String course = _course;
    int? subjectId = _subjectId;

    final bool? apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.eleganceDeepNavy,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filtra news',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: enabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Usa contesto accademico',
                        style: TextStyle(color: AppColors.pureWhite),
                      ),
                      onChanged: (bool value) {
                        setSheetState(() {
                          enabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: city,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(labelText: 'Città'),
                      onChanged: (String value) => city = value.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: university,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(labelText: 'Ateneo'),
                      onChanged: (String value) => university = value.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: department,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration:
                          const InputDecoration(labelText: 'Dipartimento'),
                      onChanged: (String value) => department = value.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: course,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(labelText: 'Corso'),
                      onChanged: (String value) => course = value.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: subjectId?.toString() ?? '',
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration:
                          const InputDecoration(labelText: 'ID materia'),
                      onChanged: (String value) {
                        subjectId = int.tryParse(value.trim());
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                enabled = false;
                                city = '';
                                university = '';
                                department = '';
                                course = '';
                                subjectId = null;
                              });
                            },
                            child: const Text('Azzera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext, true);
                            },
                            child: const Text('Applica'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (apply != true || !mounted) {
      return;
    }

    setState(() {
      _useAcademicFilter = enabled;
      _city = city;
      _university = university;
      _department = department;
      _course = course;
      _subjectId = subjectId;
    });

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('News'),
        actions: [
          IconButton(
            tooltip: 'Filtri',
            onPressed: _openFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _canPublish
          ? FloatingActionButton.extended(
              onPressed: _openPublisher,
              backgroundColor: _isAdminPublisher
                  ? AppColors.socialBlue
                  : AppColors.teacherIndigo,
              foregroundColor: AppColors.pureWhite,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Pubblica'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSearch(),
                  const SizedBox(height: 12),
                  _buildFilterSummary(),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildError()
                  else if (_items.isEmpty)
                    _buildEmpty()
                  else ...[
                    for (final PublicNews news in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PublicNewsCard(
                          news: news,
                          isGuest: _isGuest,
                          onOpen: () => _openDetail(news),
                          onDelete:
                              news.canDelete ? () => _delete(news) : null,
                          onModerate:
                              news.canModerate ? () => _moderate(news) : null,
                          onReport:
                              news.canReport ? () => _report(news) : null,
                          onBlock: news.canBlockAuthor
                              ? () => _block(news)
                              : null,
                        ),
                      ),
                    if (_items.length < _total)
                      OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: Text(
                          _loadingMore ? 'Caricamento...' : 'Carica altre news',
                        ),
                      ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _load(),
      style: const TextStyle(color: AppColors.pureWhite),
      decoration: InputDecoration(
        hintText: 'Cerca autore, materia, corso, contenuto...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.skyBlue,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Cancella',
                onPressed: () {
                  _searchController.clear();
                  _load();
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: AppColors.eleganceMidnight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    final List<String> values = [];

    if (_useAcademicFilter) {
      values.addAll([
        _city,
        _university,
        _department,
        _course,
        if (_subjectId != null) 'Materia #$_subjectId',
      ].where((String value) => value.trim().isNotEmpty));
    }

    return Row(
      children: [
        Icon(
          _useAcademicFilter
              ? Icons.school_outlined
              : Icons.public_rounded,
          color: AppColors.materialSky,
          size: 16,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            values.isEmpty ? 'Tutte le news pubbliche' : values.join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          '$_total',
          style: const TextStyle(
            color: AppColors.materialSky,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.newspaper_outlined,
            color: Colors.white30,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Nessuna news disponibile',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Non ci sono comunicazioni compatibili con i filtri selezionati.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(PublicNews news) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicNewsDetailPage(
          news: news,
          isGuest: _isGuest,
        ),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: Text(
            title,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                action,
                style: TextStyle(
                  color: destructive ? Colors.redAccent : AppColors.skyBlue,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  String _friendlyError(Object error) {
    final String value = error.toString().toLowerCase();

    if (value.contains('401')) {
      return 'La sessione non è più valida. Accedi nuovamente.';
    }
    if (value.contains('403')) {
      return 'Non hai i permessi necessari per questa operazione.';
    }
    if (value.contains('404')) {
      return 'La news non è più disponibile.';
    }
    if (value.contains('409')) {
      return 'Questa operazione è già stata registrata.';
    }
    if (value.contains('socket') ||
        value.contains('network') ||
        value.contains('connection') ||
        value.contains('host lookup')) {
      return 'Non è stato possibile connettersi a StudentLab. Controlla la connessione e riprova.';
    }
    return 'Non è stato possibile completare l’operazione. Riprova.';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class PublicNewsDetailPage extends StatelessWidget {
  final PublicNews news;
  final bool isGuest;

  const PublicNewsDetailPage({
    super.key,
    required this.news,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: const Text('News'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _PublicNewsCard(
                  news: news,
                  isGuest: isGuest,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicNewsCard extends StatelessWidget {
  final PublicNews news;
  final bool isGuest;
  final bool expanded;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onModerate;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  const _PublicNewsCard({
    required this.news,
    required this.isGuest,
    this.expanded = false,
    this.onOpen,
    this.onDelete,
    this.onModerate,
    this.onReport,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Text(
      news.content,
      maxLines: expanded ? null : 6,
      overflow: expanded ? null : TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.pureWhite.withValues(alpha: 0.78),
        fontSize: 12,
        height: 1.45,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.skyBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brandNightBlue,
                child: Text(
                  _initials(news.author.fullName),
                  style: const TextStyle(
                    color: AppColors.skyBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.author.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      news.author.roleLabel,
                      style: const TextStyle(
                        color: AppColors.materialSky,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(news.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest &&
                  (onDelete != null ||
                      onModerate != null ||
                      onReport != null ||
                      onBlock != null))
                PopupMenuButton<String>(
                  tooltip: 'Azioni',
                  color: AppColors.eleganceDeepNavy,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white54,
                  ),
                  onSelected: (String value) {
                    if (value == 'delete') {
                      onDelete?.call();
                    } else if (value == 'moderate') {
                      onModerate?.call();
                    } else if (value == 'report') {
                      onReport?.call();
                    } else if (value == 'block') {
                      onBlock?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    if (onReport != null)
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Segnala'),
                      ),
                    if (onBlock != null)
                      const PopupMenuItem(
                        value: 'block',
                        child: Text('Blocca autore'),
                      ),
                    if (onModerate != null)
                      const PopupMenuItem(
                        value: 'moderate',
                        child: Text('Rimuovi come moderatore'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Elimina',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            news.academicContext,
            maxLines: expanded ? null : 2,
            overflow: expanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.materialSky,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            news.title,
            maxLines: expanded ? null : 2,
            overflow: expanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          content,
          if (!expanded && news.needsDedicatedPage && onOpen != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
              ),
              label: const Text('Apri news'),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String value) => value.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatDate(DateTime value) {
    final DateTime date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PublicNewsReportSheet extends StatefulWidget {
  const _PublicNewsReportSheet();

  @override
  State<_PublicNewsReportSheet> createState() =>
      _PublicNewsReportSheetState();
}

class _PublicNewsReportSheetState extends State<_PublicNewsReportSheet> {
  final TextEditingController _controller = TextEditingController();
  String _reason = 'spam';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Segnala news',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                dropdownColor: AppColors.eleganceDeepNavy,
                items: const [
                  DropdownMenuItem(value: 'spam', child: Text('Spam')),
                  DropdownMenuItem(
                    value: 'harassment',
                    child: Text('Molestie o comportamento offensivo'),
                  ),
                  DropdownMenuItem(
                    value: 'hate',
                    child: Text('Contenuto discriminatorio'),
                  ),
                  DropdownMenuItem(
                    value: 'privacy',
                    child: Text('Violazione della privacy'),
                  ),
                  DropdownMenuItem(
                    value: 'illegal_content',
                    child: Text('Contenuto illecito'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Altro')),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _reason = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                style: const TextStyle(color: AppColors.pureWhite),
                decoration: const InputDecoration(
                  labelText: 'Dettagli facoltativi',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _ReportDraft(
                      reason: _reason,
                      description: _controller.text.trim(),
                    ),
                  );
                },
                child: const Text('Invia segnalazione'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDraft {
  final String reason;
  final String description;

  const _ReportDraft({
    required this.reason,
    required this.description,
  });
}
