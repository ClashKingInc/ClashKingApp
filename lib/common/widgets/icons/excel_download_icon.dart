import 'dart:io';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:open_filex/open_filex.dart';

class DownloadCwlExcelButton extends StatefulWidget {
  final String url;
  final String fileName;

  const DownloadCwlExcelButton({super.key, required this.url, required this.fileName});

  @override
  State<DownloadCwlExcelButton> createState() => _DownloadCwlExcelButtonState();
}

class _DownloadCwlExcelButtonState extends State<DownloadCwlExcelButton> {
  bool _isDownloading = false;

  Future<void> downloadExcel(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final dioClient = Dio();

    setState(() => _isDownloading = true);

    try {
      final response = await dioClient.get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data!;
      final filename = widget.fileName;

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final urlBlob = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: urlBlob)
          ..setAttribute("download", filename)
          ..click();
        html.Url.revokeObjectUrl(urlBlob);
      } else {
        final dir = Platform.isAndroid || Platform.isIOS
            ? await getExternalStorageDirectory()
            : await getDownloadsDirectory();

        final filePath = '${dir!.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.downloadSuccess(filePath))),
          );
          try{
            await OpenFilex.open(filePath);
          } catch (e) {
            DebugUtils.debugError(' Error opening file : $e');
          }
        }
      }
    } catch (e) {
      DebugUtils.debugError(' Error downloading file : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.downloadError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return _isDownloading
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : IconButton(
            icon: const Icon(Icons.download),
            tooltip: loc.downloadTooltip,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.downloadInProgress)),
              );
              downloadExcel(context);
            },
          );
  }
}
