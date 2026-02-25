import '../../domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.avatarUrl,
  });

  factory UserModel.fromSupabaseUser(sb.User user) {
    final meta = user.userMetadata ?? {};
    final name = meta['full_name'] ??
        meta['name'] ??
        user.email?.split('@').first ??
        'User';
    final avatar = meta['avatar_url'] ?? meta['picture'] ?? '';
    
    return UserModel(
      id: user.id,
      name: name,
      email: user.email ?? '',
      avatarUrl: avatar,
    );
  }
}
