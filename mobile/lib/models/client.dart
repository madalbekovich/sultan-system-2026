class Client {
  Client({
    required this.id,
    this.tgUserId,
    required this.name,
    this.phone,
    this.address,
  });

  final int id;
  final int? tgUserId;
  final String name;
  final String? phone;
  final String? address;

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as int,
        tgUserId: json['tg_user_id'] as int?,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
}
