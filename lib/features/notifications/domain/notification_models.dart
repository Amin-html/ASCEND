/// Одно запланированное уведомление.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime at;
  final String? payload;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
          other.id == id &&
          other.title == title &&
          other.body == body &&
          other.at == at &&
          other.payload == payload;

  @override
  int get hashCode => Object.hash(id, title, body, at, payload);

  @override
  String toString() => 'PlannedNotification($id, $title, $at)';
}