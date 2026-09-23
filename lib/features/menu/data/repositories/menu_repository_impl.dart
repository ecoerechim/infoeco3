import '../../../../user_profile_service.dart';
import '../../domain/entities/cooperative_option.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_firebase_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._datasource);

  final MenuFirebaseDatasource _datasource;

  @override
  Future<UserProfileInfo> loadUserProfile() {
    return _datasource.loadUserProfile();
  }

  @override
  Future<List<CooperativeOption>> loadCooperatives(String prefeituraUid) {
    return _datasource.loadCooperatives(prefeituraUid);
  }

  @override
  Future<void> signOut() {
    return _datasource.signOut();
  }
}
