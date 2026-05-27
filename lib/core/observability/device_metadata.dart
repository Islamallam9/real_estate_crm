import 'device_metadata_stub.dart'
    if (dart.library.html) 'device_metadata_web.dart';

Map<String, String> platformDeviceMetadata() {
  return platformDeviceMetadataImpl();
}
