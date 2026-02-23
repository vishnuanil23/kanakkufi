import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../profile/domain/profile_entity.dart';
import '../../profile/domain/profile_repository.dart';
import 'profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(String userId) async {
    try {
      final profile = await remote.getProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    required String fullName,
  }) async {
    try {
      await remote.updateProfile(userId: userId, fullName: fullName);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
