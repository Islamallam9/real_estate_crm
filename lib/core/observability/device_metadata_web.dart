Map<String, String> platformDeviceMetadataImpl() {
  // Keep web metadata intentionally conservative. Some Flutter Web hot-restart
  // sessions can expose a disposed/stale browser interop object; observability
  // must never crash the app while collecting optional device data.
  return const {'userAgent': ''};
}
