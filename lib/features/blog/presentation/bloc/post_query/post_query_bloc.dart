import 'dart:async';

import 'package:blog_app/features/blog/domain/entities/post_entity.dart';
import 'package:blog_app/features/blog/domain/repositories/post_query_repository.dart';
import 'package:blog_app/features/blog/presentation/bloc/post_query/post_query_event.dart';
import 'package:blog_app/features/blog/presentation/bloc/post_query/post_query_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostQueryBloc extends Bloc<PostQueryEvent, PostQueryState> {
  final PostQueryRepository postQueryRepository;

  static const int _pageSize = 10;
  List<PostEntity> _allPosts = [];
  String? _currentCategory;
  bool _hasMore = true;
  bool _isSearching = false;
  StreamSubscription? _postUpdatesSubscription;
  StreamSubscription? _profileUpdatesSubscription;

  PostQueryBloc({required this.postQueryRepository})
    : super(PostQueryInitial()) {
    on<GetPostsEvent>(_onGetPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
    on<GetMyPostsEvent>(_onGetMyPosts);
    on<SearchPostsEvent>(_onSearchPosts);
    on<RefreshPostsEvent>(_onRefreshPosts);
    on<PostPublishedEvent>(_onPostPublished);
    on<PostDeletedEvent>(_onPostDeleted);
    on<PostUpdatedEvent>(_onPostUpdated);
    on<ProfileUpdatedEvent>(_onProfileUpdated);
  }

  Future<void> _onGetPosts(
    GetPostsEvent event,
    Emitter<PostQueryState> emit,
  ) async {
    emit(PostQueryLoading());
    _allPosts = [];
    _isSearching = false;
    _currentCategory = event.category;
    final result = await postQueryRepository.getPosts(
      rangeFrom: 0,
      rangeTo: _pageSize - 1,
      category: _currentCategory,
    );
    result.fold((failure) => emit(PostQueryError(failure.message)), (posts) {
      _allPosts = posts;
      _hasMore = posts.length >= _pageSize;
      emit(PostsLoaded(posts: _allPosts, hasMore: _hasMore));
    });
    _startLiveFeed();
  }

  Future<void> _onLoadMorePosts(
    LoadMorePostsEvent event,
    Emitter<PostQueryState> emit,
  ) async {
    final rangeFrom = _allPosts.length;
    final rangeTo = rangeFrom + _pageSize - 1;
    final result = await postQueryRepository.getPosts(
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
      category: _currentCategory,
    );
    result.fold((failure) => emit(PostQueryError(failure.message)), (posts) {
      final known = _allPosts.map((p) => p.id).toSet();
      _allPosts = [..._allPosts, ...posts.where((p) => !known.contains(p.id))];
      _hasMore = posts.length >= _pageSize;
      emit(PostsLoaded(posts: _allPosts, hasMore: _hasMore));
    });
  }

  Future<void> _onGetMyPosts(
    GetMyPostsEvent event,
    Emitter<PostQueryState> emit,
  ) async {
    emit(PostQueryLoading());
    final result = await postQueryRepository.getMyPosts(
      userId: event.userId,
      category: event.category,
    );
    result.fold(
      (failure) => emit(PostQueryError(failure.message)),
      (posts) => emit(PostsLoaded(posts: posts, hasMore: false)),
    );
  }

  Future<void> _onSearchPosts(
    SearchPostsEvent event,
    Emitter<PostQueryState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const GetPostsEvent());
      return;
    }
    _isSearching = true;
    emit(PostQueryLoading());
    final result = await postQueryRepository.searchPosts(query: event.query);
    result.fold(
      (failure) => emit(PostQueryError(failure.message)),
      (posts) => emit(PostsLoaded(posts: posts, hasMore: false)),
    );
  }

  Future<void> _onRefreshPosts(
    RefreshPostsEvent event,
    Emitter<PostQueryState> emit,
  ) async {
    try {
      final result = await postQueryRepository.getPosts(
        rangeFrom: 0,
        rangeTo: _pageSize - 1,
        category: _currentCategory,
      );
      result.fold((failure) => emit(PostQueryError(failure.message)), (fetched) {
        final current = state;
        final shown = current is PostsLoaded ? current.posts : _allPosts;
        final fresh = {for (final p in fetched) p.id: p};
        final pageIsFull = fetched.length >= _pageSize;
        final oldestFetched = fetched.isEmpty
            ? null
            : fetched.map((p) => p.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);

        // A shown post is gone only if the fetched page should have contained it.
        bool coveredByPage(PostEntity p) =>
            !pageIsFull || (oldestFetched != null && !p.createdAt.isBefore(oldestFetched));

        final kept = <PostEntity>[
          for (final p in shown)
            if (fresh.containsKey(p.id))
              fresh[p.id]!.withAuthor(fresh[p.id]!.author ?? p.author)
            else if (!coveredByPage(p))
              p,
        ];
        final shownIds = shown.map((p) => p.id).toSet();
        final added = fetched.where((p) => !shownIds.contains(p.id));

        _allPosts = [...kept, ...added];
        if (shown.isEmpty) _hasMore = pageIsFull;
        emit(PostsLoaded(posts: _allPosts, hasMore: _hasMore));
      });
    } finally {
      event.completer?.complete();
    }
  }

  void _onPostDeleted(PostDeletedEvent event, Emitter<PostQueryState> emit) {
    final current = state;
    _allPosts = _allPosts.where((p) => p.id != event.postId).toList();
    if (current is! PostsLoaded) return;
    emit(PostsLoaded(
      posts: current.posts.where((p) => p.id != event.postId).toList(),
      hasMore: current.hasMore,
      isAddingPost: current.isAddingPost,
    ));
  }
  void _startLiveFeed() {
    // Subscribe once; re-subscribing on every reload would race on channel names.
    if (_postUpdatesSubscription != null) return;
    _postUpdatesSubscription = postQueryRepository.watchPostUpdates().listen((either) {
      either.fold((_) => null, (post) => add(PostUpdatedEvent(post)));
    });
    _profileUpdatesSubscription = postQueryRepository.watchProfileUpdates().listen((either) {
      either.fold((_) => null, (profile) => add(ProfileUpdatedEvent(profile)));
    });
  }

  Future<void> _onPostPublished(
    PostPublishedEvent event,
    Emitter<PostQueryState> emit,
  ) async {
    final current = state;
    if (current is! PostsLoaded) return;
    emit(PostsLoaded(posts: current.posts, hasMore: current.hasMore, isAddingPost: true));
    final result = await postQueryRepository.getPostById(event.postId);
    final latest = state is PostsLoaded ? state as PostsLoaded : current;
    result.fold(
      (_) => emit(PostsLoaded(posts: latest.posts, hasMore: latest.hasMore)),
      (post) {
        final exists = latest.posts.any((p) => p.id == post.id);
        _allPosts = exists ? _allPosts : [..._allPosts, post];
        emit(PostsLoaded(
          posts: exists ? latest.posts : [...latest.posts, post],
          hasMore: latest.hasMore,
        ));
      },
    );
  }
  void _onPostUpdated(PostUpdatedEvent event, Emitter<PostQueryState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    if (!current.posts.any((p) => p.id == event.post.id)) return;
    PostEntity merge(PostEntity p) => p.id == event.post.id ? p.applyUpdate(event.post) : p;
    _allPosts = _allPosts.map(merge).toList();
    emit(PostsLoaded(posts: current.posts.map(merge).toList(), hasMore: current.hasMore, isAddingPost: current.isAddingPost));
  }

  void _onProfileUpdated(ProfileUpdatedEvent event, Emitter<PostQueryState> emit) {
    final current = state;
    if (current is! PostsLoaded) return;
    if (!current.posts.any((p) => p.authorId == event.profile.id)) return;
    PostEntity merge(PostEntity p) => p.authorId == event.profile.id ? p.withAuthor(event.profile) : p;
    _allPosts = _allPosts.map(merge).toList();
    emit(PostsLoaded(posts: current.posts.map(merge).toList(), hasMore: current.hasMore, isAddingPost: current.isAddingPost));
  }
  @override
  Future<void> close() {
    _postUpdatesSubscription?.cancel();
    _profileUpdatesSubscription?.cancel();
    return super.close();
  }
}
