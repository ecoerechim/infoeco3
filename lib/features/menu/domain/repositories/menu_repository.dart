import '../../../../user_profile_service.dart';
import '../entities/cooperative_option.dart';

abstract class MenuRepository {
  Future<UserProfileInfo> loadUserProfile();

  Future<List<CooperativeOption>> loadCooperatives(String prefeituraUid);

  Future<void> signOut();
}
