import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_application_1/models/model_response.dart';
import 'package:dart_application_1/models/post.dart';
import 'package:dart_application_1/models/author.dart';
import 'package:dart_application_1/utils/app_response.dart';
import 'package:dart_application_1/utils/app_utils.dart';

class AppPostController extends ResourceController {
  AppPostController(this.managedContext);
  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> createPost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() Post post) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final author = await managedContext.fetchObjectWithID<Author>(id);
      if (author == null) {
        final qCreateAuthor = Query<Author>(managedContext)..values.id = id;
        await qCreateAuthor.insert();
      }

      final qCreatePost = Query<Post>(managedContext)
        ..values.author!.id = id
        ..values.content = post.content;

      await qCreatePost.insert();
      return AppResponse.ok(message: 'Пост добавлен');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка создания поста');
    }
  }

  @Operation.get()
  Future<Response> getPosts(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qCreatePost = Query<Post>(managedContext)
        ..where((x) => x.author!.id).equalTo(id);
      final List<Post> list = await qCreatePost.fetch();
      if (list.isEmpty) {
        return Response.notFound(
            body: ModelResponse(data: [], message: 'Постов нет'));
      }
      return Response.ok(list);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка вывода постов');
    }
  }

  @Operation.get('id')
  Future<Response> getPost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path('id') int id) async 
  {
    try 
    {
      final curremtAuthorId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.ok(message: 'Пост не найден');
      }
      if (post.author?.id != curremtAuthorId) {
        return AppResponse.ok(message: 'Нет доступа к посту');
      }
      post.backing.removeProperty('author');
      return AppResponse.ok(body: post.backing.contents, message: 'Пост создан');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка создания поста');
    }
  }

  @Operation.put("id")
  Future<Response> updatePost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("id") int id,
      @Bind.body() Post bodyPost) async {
    try {
      final currentAuthorId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);

      if (post == null) {
        return AppResponse.ok(message: 'Пост не найден');
      }
      if (post.author!.id != currentAuthorId) {
        return AppResponse.ok(message: 'Нет доступа к посту');
      }
      final qUpdatePost = Query<Post>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.content = bodyPost.content;
      await qUpdatePost.update();
      return AppResponse.ok(message: 'Пост обновлен');
    } catch (e) {
      return AppResponse.serverError(e, message: "Пост не обновлен");
    }
  }

  @Operation.delete("id")
  Future<Response> deletePost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("id") int id) async {
    try {
      final currentAuthorId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);

      if (post == null) {
        return AppResponse.ok(message: 'Пост не найден');
      }
      if (post.author!.id != currentAuthorId) {
        return AppResponse.ok(message: 'Нет доступа к посту');
      }

      final qDeletePost = Query<Post>(managedContext)
        ..where((x) => x.id).equalTo(id);
      await qDeletePost.delete();
      return AppResponse.ok(message: "Пост удален");
    } catch (e) {
      return AppResponse.serverError(e, message: "Ошибка удаления поста");
    }
  }


}
