import 'package:blog_app/features/blog/data/models/post_model.dart';
import 'package:blog_app/features/blog/data/models/profile_model.dart';

abstract class PostQueryDataSource {
  Future<List<PostModel>> getPosts({int? rangeFrom, int? rangeTo , String? category});

  Future<List<PostModel>> getMyPosts({required String userId, String? category});

  Future<List<PostModel>> searchPosts({required String query});

  Future<PostModel> getPostById(String id);

  Stream<PostModel> watchNewPosts();

  /// Emits raw updated post rows (no joined author).
  Stream<PostModel> watchPostUpdates();

  Stream<ProfileModel> watchProfileUpdates();
}
