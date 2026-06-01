import '../../domain/entities/export_column.dart';

class ExportDataset {
  const ExportDataset({
    required this.columns,
    required this.rows,
    required this.summary,
    this.extraSheets = const <ExportSheet>[],
    this.limitedByCap = false,
    this.recordCountOverride,
  });

  final List<ExportColumn> columns;
  final List<List<String>> rows;
  final Map<String, String> summary;
  final List<ExportSheet> extraSheets;
  final bool limitedByCap;
  final int? recordCountOverride;

  int get recordCount => recordCountOverride ?? rows.length;
}

class ExportSheet {
  const ExportSheet({
    required this.name,
    required this.columns,
    required this.rows,
  });

  final String name;
  final List<ExportColumn> columns;
  final List<List<String>> rows;
}
