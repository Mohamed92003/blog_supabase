import 'package:blog_app/core/error/exceptions.dart';
import 'package:blog_app/core/error/failures.dart';
import 'package:blog_app/features/blog/data/datasources/post_query_datasource.dart';
import 'package:blog_app/features/blog/domain/entities/post_entity.dart';
import 'package:blog_app/features/blog/domain/repositories/post_query_repository.dart';
import 'package:blog_app/features/blog/domain/entities/profile_entity.dart';
import 'package:dartz/dartz.dart';

class PostQueryRepositoryImpl implements PostQueryRepository {
  final PostQueryDataSource postQueryDataSource;

  PostQueryRepositoryImpl({required this.postQueryDataSource});

  @override
  Future<Either<Failure, List<PostEntity>>> getPosts({
    int? rangeFrom,
    int? rangeTo,
    String? category,
  }) async {
    try {
      final posts = await postQueryDataSource.getPosts(
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
        category: category,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getMyPosts({
    required String userId,
    String? category,
  }) async {
    try {
      final posts = await postQueryDataSource.getMyPosts(
        userId: userId,
        category: category,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> searchPosts({
    required String query,
  }) async {
    try {
      final posts = await postQueryDataSource.searchPosts(query: query);
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> getPostById(String id) async {
    try {
      return Right(await postQueryDataSource.getPostById(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, PostEntity>> watchNewPosts() {
    return postQueryDataSource.watchNewPosts().map<Either<Failure, PostEntity>>((post) => Right(post)).handleError((
        error,
        ) {
      if (error is ServerException) {
        return Left(ServerFailure(error.message));
      } else {
        return Left(ServerFailure('Unexpected error: ${error.toString()}'));
      }
    });
  }

  Either<Failure, T> _toFailure<T>(Object error) {
    if (error is ServerException) return Left(ServerFailure(error.message));
    return Left(ServerFailure('Unexpected error: ${error.toString()}'));
  }

  @override
  Stream<Either<Failure, PostEntity>> watchPostUpdates() {
    return postQueryDataSource
        .watchPostUpdates()
        .map<Either<Failure, PostEntity>>((post) => Right(post))
        .handleError((error) => _toFailure<PostEntity>(error));
  }

  @override
  Stream<Either<Failure, ProfileEntity>> watchProfileUpdates() {
    return postQueryDataSource
        .watchProfileUpdates()
        .map<Either<Failure, ProfileEntity>>((profile) => Right(profile))
        .handleError((error) => _toFailure<ProfileEntity>(error));
  }
}
