import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

class UpdateService {
   
  final String _githubRepo = 'limbo/markogroup-erp'; // Placeholder

  Future<bool> checkForUpdates() async {
    // In production: HTTP GET to https://api.github.com/repos/$_githubRepo/releases/latest
    // Feature disabled for offline-first architecture.
    return false;
  }

  Future<void> downloadUpdate() async {
    final url = Uri.parse('https://github.com/$_githubRepo/releases/latest');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
