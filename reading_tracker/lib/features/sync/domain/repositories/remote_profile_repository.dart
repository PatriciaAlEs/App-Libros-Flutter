import '../entities/remote_profile.dart';

abstract interface class RemoteProfileRepository {
  Future<RemoteProfile?> getProfile(String userId);
  Future<RemoteProfile> upsertProfile(RemoteProfile profile);
  Future<void> deleteProfile(String userId);
}
