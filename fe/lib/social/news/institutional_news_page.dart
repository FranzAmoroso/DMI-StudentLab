import 'package:flutter/material.dart';

import '../../services/auth_session.dart';
import '../../theme/nightTheme.dart';
import '../social_models.dart';
import 'models/public_news.dart';

class InstitutionalNewsPage extends StatefulWidget {
  final bool embedded;
  final List<PublicNews> initialItems;

  const InstitutionalNewsPage({
    super.key,
    this.embedded = false,
    this.initialItems = const [],
  });

  @override
  State<InstitutionalNewsPage> createState() =>
      _InstitutionalNewsPageState();
}

class _InstitutionalNewsPageState extends State<InstitutionalNewsPage> {
  final AuthSession _session = AuthSession.instance;
  final TextEditingController _searchController = TextEditingController();

  late List<PublicNews> _items;

  String _university = '';
  String _department = '';
  String _course = '';
  int? _subjectId;
  String _subjectName = '';

  bool _academicFilterEnabled = false;

  SocialUser? get _currentUser => _session.currentUser;

  bool get _isGuest => _session.isGuest;

  bool get _canPublish {
    final SocialUser? user = _currentUser;

    if (user == null) {
      return false;
    }

    return user.type == SocialUserType.teacher &&
        user.isVerifiedTeacher;
  }

  @override
  void initState() {
    super.initState();
    _items = List<PublicNews>.from(widget.initialItems);
    _applyDefaultAcademicContext();
    _session.addListener(_onSessionChanged);
  }

