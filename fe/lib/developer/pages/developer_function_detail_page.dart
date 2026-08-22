import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../data/developer_api_repository.dart';
import '../models/developer_models.dart';
import '../theme/developer_ui_style.dart';

class DeveloperFunctionDetailPage
    extends StatefulWidget {
  final DeveloperFileDoc file;
  final DeveloperFunctionDoc function;

  const DeveloperFunctionDetailPage({
    super.key,
    required this.file,
    required this.function,
  });

  @override
  State<DeveloperFunctionDetailPage> createState() =>
      _DeveloperFunctionDetailPageState();
}

class _DeveloperFunctionDetailPageState
    extends State<DeveloperFunctionDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_FunctionTabData> _tabs = [
    _FunctionTabData(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
    ),
    _FunctionTabData(
      label: 'Calls',
      icon: Icons.call_made_rounded,
    ),
    _FunctionTabData(
      label: 'Called By',
      icon: Icons.call_received_rounded,
    ),
    _FunctionTabData(
      label: 'Security',
      icon: Icons.shield_outlined,
    ),
    _FunctionTabData(
      label: 'Flow',
      icon: Icons.account_tree_outlined,
    ),
    _FunctionTabData(
      label: 'Impact',
      icon: Icons.warning_amber_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeveloperFunctionDoc function =
        widget.function;

    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        title: Text(
          '${function.name}()',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth:
                  DeveloperUiStyle.maxContentWidth,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    12,
                  ),
                  child: _buildHeader(),
                ),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(
                        file: widget.file,
                        function: function,
                      ),
                      _CallsTab(
                        function: function,
                      ),
                      _CalledByTab(
                        function: function,
                      ),
                      _SecurityTab(
                        file: widget.file,
                        function: function,
                      ),
                      _FlowTab(
                        function: function,
                      ),
                      _ImpactTab(
                        file: widget.file,
                        function: function,
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

  Widget _buildHeader() {
    final DeveloperFunctionDoc function =
        widget.function;

    final Color riskColor =
        DeveloperUiStyle.riskColor(
      function.risk.name,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration:
          DeveloperUiStyle.elevatedPanelDecoration(
        borderColor: riskColor,
        radius: 18,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.brandNightBlue,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.functions,
              color: riskColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${function.name}()',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.file.path,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      DeveloperUiStyle.bodyMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  function.signature,
                  maxLines: 4,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.pureWhite
                        .withValues(alpha: 0.72),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _InfoBadge(
                      icon: Icons
                          .warning_amber_rounded,
                      label:
                          function.risk.name
                              .toUpperCase(),
                      color: riskColor,
                    ),
                    if (function.isAsync)
                      const _InfoBadge(
                        icon:
                            Icons.sync_rounded,
                        label: 'ASYNC',
                        color:
                            AppColors.materialSky,
                      ),
                    if (function.lineStart != null)
                      _InfoBadge(
                        icon:
                            Icons.numbers_rounded,
                        label:
                            'L${function.lineStart}'
                            '${function.lineEnd != null ? '–${function.lineEnd}' : ''}',
                      ),
                    if (function.security
                        .isNotEmpty)
                      const _InfoBadge(
                        icon: Icons
                            .lock_outline_rounded,
                        label: 'SECURITY',
                        color:
                            Colors.redAccent,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration:
          DeveloperUiStyle.panelDecoration(
        radius: 14,
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize:
            TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.skyBlue
              .withValues(alpha: 0.14),
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color: AppColors.skyBlue
                .withValues(alpha: 0.20),
          ),
        ),
        labelColor: AppColors.pureWhite,
        unselectedLabelColor:
            AppColors.pureWhite
                .withValues(alpha: 0.42),
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        tabs: _tabs
            .map(
              (_FunctionTabData tab) =>
                  Tab(
                icon: Icon(
                  tab.icon,
                  size: 16,
                ),
                text: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final DeveloperFileDoc file;
  final DeveloperFunctionDoc function;

  const _OverviewTab({
    required this.file,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    return _TabScroll(
      children: [
        _DetailSection(
          icon: Icons.info_outline_rounded,
          title: 'Responsabilità',
          accent: AppColors.skyBlue,
          child: Text(
            function.description.isEmpty
                ? 'Descrizione semantica non ancora '
                    'disponibile per questa funzione.'
                : function.description,
            style: DeveloperUiStyle.bodyMuted,
          ),
        ),
        _DetailSection(
          icon: Icons.input_rounded,
          title: 'Input',
          accent: AppColors.materialSky,
          child: function.inputs.isEmpty
              ? const _EmptyInline(
                  message:
                      'Nessun input indicizzato.',
                )
              : Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: function.inputs
                      .map(
                        (String value) =>
                            _InfoBadge(
                          icon:
                              Icons.login_rounded,
                          label: value,
                        ),
                      )
                      .toList(),
                ),
        ),
        _DetailSection(
          icon: Icons.output_rounded,
          title: 'Output',
          accent: AppColors.socialSky,
          child: function.outputs.isEmpty
              ? const _EmptyInline(
                  message:
                      'Nessun output indicizzato.',
                )
              : Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: function.outputs
                      .map(
                        (String value) =>
                            _InfoBadge(
                          icon:
                              Icons.logout_rounded,
                          label: value,
                          color:
                              AppColors.socialSky,
                        ),
                      )
                      .toList(),
                ),
        ),
        _DetailSection(
          icon: Icons.analytics_outlined,
          title: 'Metadata',
          accent: AppColors.lavenderBlue,
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _InfoBadge(
                icon: Icons
                    .description_outlined,
                label: file.name,
              ),
              _InfoBadge(
                icon: Icons.layers_outlined,
                label: file.layer,
              ),
              _InfoBadge(
                icon: Icons.folder_outlined,
                label: file.module,
              ),
              if (function.lineStart != null)
                _InfoBadge(
                  icon: Icons.numbers_rounded,
                  label:
                      'Line ${function.lineStart}'
                      '${function.lineEnd != null ? '–${function.lineEnd}' : ''}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CallsTab extends StatelessWidget {
  final DeveloperFunctionDoc function;

  const _CallsTab({
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    if (function.calls.isEmpty) {
      return const _EmptyTab(
        icon: Icons.call_made_rounded,
        title:
            'Nessuna chiamata indicizzata',
        message:
            'L’indicizzatore non ha rilevato funzioni '
            'chiamate direttamente da questo metodo.',
      );
    }

    return _TabScroll(
      children: [
        _DetailSection(
          icon: Icons.call_made_rounded,
          title:
              'Calls (${function.calls.length})',
          accent: AppColors.materialSky,
          child: Column(
            children: function.calls
                .map(
                  (String call) =>
                      _RelationRow(
                    icon:
                        Icons.call_made_rounded,
                    title: call,
                    subtitle:
                        'Chiamata da ${function.name}()',
                    color:
                        AppColors.materialSky,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _CalledByTab extends StatelessWidget {
  final DeveloperFunctionDoc function;

  const _CalledByTab({
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    if (function.calledBy.isEmpty) {
      return const _EmptyTab(
        icon:
            Icons.call_received_rounded,
        title:
            'Nessun chiamante indicizzato',
        message:
            'Non risultano ancora funzioni collegate '
            'che chiamano direttamente questo metodo.',
      );
    }

    return _TabScroll(
      children: [
        _DetailSection(
          icon:
              Icons.call_received_rounded,
          title:
              'Called By (${function.calledBy.length})',
          accent:
              AppColors.lavenderBlue,
          child: Column(
            children: function.calledBy
                .map(
                  (String caller) =>
                      _RelationRow(
                    icon: Icons
                        .call_received_rounded,
                    title: caller,
                    subtitle:
                        'Dipendenza in ingresso',
                    color:
                        AppColors.lavenderBlue,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SecurityTab extends StatelessWidget {
  final DeveloperFileDoc file;
  final DeveloperFunctionDoc function;

  const _SecurityTab({
    required this.file,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    final bool sensitive =
        function.security.isNotEmpty ||
            function.risk ==
                DeveloperRiskLevel.critical ||
            file.securityCritical;

    return _TabScroll(
      children: [
        _DetailSection(
          icon: Icons.shield_outlined,
          title: 'Classificazione',
          accent: sensitive
              ? Colors.redAccent
              : Colors.greenAccent,
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                sensitive
                    ? Icons
                        .lock_outline_rounded
                    : Icons
                        .verified_user_outlined,
                color: sensitive
                    ? Colors.redAccent
                    : Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  sensitive
                      ? 'Questa funzione è coinvolta in '
                          'logica potenzialmente sensibile.'
                      : 'Nessun indicatore di sicurezza '
                          'specifico rilevato.',
                  style:
                      DeveloperUiStyle.bodyMuted,
                ),
              ),
            ],
          ),
        ),
        if (function.security.isNotEmpty)
          _DetailSection(
            icon: Icons
                .security_update_warning_outlined,
            title: 'Security indicators',
            accent: Colors.redAccent,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: function.security
                  .map(
                    (String value) =>
                        _InfoBadge(
                      icon: Icons
                          .lock_outline_rounded,
                      label: value,
                      color:
                          Colors.redAccent,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (file.securityNotes.isNotEmpty)
          _DetailSection(
            icon: Icons.notes_rounded,
            title:
                'File security notes',
            accent:
                Colors.orangeAccent,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: file.securityNotes
                  .map(
                    (String note) =>
                        _BulletText(
                      text: note,
                      color: Colors
                          .orangeAccent,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _FlowTab extends StatelessWidget {
  final DeveloperFunctionDoc function;

  const _FlowTab({
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    if (function.flows.isEmpty) {
      return const _EmptyTab(
        icon: Icons.account_tree_outlined,
        title:
            'Nessun flow associato',
        message:
            'Questa funzione non è ancora collegata '
            'a un flow applicativo esplicito.',
      );
    }

    return _TabScroll(
      children: [
        _DetailSection(
          icon:
              Icons.account_tree_outlined,
          title:
              'Part of Flow (${function.flows.length})',
          accent: AppColors.socialSky,
          child: Column(
            children: function.flows
                .map(
                  (String flow) =>
                      _RelationRow(
                    icon:
                        Icons.route_outlined,
                    title: flow,
                    subtitle:
                        'Flow applicativo associato',
                    color:
                        AppColors.socialSky,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ImpactTab extends StatefulWidget {
  final DeveloperFileDoc file;
  final DeveloperFunctionDoc function;

  const _ImpactTab({
    required this.file,
    required this.function,
  });

  @override
  State<_ImpactTab> createState() =>
      _ImpactTabState();
}

class _ImpactTabState
    extends State<_ImpactTab> {
  final DeveloperApiRepository _repository =
      const DeveloperApiRepository();

  late Future<DeveloperImpactAnalysis>
      _futureImpact;

  @override
  void initState() {
    super.initState();

    _futureImpact = _load();
  }

  Future<DeveloperImpactAnalysis>
      _load() {
    return _repository.getImpact(
      path: widget.file.path,
      functionName:
          widget.function.name,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _futureImpact = _load();
    });

    await _futureImpact;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        DeveloperImpactAnalysis>(
      future: _futureImpact,
      builder: (
        BuildContext context,
        AsyncSnapshot<
                DeveloperImpactAnalysis>
            snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _ImpactError(
            message:
                snapshot.error.toString(),
            onRetry: _reload,
          );
        }

        final DeveloperImpactAnalysis?
            impact = snapshot.data;

        if (impact == null) {
          return const _EmptyTab(
            icon:
                Icons.warning_amber_rounded,
            title:
                'Impact non disponibile',
            message:
                'Il backend non ha restituito '
                'un’analisi di impatto.',
          );
        }

        final Color riskColor =
            DeveloperUiStyle.riskColor(
          impact.risk.name,
        );

        return _TabScroll(
          children: [
            _DetailSection(
              icon:
                  Icons.speed_outlined,
              title: 'Impact summary',
              accent: riskColor,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    impact.summary,
                    style:
                        DeveloperUiStyle
                            .bodyMuted,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  LayoutBuilder(
                    builder: (
                      BuildContext context,
                      BoxConstraints constraints,
                    ) {
                      final int columns =
                          constraints.maxWidth >=
                                  650
                              ? 4
                              : 2;

                      final List<
                              _ImpactMetricData>
                          metrics = [
                        _ImpactMetricData(
                          label:
                              'Direct callers',
                          value:
                              '${impact.directCallers.length}',
                          icon: Icons
                              .call_received_rounded,
                        ),
                        _ImpactMetricData(
                          label:
                              'Calls',
                          value:
                              '${impact.directCallees.length}',
                          icon: Icons
                              .call_made_rounded,
                        ),
                        _ImpactMetricData(
                          label:
                              'Flows',
                          value:
                              '${impact.flows.length}',
                          icon: Icons
                              .route_outlined,
                        ),
                        _ImpactMetricData(
                          label:
                              'Files',
                          value:
                              '${impact.relatedFiles.length}',
                          icon: Icons
                              .description_outlined,
                        ),
                      ];

                      return GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount:
                            metrics.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              columns,
                          crossAxisSpacing:
                              8,
                          mainAxisSpacing:
                              8,
                          mainAxisExtent:
                              86,
                        ),
                        itemBuilder: (
                          BuildContext context,
                          int index,
                        ) {
                          return _ImpactMetric(
                            data:
                                metrics[index],
                            color:
                                riskColor,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            _DetailSection(
              icon: Icons
                  .warning_amber_rounded,
              title: 'Risk',
              accent: riskColor,
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _InfoBadge(
                    icon: Icons
                        .warning_amber_rounded,
                    label: impact.risk.name
                        .toUpperCase(),
                    color: riskColor,
                  ),
                  if (impact.securityCritical)
                    const _InfoBadge(
                      icon: Icons
                          .lock_outline_rounded,
                      label:
                          'SECURITY CRITICAL',
                      color:
                          Colors.redAccent,
                    ),
                ],
              ),
            ),
            if (impact.flows.isNotEmpty)
              _DetailSection(
                icon:
                    Icons.route_outlined,
                title: 'Affected flows',
                accent:
                    AppColors.socialSky,
                child: Column(
                  children: impact.flows
                      .map(
                        (
                          DeveloperImpactFlow
                              flow,
                        ) =>
                            _RelationRow(
                          icon: Icons
                              .account_tree_outlined,
                          title:
                              flow.name,
                          subtitle:
                              '${flow.risk.name.toUpperCase()} · '
                              'step ${flow.matchedSteps.join(', ')}',
                          color:
                              DeveloperUiStyle
                                  .riskColor(
                            flow.risk.name,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (impact
                .directCallers.isNotEmpty)
              _DetailSection(
                icon: Icons
                    .call_received_rounded,
                title: 'Direct callers',
                accent:
                    AppColors.lavenderBlue,
                child: Column(
                  children: impact
                      .directCallers
                      .map(
                        (
                          DeveloperImpactFunctionRef
                              item,
                        ) =>
                            _RelationRow(
                          icon: Icons
                              .call_received_rounded,
                          title:
                              '${item.function}()',
                          subtitle:
                              item.file,
                          color:
                              DeveloperUiStyle
                                  .riskColor(
                            item.risk.name,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (impact
                .directCallees.isNotEmpty)
              _DetailSection(
                icon:
                    Icons.call_made_rounded,
                title:
                    'Outgoing dependencies',
                accent:
                    AppColors.materialSky,
                child: Column(
                  children: impact
                      .directCallees
                      .map(
                        (
                          DeveloperImpactFunctionRef
                              item,
                        ) =>
                            _RelationRow(
                          icon: Icons
                              .call_made_rounded,
                          title:
                              '${item.function}()',
                          subtitle:
                              item.file,
                          color:
                              DeveloperUiStyle
                                  .riskColor(
                            item.risk.name,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (impact
                .transitiveCallers
                .isNotEmpty)
              _DetailSection(
                icon: Icons
                    .hub_outlined,
                title:
                    'Transitive callers',
                accent:
                    AppColors.skyBlue,
                child: Column(
                  children: impact
                      .transitiveCallers
                      .map(
                        (
                          DeveloperImpactFunctionRef
                              item,
                        ) =>
                            _RelationRow(
                          icon:
                              Icons.hub_outlined,
                          title:
                              '${item.function}()',
                          subtitle:
                              '${item.file}'
                              '${item.depth != null ? ' · depth ${item.depth}' : ''}',
                          color:
                              DeveloperUiStyle
                                  .riskColor(
                            item.risk.name,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (impact
                .relatedFiles.isNotEmpty)
              _DetailSection(
                icon: Icons
                    .description_outlined,
                title: 'Related files',
                accent:
                    AppColors.materialSky,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: impact
                      .relatedFiles
                      .map(
                        (String path) =>
                            _InfoBadge(
                          icon: Icons
                              .description_outlined,
                          label: path,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (impact
                .securityFlags.isNotEmpty)
              _DetailSection(
                icon:
                    Icons.shield_outlined,
                title:
                    'Security exposure',
                accent:
                    Colors.redAccent,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: impact
                      .securityFlags
                      .map(
                        (String flag) =>
                            _InfoBadge(
                          icon: Icons
                              .lock_outline_rounded,
                          label: flag,
                          color:
                              Colors.redAccent,
                        ),
                      )
                      .toList(),
                ),
              ),
            Center(
              child: TextButton.icon(
                onPressed: _reload,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Ricalcola impact',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImpactError extends StatelessWidget {
  final String message;
  final Future<void> Function()
      onRetry;

  const _ImpactError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 520,
          ),
          padding:
              const EdgeInsets.all(20),
          decoration:
              DeveloperUiStyle.panelDecoration(
            borderColor:
                Colors.redAccent,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Colors.redAccent,
                size: 38,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Impact analysis non disponibile',
                style:
                    DeveloperUiStyle
                        .bodyStrong,
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    DeveloperUiStyle
                        .bodyMuted,
              ),
              const SizedBox(
                height: 14,
              ),
              FilledButton.icon(
                onPressed: () {
                  onRetry();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label:
                    const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabScroll extends StatelessWidget {
  final List<Widget> children;

  const _TabScroll({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: children,
    );
  }
}

class _DetailSection
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(16),
      decoration:
          DeveloperUiStyle.panelDecoration(
        borderColor: accent,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      AppColors.brandNightBlue,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style:
                      DeveloperUiStyle.bodyStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.color = AppColors.materialSky,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _RelationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  AppColors.brandNightBlue,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      DeveloperUiStyle.bodyStrong,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style:
                      DeveloperUiStyle.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletText({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 5,
              color: color,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style:
                  DeveloperUiStyle.bodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetricData {
  final String label;
  final String value;
  final IconData icon;

  const _ImpactMetricData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _ImpactMetric
    extends StatelessWidget {
  final _ImpactMetricData data;
  final Color color;

  const _ImpactMetric({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            color: color,
            size: 16,
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            data.label,
            style: TextStyle(
              color: AppColors.pureWhite
                  .withValues(alpha: 0.38),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline
    extends StatelessWidget {
  final String message;

  const _EmptyInline({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style:
          DeveloperUiStyle.bodyMuted,
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints:
              const BoxConstraints(
            maxWidth: 520,
          ),
          padding:
              const EdgeInsets.all(24),
          decoration:
              DeveloperUiStyle.panelDecoration(),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white24,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style:
                    DeveloperUiStyle.bodyStrong,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    DeveloperUiStyle.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FunctionTabData {
  final String label;
  final IconData icon;

  const _FunctionTabData({
    required this.label,
    required this.icon,
  });
}