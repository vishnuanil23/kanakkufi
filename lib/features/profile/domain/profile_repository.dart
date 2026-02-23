import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import 'profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile(String userId);
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    required String fullName,
  });
}
