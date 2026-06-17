class MDnsClient {
  Future<void> start() async {}
  void stop() {}
  Stream<dynamic> lookup<T>(dynamic query) => const Stream.empty();
}

class PtrResourceRecord {
  final String domainName = '';
}

class SrvResourceRecord {
  final String target = '';
  final int port = 0;
}

class IPAddressResourceRecord {
  final Address address = Address();
}

class Address {
  final String address = '';
}

class ResourceRecordQuery {
  static dynamic serverPointer(String name) {}
  static dynamic service(String name) {}
  static dynamic addressIPv4(String name) {}
}
