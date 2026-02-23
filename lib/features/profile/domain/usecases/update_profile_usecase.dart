import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../profile_repository.dart';

class UpdateProfileUseCase implements UseCase<void, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      userId: params.userId,
      fullName: params.fullName,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String userId;
  final String fullName;

  const UpdateProfileParams({required this.userId, required this.fullName});

  @override
  List<Object?> get props => [userId, fullName];
}