  @override
  void didUpdateWidget(covariant InstitutionalNewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.initialItems, widget.initialItems)) {
      _items = List<PublicNews>.from(widget.initialItems);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(_applyDefaultAcademicContext);
  }

  void _applyDefaultAcademicContext() {
    final SocialUser? user = _currentUser;

    if (user == null) {
      _academicFilterEnabled = false;
      _university = '';
      _department = '';
      _course = '';
      _subjectId = null;
      _subjectName = '';
      return;
    }

    final SocialAcademicPath? path = _preferredPath(user);

    _university = path?.university.trim().isNotEmpty == true
        ? path!.university.trim()
        : user.university.trim();

    _department = path?.department.trim().isNotEmpty == true
        ? path!.department.trim()
        : user.department.trim();

    _course = path?.course.trim().isNotEmpty == true
        ? path!.course.trim()
        : user.course.trim();

    _subjectId = null;
    _subjectName = '';
    _academicFilterEnabled =
        _university.isNotEmpty || _department.isNotEmpty || _course.isNotEmpty;
  }

  SocialAcademicPath? _preferredPath(SocialUser user) {
    for (final SocialAcademicPath path in user.academicPaths) {
      if (path.isCurrent) {
        return path;
      }
    }

    for (final SocialAcademicPath path in user.academicPaths) {
      if (path.isPrimary) {
        return path;
      }
    }

    return user.academicPaths.isEmpty ? null : user.academicPaths.first;
  }

  List<SocialSubject> get _availableSubjects {
    final SocialUser? user = _currentUser;

    if (user == null) {
      return const [];
    }

    final Map<int, SocialSubject> values = {};

    for (final SocialSubject subject in user.subjects) {
      if (subject.id > 0) {
        values[subject.id] = subject;
      }
    }

    for (final TeacherAssignment assignment in user.teacherAssignments) {
      if (assignment.subject.id > 0) {
        values[assignment.subject.id] = assignment.subject;
      }
    }

    final List<SocialSubject> result = values.values.toList()
      ..sort(
        (SocialSubject a, SocialSubject b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    return result;
  }

  List<PublicNews> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();

    final List<PublicNews> result = _items.where((PublicNews news) {
      if (news.isExpired) {
        return false;
      }

      if (_academicFilterEnabled) {
        if (_university.isNotEmpty &&
            !_same(news.university, _university)) {
          return false;
        }

        if (_department.isNotEmpty &&
            !_same(news.department, _department)) {
          return false;
        }

        if (_course.isNotEmpty && !_same(news.course, _course)) {
          return false;
        }

        if (_subjectId != null && news.subjectId != _subjectId) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchable = [
        news.author.fullName,
        news.author.roleLabel,
        news.title,
        news.content,
        news.city,
        news.university,
        news.department,
        news.course,
        news.subjectName,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();

    result.sort(
      (PublicNews a, PublicNews b) => b.createdAt.compareTo(a.createdAt),
    );

    return result;
  }

  bool _same(String first, String second) {
    return first.trim().toLowerCase() == second.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchAndFilters(),
                const SizedBox(height: 16),
                _buildActiveFilterSummary(),
                const SizedBox(height: 16),
                _buildFeed(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.darkElegance,
        appBar: _buildAppBar(),
        body: content,
        floatingActionButton: _canPublish ? _buildPublishButton() : null,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: _buildAppBar(),
      body: content,
      floatingActionButton: _canPublish ? _buildPublishButton() : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.brandNightBlue,
      foregroundColor: AppColors.pureWhite,
      elevation: 0,
      title: const Text('News'),
      actions: [
        if (!_isGuest)
          IconButton(
            tooltip: 'Comunicazioni private',
            onPressed: _openPrivateInfo,
            icon: const Icon(Icons.lock_outline_rounded),
          ),
        IconButton(
          tooltip: 'Aggiorna',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.teacherIndigo.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.teacherIndigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppColors.teacherIndigo,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'News StudentLab',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isGuest
                      ? 'Consulta le comunicazioni pubbliche della community. Puoi filtrare per contesto accademico senza accedere.'
                      : 'Comunicazioni pubbliche dei docenti verificati e, quando il backend pubblico sarà collegato, degli amministratori e del Creator.',
                  style: TextStyle(
                    color: AppColors.pureWhite.withValues(alpha: 0.50),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: InputDecoration(
            hintText: 'Cerca autore, materia, corso, contenuto...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.skyBlue,
            ),
            suffixIcon: IconButton(
              tooltip: 'Filtri',
              onPressed: _openFilters,
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.materialSky,
              ),
            ),
            filled: true,
            fillColor: AppColors.eleganceMidnight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FilterModeButton(
                selected: _academicFilterEnabled,
                icon: Icons.school_outlined,
                label: 'Il mio percorso',
                onTap: () {
                  if (_currentUser == null) {
                    _showMessage(
                      'Accedi per usare automaticamente il tuo percorso accademico.',
                    );
                    return;
                  }

                  setState(() {
                    _applyDefaultAcademicContext();
                    _academicFilterEnabled = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _FilterModeButton(
                selected: !_academicFilterEnabled,
                icon: Icons.public_rounded,
                label: 'Tutte',
                onTap: () {
                  setState(() {
                    _academicFilterEnabled = false;
                    _subjectId = null;
                    _subjectName = '';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFilterSummary() {
    final List<String> values = [];

    if (_academicFilterEnabled) {
      if (_university.isNotEmpty) {
        values.add(_university);
      }

      if (_department.isNotEmpty) {
        values.add(_department);
      }

      if (_course.isNotEmpty) {
        values.add(_course);
      }

      if (_subjectName.isNotEmpty) {
        values.add(_subjectName);
      }
    }

    return Row(
      children: [
        const Icon(
          Icons.filter_alt_outlined,
          color: AppColors.materialSky,
          size: 16,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            values.isEmpty ? 'Tutte le news pubbliche' : values.join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.pureWhite.withValues(alpha: 0.52),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ),
        Text(
          '${_filteredItems.length}',
          style: const TextStyle(
            color: AppColors.materialSky,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeed() {
    final List<PublicNews> items = _filteredItems;

    if (_items.isEmpty) {
      return _buildBackendPendingState();
    }

    if (items.isEmpty) {
      return _buildEmptyFilteredState();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 760 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 285,
          ),
          itemBuilder: (BuildContext context, int index) {
            final PublicNews news = items[index];

            return _PublicNewsCard(
              news: news,
              isGuest: _isGuest,
              onOpen: () => _openNews(news),
            );
          },
        );
      },
    );
  }

  Widget _buildBackendPendingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.skyBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.newspaper_outlined,
            color: AppColors.skyBlue,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nessuna news pubblica disponibile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La sezione è ora collegata alla navigazione principale. Il feed pubblico non usa le news dei gruppi e verrà popolato quando aggiungeremo gli endpoint PublicNews dedicati nel backend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.pureWhite.withValues(alpha: 0.48),
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_outlined,
            color: Colors.white30,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'Nessuna news con questi filtri',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Modifica il percorso, la materia o la ricerca.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.pureWhite.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return FloatingActionButton.extended(
      onPressed: _showPublishingPending,
      backgroundColor: AppColors.socialBlue,
      foregroundColor: AppColors.pureWhite,
      icon: const Icon(Icons.edit_note_rounded),
      label: const Text('Pubblica'),
    );
  }

  Future<void> _openFilters() async {
    String university = _university;
    String department = _department;
    String course = _course;
    int? subjectId = _subjectId;
    String subjectName = _subjectName;
    bool enabled = _academicFilterEnabled;

    final bool? apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.eleganceDeepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
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
                18 + MediaQuery.of(context).viewInsets.bottom,
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
                        'Filtra per percorso accademico',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (bool value) {
                        setSheetState(() {
                          enabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: university,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(
                        labelText: 'Ateneo',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      onChanged: (String value) {
                        university = value.trim();
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: department,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(
                        labelText: 'Dipartimento',
                        prefixIcon: Icon(Icons.domain_outlined),
                      ),
                      onChanged: (String value) {
                        department = value.trim();
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: course,
                      enabled: enabled,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(
                        labelText: 'Corso',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      onChanged: (String value) {
                        course = value.trim();
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      initialValue: subjectId,
                      isExpanded: true,
                      dropdownColor: AppColors.eleganceDeepNavy,
                      decoration: const InputDecoration(
                        labelText: 'Materia',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'Tutte le materie',
                            style: TextStyle(color: AppColors.pureWhite),
                          ),
                        ),
                        ..._availableSubjects.map(
                          (SocialSubject subject) => DropdownMenuItem<int?>(
                            value: subject.id,
                            child: Text(
                              subject.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: enabled
                          ? (int? value) {
                              setSheetState(() {
                                subjectId = value;
                                subjectName = value == null
                                    ? ''
                                    : _availableSubjects
                                        .firstWhere(
                                          (SocialSubject subject) =>
                                              subject.id == value,
                                        )
                                        .name;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                enabled = false;
                                university = '';
                                department = '';
                                course = '';
                                subjectId = null;
                                subjectName = '';
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
      _academicFilterEnabled = enabled;
      _university = university;
      _department = department;
      _course = course;
      _subjectId = subjectId;
      _subjectName = subjectName;
    });
  }

  Future<void> _openNews(PublicNews news) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicNewsDetailPage(
          news: news,
          isGuest: _isGuest,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _showPublishingPending() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text(
            'Pubblicazione news',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          content: Text(
            'Il frontend è predisposto. La pubblicazione nel feed principale verrà attivata quando aggiungeremo gli endpoint PublicNews e i permessi per docente verificato, admin e Creator.',
            style: TextStyle(
              color: AppColors.pureWhite.withValues(alpha: 0.64),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  void _openPrivateInfo() {
    _showMessage(
      'Le comunicazioni private restano separate dal feed pubblico e sono accessibili dalle sezioni dedicate.',
    );
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

  const _PublicNewsCard({
    required this.news,
    required this.isGuest,
    this.expanded = false,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(
                        color: AppColors.pureWhite.withValues(alpha: 0.36),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest &&
                  (news.canDelete ||
                      news.canModerate ||
                      news.canReport ||
                      news.canBlockAuthor))
                const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white38,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            news.academicContext,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.materialSky,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          if (news.title.isNotEmpty) ...[
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
          ],
          const SizedBox(height: 10),
          if (expanded)
            Text(
              news.content,
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.76),
                fontSize: 12,
                height: 1.45,
              ),
            )
          else
            Flexible(
              child: Text(
                news.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.76),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          if (!expanded && news.needsDedicatedPage && onOpen != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                ),
                label: const Text('Apri news'),
              ),
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

class _FilterModeButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.skyBlue.withValues(alpha: 0.14)
              : AppColors.eleganceMidnight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.skyBlue.withValues(alpha: 0.30)
                : AppColors.skyBlue.withValues(alpha: 0.09),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.skyBlue : Colors.white38,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selected ? AppColors.pureWhite : Colors.white54,
                  fontSize: 10,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}