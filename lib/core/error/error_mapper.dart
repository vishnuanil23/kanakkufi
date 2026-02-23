import '../error/failures.dart';

class ErrorMapper {
  static String mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Error: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Please check your internet connection';
    } else if (failure is CacheFailure) {
      return 'Data unavailable offline';
    }
    return 'Unexpected Error';
  }
}
