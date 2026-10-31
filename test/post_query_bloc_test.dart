import 'dart:async';

import 'package:blog_app/core/error/failures.dart';
import 'package:blog_app/features/blog/domain/entities/post_entity.dart';
import 'package:blog_app/features/blog/domain/entities/profile_entity.dart';
import 'package:blog_app/features/blog/domain/repositories/post_query_repository.dart';
import 'package:blog_app/features/blog/presentation/bloc/post_query/post_query_bloc.dart';
import 'package:blog_app/features/blog/presentation/bloc/post_query/post_query_event.dart';
import 'package:blog_app/features/blog/presentation/bloc/post_query/post_query_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

PostEntity _post(String id, {String author = 'a1', String? category, int views = 0}) => PostEntity(
  id: id,
  title: 't$id',
  content: 'c',
  authorId: author,
  category: category,
  viewCount: views,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeRepo implements PostQueryRepository {
  final newPosts = StreamController<Either<Failure, PostEntity>>.broadcast();
  final updates = StreamController<Either<Failure, PostEntity>>.broadcast();
  final profiles = StreamController<Either<Failure, ProfileEntity>>.broadcast();
  List<PostEntity> initial = [];
  PostEntity? byId;

  @override
  Future<Either<Failure, PostEntity>> getPostById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return byId == null ? Left(ServerFailure('nf')) : Right(byId!);
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getPosts({int? rangeFrom, int? rangeTo, String? category}) async =>
      Right(initial);

  @override
  Future<Either<Failure, List<PostEntity>>> getMyPosts({required String userId, String? category}) async =>
      Right(initial);

  @override
  Future<Either<Failure, List<PostEntity>>> searchPosts({required String query}) async => Right(initial);

  @override
  Stream<Either<Failure, PostEntity>> watchNewPosts() => newPosts.stream;

  @override
  Stream<Either<Failure, PostEntity>> watchPostUpdates() => updates.stream;

  @override
  Stream<Either<Failure, ProfileEntity>> watchProfileUpdates() => profiles.stream;
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _FakeRepo repo;
  late PostQueryBloc bloc;

  setUp(() async {
    repo = _FakeRepo()..initial = [_post('1', views: 1)];
    bloc = PostQueryBloc(postQueryRepository: repo)..add(const GetPostsEvent());
    await _pump();
  });

  tearDown(() => bloc.close());

  test('realtime insert is ignored (no post pushed to the top)', () async {
    repo.newPosts.add(Right(_post('2')));
    await _pump();
    expect((bloc.state as PostsLoaded).posts.map((p) => p.id), ['1']);
  });

  test('published post shows spinner then is appended last', () async {
    repo.byId = _post('2');
    bloc.add(const PostPublishedEvent('2'));
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as PostsLoaded).isAddingPost, true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = bloc.state as PostsLoaded;
    expect(state.isAddingPost, false);
    expect(state.posts.map((p) => p.id), ['1', '2']);
  });

  test('published post failure clears spinner', () async {
    bloc.add(const PostPublishedEvent('x'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = bloc.state as PostsLoaded;
    expect(state.isAddingPost, false);
    expect(state.posts.length, 1);
  });
  test('post update merges view count but keeps author', () async {
    final author = ProfileEntity(id: 'a1', name: 'N', createdAt: DateTime(2026));
    repo.profiles.add(Right(author));
    await _pump();
    repo.updates.add(Right(_post('1', views: 5)));
    await _pump();
    final post = (bloc.state as PostsLoaded).posts.single;
    expect(post.viewCount, 5);
    expect(post.author, author);
  });

  test('profile update rewrites the author avatar on matching posts', () async {
    final profile = ProfileEntity(id: 'a1', avatarUrl: 'http://x/new.png', createdAt: DateTime(2026));
    repo.profiles.add(Right(profile));
    await _pump();
    expect((bloc.state as PostsLoaded).posts.single.author?.avatarUrl, 'http://x/new.png');
  });

  group('refresh / delete', () {
    test('refresh keeps order and appends unseen posts last', () async {
      repo.initial = [_post('1', views: 1), _post('0')];
      bloc.add(const GetPostsEvent());
      await _pump();
      repo.initial = [_post('9'), _post('1', views: 7), _post('0')];
      bloc.add(const RefreshPostsEvent());
      await _pump();
      final state = bloc.state as PostsLoaded;
      expect(state.posts.map((p) => p.id), ['1', '0', '9']);
      expect(state.posts.first.viewCount, 7);
    });

    test('refresh drops posts deleted on the server', () async {
      repo.initial = [_post('1'), _post('0')];
      bloc.add(const GetPostsEvent());
      await _pump();
      repo.initial = [_post('1')];
      bloc.add(const RefreshPostsEvent());
      await _pump();
      expect((bloc.state as PostsLoaded).posts.map((p) => p.id), ['1']);
    });

    test('refresh completes its completer', () async {
      final completer = Completer<void>();
      bloc.add(RefreshPostsEvent(completer: completer));
      await completer.future.timeout(const Duration(seconds: 1));
    });

    test('PostDeletedEvent removes the post', () async {
      bloc.add(const PostDeletedEvent('1'));
      await _pump();
      expect((bloc.state as PostsLoaded).posts, isEmpty);
    });
  });}
