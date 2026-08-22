import 'package:flutter/material.dart';

enum DeveloperNodeType { folder, file }

enum DeveloperRelationType {
  calls,
  calledBy,
  usesModel,
  usesConfig,
  frontend,
  flow,
  security,
  endpoint,
  imports,
  contains,
  unknown,
}

enum DeveloperSourceType {
  local,
  remote,
  synced,
}

enum DeveloperRiskLevel {
  low,
  medium,
  high,
  critical,
}

class DeveloperBadge {
  final String label;
  final IconData icon;
  final Color color;

  const DeveloperBadge(
    this.label,
    this.icon,
    this.color,
  );
}

class DeveloperAccessResult {
  final bool authorized;
  final String? role;

  const DeveloperAccessResult({
    required this.authorized,
    this.role,
  });
}

class DeveloperRepositoryStatus {
  final String repositoryName;
  final String repositoryRoot;
  final DeveloperSourceType sourceType;
  final bool gitAvailable;
  final String? branch;
  final String? headCommit;
  final int filesIndexed;
  final int functionsIndexed;
  final int documentedFiles;
  final int outdatedFiles;
  final int changedFiles;
  final int securityCriticalFiles;

  const DeveloperRepositoryStatus({
    required this.repositoryName,
    required this.repositoryRoot,
    required this.sourceType,
    required this.gitAvailable,
    required this.branch,
    required this.headCommit,
    required this.filesIndexed,
    required this.functionsIndexed,
    required this.documentedFiles,
    required this.outdatedFiles,
    required this.changedFiles,
    required this.securityCriticalFiles,
  });
}

class DeveloperTreeNode {
  final String id;
  final String name;
  final String path;
  final DeveloperNodeType type;
  final List<DeveloperTreeNode> children;
  final bool documented;
  final bool outdated;
  final bool changed;
  final bool securityCritical;
  final int? functionCount;

  const DeveloperTreeNode({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.children = const [],
    this.documented = false,
    this.outdated = false,
    this.changed = false,
    this.securityCritical = false,
    this.functionCount,
  });
}

class DeveloperFunctionDoc {
  final String id;
  final String name;
  final String signature;
  final String description;
  final int? lineStart;
  final int? lineEnd;
  final bool isAsync;
  final List<String> calls;
  final List<String> calledBy;
  final List<String> flows;
  final List<String> security;
  final List<String> inputs;
  final List<String> outputs;
  final DeveloperRiskLevel risk;

  const DeveloperFunctionDoc({
    required this.id,
    required this.name,
    required this.signature,
    required this.description,
    this.lineStart,
    this.lineEnd,
    this.isAsync = false,
    this.calls = const [],
    this.calledBy = const [],
    this.flows = const [],
    this.security = const [],
    this.inputs = const [],
    this.outputs = const [],
    this.risk = DeveloperRiskLevel.medium,
  });
}

class DeveloperRelation {
  final DeveloperRelationType type;
  final String label;
  final String targetPath;
  final String? targetFunction;

  const DeveloperRelation({
    required this.type,
    required this.label,
    required this.targetPath,
    this.targetFunction,
  });
}

class DeveloperFileDoc {
  final String id;
  final String path;
  final String name;
  final String extension;
  final String language;
  final String layer;
  final String module;
  final String description;
  final String importance;
  final DeveloperRiskLevel risk;
  final DeveloperSourceType sourceType;
  final bool documented;
  final bool outdated;
  final bool changed;
  final bool securityCritical;
  final int sizeBytes;
  final double? modifiedAt;
  final String contentHash;
  final List<DeveloperBadge> badges;
  final List<DeveloperFunctionDoc> functions;
  final List<String> imports;
  final List<DeveloperRelation> relations;
  final List<String> flows;
  final List<String> securityNotes;

  const DeveloperFileDoc({
    required this.id,
    required this.path,
    required this.name,
    required this.extension,
    required this.language,
    required this.layer,
    required this.module,
    required this.description,
    required this.importance,
    required this.risk,
    required this.sourceType,
    required this.documented,
    required this.outdated,
    required this.changed,
    required this.securityCritical,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.contentHash,
    this.badges = const [],
    this.functions = const [],
    this.imports = const [],
    this.relations = const [],
    this.flows = const [],
    this.securityNotes = const [],
  });
}

class DeveloperSearchResult {
  final String kind;
  final String title;
  final String subtitle;
  final String path;
  final String? functionName;
  final double score;
  final List<String> reasons;

  const DeveloperSearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.path,
    this.functionName,
    required this.score,
    this.reasons = const [],
  });
}

class DeveloperFlowDoc {
  final String id;
  final String name;
  final String description;
  final DeveloperRiskLevel risk;
  final List<DeveloperFlowStep> steps;

  const DeveloperFlowDoc({
    required this.id,
    required this.name,
    required this.description,
    required this.risk,
    required this.steps,
  });
}

class DeveloperFlowStep {
  final int order;
  final String title;
  final String file;
  final String? function;
  final String layer;
  final String relation;
  final String context;
  final bool securityCritical;

  const DeveloperFlowStep({
    required this.order,
    required this.title,
    required this.file,
    this.function,
    required this.layer,
    this.relation = 'NEXT',
    this.context = '',
    this.securityCritical = false,
  });
}

class DeveloperGraphNode {
  final String id;
  final String label;
  final String path;
  final String? functionName;
  final String kind;
  final String? layer;
  final bool securityCritical;

  const DeveloperGraphNode({
    required this.id,
    required this.label,
    required this.path,
    required this.functionName,
    required this.kind,
    required this.layer,
    required this.securityCritical,
  });
}

class DeveloperGraphEdge {
  final String id;
  final String source;
  final String target;
  final String type;
  final String label;

  const DeveloperGraphEdge({
    required this.id,
    required this.source,
    required this.target,
    required this.type,
    required this.label,
  });
}

class DeveloperGraphData {
  final List<DeveloperGraphNode> nodes;
  final List<DeveloperGraphEdge> edges;

  const DeveloperGraphData({
    required this.nodes,
    required this.edges,
  });
}

class DeveloperImpactFunctionRef {
  final String file;
  final String function;
  final String layer;
  final bool securityCritical;
  final DeveloperRiskLevel risk;
  final int? depth;

  const DeveloperImpactFunctionRef({
    required this.file,
    required this.function,
    required this.layer,
    required this.securityCritical,
    required this.risk,
    this.depth,
  });
}

class DeveloperImpactFlow {
  final String id;
  final String name;
  final DeveloperRiskLevel risk;
  final List<int> matchedSteps;

  const DeveloperImpactFlow({
    required this.id,
    required this.name,
    required this.risk,
    required this.matchedSteps,
  });
}

class DeveloperImpactAnalysis {
  final String path;
  final String? function;
  final DeveloperRiskLevel risk;
  final String summary;
  final List<DeveloperImpactFunctionRef>
      directCallers;
  final List<DeveloperImpactFunctionRef>
      directCallees;
  final List<DeveloperImpactFunctionRef>
      transitiveCallers;
  final List<String> relatedFiles;
  final List<DeveloperImpactFlow> flows;
  final List<String> securityFlags;
  final bool securityCritical;

  const DeveloperImpactAnalysis({
    required this.path,
    required this.function,
    required this.risk,
    required this.summary,
    required this.directCallers,
    required this.directCallees,
    required this.transitiveCallers,
    required this.relatedFiles,
    required this.flows,
    required this.securityFlags,
    required this.securityCritical,
  });
}
