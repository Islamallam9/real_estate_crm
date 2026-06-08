import 'browser_title_updater_stub.dart'
    if (dart.library.html) 'browser_title_updater_web.dart' as implementation;

void setBrowserTitle(String title) {
  implementation.setBrowserTitle(title);
}
