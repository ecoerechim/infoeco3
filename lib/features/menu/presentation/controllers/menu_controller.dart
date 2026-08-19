import 'package:flutter/foundation.dart';

import '../../domain/entities/cooperative_option.dart';
import '../../domain/repositories/menu_repository.dart';
import '../states/menu_state.dart';

class MenuController extends ChangeNotifier {
  MenuController(this._repository);

  final MenuRepository _repository;
  MenuState _state = const MenuState();

  MenuState get state => _state;

  Future<void> loadProfile() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final profile = await _repository.loadUserProfile();
      _state = _state.copyWith(profile: profile, isLoading: false);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
    notifyListeners();
  }

  Future<List<CooperativeOption>> loadCooperatives(String prefeituraUid) {
    return _repository.loadCooperatives(prefeituraUid);
  }

  Future<void> signOut() {
    return _repository.signOut();
  }
}
