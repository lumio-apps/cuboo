import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const String kGithubOwner = 'lumio-apps';
const String kGithubRepo = 'cuboo';

class UpdateInfo {
  UpdateInfo({
    required this.version,
    required this.notes,
    required this.downloadUrl,
    required this.pageUrl,
  });

  final String version;
  final String notes;

  /// The APK of the release.
  final String downloadUrl;

  /// The release page on GitHub.
  final String pageUrl;
}

/// Looks for a newer release on GitHub, only when the user taps
/// "Check for updates". Nothing is checked in the background and nothing
/// about the user or the phone is sent.
class UpdateChecker {
  /// Returns the newest release if it is newer than the installed app and
  /// has an APK, or null when the app is up to date.
  static Future<UpdateInfo?> check() async {
    final info = await PackageInfo.fromPlatform();
    final uri = Uri.https(
      'api.github.com',
      '/repos/$kGithubOwner/$kGithubRepo/releases/latest',
    );
    final res = await http
        .get(uri, headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 404) return null; // no release published yet
    if (res.statusCode != 200) {
      throw HttpException('GitHub returned ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
    if (!isNewer(tag, info.version)) return null;

    final assets =
        (json['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final apk = assets.firstWhere(
      (a) => (a['name'] as String).toLowerCase().endsWith('.apk'),
      orElse: () => <String, dynamic>{},
    );
    final url = apk['browser_download_url'] as String?;
    if (url == null) return null;

    return UpdateInfo(
      version: tag,
      notes: (json['body'] as String?)?.trim() ?? '',
      downloadUrl: url,
      pageUrl: json['html_url'] as String? ??
          'https://github.com/$kGithubOwner/$kGithubRepo/releases/latest',
    );
  }

  /// Downloads the APK (reporting progress 0..1) and opens the installer.
  static Future<void> downloadAndInstall(
    UpdateInfo update,
    void Function(double progress) onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cuboo-${update.version}.apk');

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(update.downloadUrl));
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw HttpException('Download failed (${res.statusCode})');
      }
      final total = res.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.close();
    } finally {
      client.close();
    }

    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  /// True when [remote] (for example "1.2.0") is newer than [local]
  /// (for example "1.1.0+5").
  static bool isNewer(String remote, String local) {
    List<int> parse(String v) {
      final core = v.split('+').first.split('-').first;
      return core
          .split('.')
          .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
    }

    final a = parse(remote);
    final b = parse(local);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
