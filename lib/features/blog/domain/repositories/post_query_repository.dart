import 'package:blog_app/core/error/failures.dart';
import 'package:blog_app/features/blog/domain/entities/post_entity.dart';
import 'package:blog_app/features/blog/domain/entities/profile_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PostQueryRepository {
  Future<Either<Failure, List<PostEntity>>> getPosts({
    int? rangeFrom,
    int? rangeTo,
    String? category,
  });

  Future<Either<Failure, List<PostEntity>>> getMyPosts({
    required String userId,
    String? category,
  });

  Future<Either<Failure, List<PostEntity>>> searchPosts({
    required String query,
  });

  Future<Either<Failure, PostEntity>> getPostById(String id);

  Stream<Either<Failure, PostEntity>> watchNewPosts();

  Stream<Either<Failure, PostEntity>> watchPostUpdates();

  Stream<Either<Failure, ProfileEntity>> watchProfileUpdates();
}
