class Client {
  Client({
    required this.id,
    required this.clientCode,
    this.tgUserId,
    required this.name,
    this.phone,
    this.address,
    required this.isArchived,
    required this.isBound,
  });

  final int id;
  final String clientCode;
  final int? tgUserId;
  final String name;
  final String? phone;
  final String? address;
  final bool isArchived;
  final bool isBound;

  Client copyWith({bool? isArchived, bool? isBound}) => Client(
        id: id,
        clientCode: clientCode,
        tgUserId: tgUserId,
        name: name,
        phone: phone,
        address: address,
        isArchived: isArchived ?? this.isArchived,
        isBound: isBound ?? this.isBound,
      );

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as int,
        clientCode: json['client_code'] as String,
        tgUserId: json['tg_user_id'] as int?,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isArchived: json['is_archived'] as bool,
        isBound: json['is_bound'] as bool,
      );
}
