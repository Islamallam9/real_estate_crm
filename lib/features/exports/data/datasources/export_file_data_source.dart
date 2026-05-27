import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/export_request.dart';
import '../../domain/entities/export_result.dart';
import '../models/export_dataset.dart';

abstract interface class ExportFileDataSource {
  ExportResult generateFile({
    required ExportRequest request,
    required ExportDataset dataset,
  });
}

class LocalExportFileDataSource implements ExportFileDataSource {
  const LocalExportFileDataSource();

  static const String _excelMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  @override
  ExportResult generateFile({
    required ExportRequest request,
    required ExportDataset dataset,
  }) {
    final generatedAt = DateTime.now();
    final fileName = _fileName(request, generatedAt);
    return ExportResult(
      fileName: fileName,
      bytes: _buildXlsx(request, dataset, generatedAt),
      mimeType: _excelMime,
      generatedAt: generatedAt,
      recordCount: dataset.recordCount,
    );
  }

  Uint8List _buildXlsx(
    ExportRequest request,
    ExportDataset dataset,
    DateTime generatedAt,
  ) {
    final isArabic = request.filters.outputLanguage == ExportOutputLanguage.ar;
    final generatedAtLabel = DateFormat('yyyy-MM-dd HH:mm').format(generatedAt.toLocal());
    final moduleLabel = _moduleLabel(request);
    final scopeLabel = _scopeLabel(request);
    final dateRangeLabel = _dateRangeLabel(request);
    final filtersLabel = _filtersSummary(request);

    final sheets = <_XlsxSheet>[
      _XlsxSheet(
        name: _label(request, 'reportSummary'),
        rows: [
          ['Masar CRM'],
          [moduleLabel],
          const <String>[],
          [_label(request, 'field'), _label(request, 'value'), _label(request, 'field'), _label(request, 'value')],
          [_label(request, 'company'), request.actor.companyName, _label(request, 'reportName'), moduleLabel],
          [_label(request, 'scope'), scopeLabel, _label(request, 'dateRange'), dateRangeLabel],
          [_label(request, 'generatedBy'), request.actor.name, _label(request, 'generatedAt'), generatedAtLabel],
          [_label(request, 'recordCount'), dataset.recordCount.toString(), _label(request, 'filtersSummary'), filtersLabel],
          const <String>[],
          [_label(request, 'reportSummary')],
          for (final entry in dataset.summary.entries) [entry.key, entry.value],
        ],
        rightToLeft: isArabic,
        titleRows: const {0},
        subtitleRows: const {1},
        headerRows: const {3, 9},
        mergeTitleRows: true,
      ),
      _XlsxSheet(
        name: _label(request, 'dataSheet'),
        rows: [
          ['Masar CRM - $moduleLabel'],
          [
            '${_label(request, 'company')}: ${request.actor.companyName}  ·  '
                '${_label(request, 'scope')}: $scopeLabel  ·  '
                '${_label(request, 'dateRange')}: $dateRangeLabel',
          ],
          const <String>[],
          dataset.columns.map((column) => column.label).toList(),
          ...dataset.rows,
        ],
        rightToLeft: isArabic,
        titleRows: const {0},
        subtitleRows: const {1},
        headerRows: const {3},
        dataStartRow: 4,
        freezeRows: 4,
        autoFilterRow: 3,
        mergeTitleRows: true,
      ),
      for (final sheet in dataset.extraSheets)
        _XlsxSheet(
          name: sheet.name,
          rows: [
            ['Masar CRM - ${sheet.name}'],
            [
              '${_label(request, 'company')}: ${request.actor.companyName}  ·  '
                  '${_label(request, 'scope')}: $scopeLabel',
            ],
            const <String>[],
            sheet.columns.map((column) => column.label).toList(),
            ...sheet.rows,
          ],
          rightToLeft: isArabic,
          titleRows: const {0},
          subtitleRows: const {1},
          headerRows: const {3},
          dataStartRow: 4,
          freezeRows: 4,
          autoFilterRow: 3,
          mergeTitleRows: true,
        ),
    ];

    final archive = Archive();
    archive.addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes(sheets.length)));
    archive.addFile(ArchiveFile.string('_rels/.rels', _rootRels()));
    archive.addFile(ArchiveFile.string('xl/workbook.xml', _workbook(sheets)));
    archive.addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels(sheets.length)));
    archive.addFile(ArchiveFile.string('xl/styles.xml', _styles()));
    for (var index = 0; index < sheets.length; index++) {
      archive.addFile(
        ArchiveFile.string(
          'xl/worksheets/sheet${index + 1}.xml',
          _worksheet(sheets[index]),
        ),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  String _contentTypes(int sheetCount) {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  ${List.generate(sheetCount, (index) => '<Override PartName="/xl/worksheets/sheet${index + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>').join('\n  ')}
</Types>
''';
  }

  String _rootRels() {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
''';
  }

  String _workbook(List<_XlsxSheet> sheets) {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="14000"/></bookViews>
  <sheets>
    ${List.generate(sheets.length, (index) => '<sheet name="${_xml(_safeSheetName(sheets[index].name))}" sheetId="${index + 1}" r:id="rId${index + 1}"/>').join('\n    ')}
  </sheets>
</workbook>
''';
  }

  String _workbookRels(int sheetCount) {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  ${List.generate(sheetCount, (index) => '<Relationship Id="rId${index + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${index + 1}.xml"/>').join('\n  ')}
  <Relationship Id="rId${sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
''';
  }

  String _styles() {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="5">
    <font><sz val="11"/><name val="Arial"/><family val="2"/><color rgb="FF1F2933"/></font>
    <font><b/><sz val="18"/><name val="Arial"/><family val="2"/><color rgb="FF111827"/></font>
    <font><b/><sz val="12"/><name val="Arial"/><family val="2"/><color rgb="FF6B5F4A"/></font>
    <font><b/><sz val="11"/><name val="Arial"/><family val="2"/><color rgb="FF111827"/></font>
    <font><b/><sz val="11"/><name val="Arial"/><family val="2"/><color rgb="FFB87913"/></font>
  </fonts>
  <fills count="7">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFFFF8EA"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFF4BE45"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFFFE6A6"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFF8F1E3"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFFFFFFF"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="2">
    <border><left/><right/><top/><bottom/><diagonal/></border>
    <border>
      <left style="thin"><color rgb="FFE6D8C1"/></left>
      <right style="thin"><color rgb="FFE6D8C1"/></right>
      <top style="thin"><color rgb="FFE6D8C1"/></top>
      <bottom style="thin"><color rgb="FFE6D8C1"/></bottom>
      <diagonal/>
    </border>
  </borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="6" borderId="0" applyFill="1"/></cellStyleXfs>
  <cellXfs count="9">
    <xf numFmtId="0" fontId="0" fillId="6" borderId="0" xfId="0" applyFill="1"><alignment vertical="center"/></xf>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"><alignment vertical="center"/></xf>
    <xf numFmtId="0" fontId="2" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"><alignment vertical="center"/></xf>
    <xf numFmtId="0" fontId="3" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="4" fillId="5" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="0" fillId="6" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="0" fillId="5" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="0" fillId="6" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf>
  </cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0" customBuiltin="0"/></cellStyles>
</styleSheet>
''';
  }

  String _worksheet(_XlsxSheet sheet) {
    final rows = sheet.rows;
    final contentColumnCount = _columnCount(rows).clamp(1, 16384).toInt();
    final contentRowCount = rows.isEmpty ? 1 : rows.length;
    final columnCount = contentColumnCount < 80 ? 80 : contentColumnCount;
    final rowCount = contentRowCount < 120 ? 120 : contentRowCount;
    final lastColumn = _columnName(columnCount - 1);
    final contentLastColumn = _columnName(contentColumnCount - 1);
    final widths = _columnWidths(rows, columnCount);
    final rowXml = <String>[];

    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final rowNumber = rowIndex + 1;
      final cells = <String>[];
      final syntheticRow = rowIndex >= rows.length;
      final row = syntheticRow ? const <String>[] : rows[rowIndex];
      for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
        final hasCell = columnIndex < row.length;
        final value = hasCell ? row[columnIndex] : '';
        final normalized = syntheticRow || !hasCell
            ? ''
            : _cellText(sheet, rowIndex, value);
        final ref = '${_columnName(columnIndex)}$rowNumber';
        final style = _cellStyle(sheet, rowIndex, synthetic: syntheticRow);
        final styleAttribute = style == 0 ? '' : ' s="$style"';
        cells.add(
          '<c r="$ref"$styleAttribute t="inlineStr"><is><t>${_xml(normalized)}</t></is></c>',
        );
      }
      final height = _rowHeight(sheet, rowIndex);
      rowXml.add('<row r="$rowNumber"$height>${cells.join()}</row>');
    }

    final views = _sheetViews(sheet);
    final merges = _mergeCells(sheet, lastColumn);
    final autoFilter = sheet.autoFilterRow == null
        ? ''
        : '<autoFilter ref="A${sheet.autoFilterRow! + 1}:$contentLastColumn$contentRowCount"/>';

    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <dimension ref="A1:$lastColumn$rowCount"/>
  $views
  <sheetFormatPr defaultRowHeight="18"/>
  <cols>${List.generate(widths.length, (index) => '<col min="${index + 1}" max="${index + 1}" width="${widths[index].toStringAsFixed(1)}" customWidth="1"/>').join()}</cols>
  <sheetData>${rowXml.join()}</sheetData>
  $autoFilter
  $merges
  <pageMargins left="0.45" right="0.45" top="0.6" bottom="0.6" header="0.3" footer="0.3"/>
</worksheet>
''';
  }

  String _sheetViews(_XlsxSheet sheet) {
    final rtl = sheet.rightToLeft ? ' rightToLeft="1"' : '';
    if (sheet.freezeRows <= 0) {
      return '<sheetViews><sheetView workbookViewId="0"$rtl/></sheetViews>';
    }
    final topLeft = 'A${sheet.freezeRows + 1}';
    return '<sheetViews><sheetView workbookViewId="0"$rtl><pane ySplit="${sheet.freezeRows}" topLeftCell="$topLeft" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>';
  }

  String _mergeCells(_XlsxSheet sheet, String lastColumn) {
    if (!sheet.mergeTitleRows) {
      return '';
    }
    final refs = <String>[];
    for (final rowIndex in [...sheet.titleRows, ...sheet.subtitleRows]) {
      refs.add('<mergeCell ref="A${rowIndex + 1}:$lastColumn${rowIndex + 1}"/>');
    }
    if (refs.isEmpty) {
      return '';
    }
    return '<mergeCells count="${refs.length}">${refs.join()}</mergeCells>';
  }

  int _cellStyle(_XlsxSheet sheet, int rowIndex, {bool synthetic = false}) {
    if (synthetic) return 8;
    if (sheet.titleRows.contains(rowIndex)) return 1;
    if (sheet.subtitleRows.contains(rowIndex)) return 2;
    if (sheet.headerRows.contains(rowIndex)) return 3;
    if (rowIndex >= (sheet.dataStartRow ?? 999999)) {
      return rowIndex.isEven ? 6 : 5;
    }
    if (rowIndex > 3) return 8;
    return 0;
  }

  String _rowHeight(_XlsxSheet sheet, int rowIndex) {
    if (sheet.titleRows.contains(rowIndex)) {
      return ' ht="28" customHeight="1"';
    }
    if (sheet.subtitleRows.contains(rowIndex)) {
      return ' ht="22" customHeight="1"';
    }
    if (sheet.headerRows.contains(rowIndex)) {
      return ' ht="24" customHeight="1"';
    }
    return '';
  }

  String _cellText(_XlsxSheet sheet, int rowIndex, String value) {
    final text = value.trim();
    if (rowIndex >= (sheet.dataStartRow ?? 999999) && text.isEmpty) {
      return '-';
    }
    return value;
  }

  int _columnCount(List<List<String>> rows) {
    if (rows.isEmpty) return 1;
    return rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
  }

  List<double> _columnWidths(List<List<String>> rows, int count) {
    return List.generate(count, (index) {
      var width = 13.0;
      for (final row in rows.skip(3).take(120)) {
        if (index < row.length) {
          final value = row[index].replaceAll(RegExp(r'\s+'), ' ').trim();
          final length = value.length.toDouble();
          if (length > width) width = length;
        }
      }
      return (width + 3).clamp(14.0, 42.0);
    });
  }

  String _columnName(int index) {
    var value = index + 1;
    final chars = <String>[];
    while (value > 0) {
      final remainder = (value - 1) % 26;
      chars.insert(0, String.fromCharCode(65 + remainder));
      value = (value - remainder - 1) ~/ 26;
    }
    return chars.join();
  }

  String _fileName(ExportRequest request, DateTime generatedAt) {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(generatedAt);
    return 'masar_${request.module.name}_${_scopeSlug(request)}_$stamp.xlsx';
  }

  String _scopeSlug(ExportRequest request) {
    return switch (request.actor.role.name) {
      'admin' => 'company',
      'manager' => 'team',
      'salesAgent' || 'marketing' => 'mine',
      _ => 'restricted',
    };
  }

  String _moduleLabel(ExportRequest request) {
    return _label(request, 'module.${request.module.name}');
  }

  String _scopeLabel(ExportRequest request) {
    return switch (request.actor.role.name) {
      'admin' => _label(request, 'scope.companyWide'),
      'manager' => _label(request, 'scope.myTeam'),
      'salesAgent' || 'marketing' => _label(request, 'scope.myRecords'),
      _ => _label(request, 'scope.restricted'),
    };
  }

  String _dateRangeLabel(ExportRequest request) {
    return _label(request, 'dateRange.${request.filters.dateRange.name}');
  }

  String _filtersSummary(ExportRequest request) {
    final parts = <String>[
      _dateRangeLabel(request),
      if (request.filters.status.trim().isNotEmpty)
        '${_label(request, 'status')}: ${_statusFilterLabel(request)}',
      if (request.filters.assigneeId.trim().isNotEmpty)
        '${_label(request, 'assignedTo')}: ${_label(request, 'selectedAssignee')}',
      if (request.filters.includeArchived) _label(request, 'includeArchived'),
    ];
    return parts.join(' | ');
  }

  String _label(ExportRequest request, String key) => request.labels[key] ?? key;

  String _statusFilterLabel(ExportRequest request) {
    final status = request.filters.status.trim();
    if (status.isEmpty) {
      return '';
    }
    final key = switch (request.module) {
      ExportModule.leads => status == 'new'
          ? 'leadStatus.newLead'
          : 'leadStatus.$status',
      ExportModule.deals || ExportModule.pipeline => status == 'new'
          ? 'dealStage.newDeal'
          : 'dealStage.$status',
      ExportModule.tasks => 'taskStatus.$status',
      ExportModule.appointments => 'appointmentStatus.$status',
      ExportModule.properties => 'propertyStatus.$status',
      _ => '',
    };
    return key.isEmpty ? status : _label(request, key);
  }

  String _safeSheetName(String value) {
    final clean = value.replaceAll(RegExp(r'[\[\]\:\*\?\/\\]'), ' ').trim();
    if (clean.isEmpty) return 'Sheet';
    return clean.length > 31 ? clean.substring(0, 31) : clean;
  }

  String _xml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _XlsxSheet {
  const _XlsxSheet({
    required this.name,
    required this.rows,
    this.rightToLeft = false,
    this.titleRows = const <int>{},
    this.subtitleRows = const <int>{},
    this.headerRows = const <int>{},
    this.dataStartRow,
    this.freezeRows = 0,
    this.autoFilterRow,
    this.mergeTitleRows = false,
  });

  final String name;
  final List<List<String>> rows;
  final bool rightToLeft;
  final Set<int> titleRows;
  final Set<int> subtitleRows;
  final Set<int> headerRows;
  final int? dataStartRow;
  final int freezeRows;
  final int? autoFilterRow;
  final bool mergeTitleRows;
}
