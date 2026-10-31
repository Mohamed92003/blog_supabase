import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/post_entity.dart';
import '../../../domain/entities/profile_entity.dart';

abstract class PostQueryEvent extends Equatable {
  const PostQueryEvent();

  @override
  List<Object?> get props => [];
}

class GetPostsEvent extends PostQueryEvent {
  final String? category;

  const GetPostsEvent({this.category});

  @override
  List<Object?> get props => [category];
}

class LoadMorePostsEvent extends PostQueryEvent {
  const LoadMorePostsEvent();
}

class GetMyPostsEvent extends PostQueryEvent {
  final String userId;
  final String? category;

  const GetMyPostsEvent({required this.userId, this.category});

  @override
  List<Object?> get props => [userId, category];
}

class SearchPostsEvent extends PostQueryEvent {
  final String query;

  const SearchPostsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshPostsEvent extends PostQueryEvent {
  /// Completed when the refresh finishes, so a RefreshIndicator can await it.
  final Completer<void>? completer;

  const RefreshPostsEvent({this.completer});
}

class PostDeletedEvent extends PostQueryEvent {
  final String postId;

  const PostDeletedEvent(this.postId);

  @override
  List<Object> get props => [postId];
}

class PostPublishedEvent extends PostQueryEvent {
  final String postId;

  const PostPublishedEvent(this.postId);

  @override
  List<Object> get props => [postId];
}

class PostUpdatedEvent extends PostQueryEvent {
  final PostEntity post;

  const PostUpdatedEvent(this.post);

  @override
  List<Object> get props => [post];
}

class ProfileUpdatedEvent extends PostQueryEvent {
  final ProfileEntity profile;

  const ProfileUpdatedEvent(this.profile);

  @override
  List<Object> get props => [profile];
}
