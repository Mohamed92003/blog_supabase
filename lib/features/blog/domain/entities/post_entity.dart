import 'package:blog_app/features/blog/domain/entities/profile_entity.dart';
import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String authorId;
  final ProfileEntity? author;
  final String? category;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostEntity({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorId,
    this.author,
    this.category,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns this post with scalar fields taken from [update], keeping the cached [author].
  PostEntity applyUpdate(PostEntity update) => PostEntity(
    id: id,
    title: update.title,
    content: update.content,
    imageUrl: update.imageUrl,
    authorId: authorId,
    author: author,
    category: update.category,
    viewCount: update.viewCount,
    createdAt: createdAt,
    updatedAt: update.updatedAt,
  );

  PostEntity withAuthor(ProfileEntity? newAuthor) => PostEntity(
    id: id,
    title: title,
    content: content,
    imageUrl: imageUrl,
    authorId: authorId,
    author: newAuthor,
    category: category,
    viewCount: viewCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [id, title, content, imageUrl, authorId, author, category, viewCount, createdAt, updatedAt];
}
