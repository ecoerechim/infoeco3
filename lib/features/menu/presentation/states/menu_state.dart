import '../../../../user_profile_service.dart';

class MenuState {
  final UserProfileInfo? profile;
  final bool isLoading;
  final String? errorMessage;

  const MenuState({
    this.profile,
    this.isLoading = true,
    this.errorMessage,
  });

  MenuState copyWith({
    UserProfileInfo? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MenuState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
