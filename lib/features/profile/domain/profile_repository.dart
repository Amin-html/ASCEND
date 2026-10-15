import 'package:ascend/features/profile/domain/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<UserProfile> watch();
}