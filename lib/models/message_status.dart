import 'package:hive/hive.dart';

part 'message_status.g.dart';

@HiveType(typeId: 1)
enum MessageStatus {
  @HiveField(0)
  sending,

  @HiveField(1)
  sent,

  @HiveField(2)
  error,
}
