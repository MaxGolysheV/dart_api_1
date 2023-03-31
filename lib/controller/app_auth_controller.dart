import 'dart:async';

import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:dart_application_1/models/model_response.dart';
import 'package:dart_application_1/models/user.dart';
import 'package:dart_application_1/utils/app_response.dart';
import 'package:dart_application_1/utils/app_utils.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppAuthController extends ResourceController {
  AppAuthController(this.managedContext);
  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.username == null) {
      return Response.badRequest(
          body: ModelResponse(message: 'Поля password username обязательны'));
    }
    try {
      // Поиск пользователя по имени в базе данных
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.username).equalTo(user.username)
        ..returningProperties(
          (element) => [
            element.id,
            element.salt,
            element.hashPassword,
          ],
        );
//получаем первый эдемент из поиска
      final findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.input('Пользователь не найден', []);
      }
//генерация хэша пароля для дальнейшей проверки
      final requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');
//Проверка пароля
      if (requestHashPassword == findUser.hashPassword) {
// Обновления token пароля
        _updateTokens(findUser.id ?? -1, managedContext);
//Получаем данные пользователя
        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);
        return Response.ok(ModelResponse(
          data: newUser!.backing.contents,
          message: 'Успешная авторизация',
        ));
      } else {
        throw QueryException.input('Hе верный пароль', []);
      }
    } on QueryException catch (e) {
      return Response.serverError(body: ModelResponse(message: e.message));
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.username == null || user.email == null) {
      return Response.badRequest(
          body: ModelResponse(message: "Поля password username обязательны"));
    }
    //генерация соли
    final salt = generateRandomSalt();
    //генерация хеща пароля
    final hashPassword = generatePasswordHash(user.password!, salt);

    try {
      late final id;

      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();
        id = createdUser.id!;
        _updateTokens(id, transaction);
      });

      final userData = await managedContext.fetchObjectWithID<User>(id);
      return AppResponse.ok(
          body: userData!.backing.contents,
          message: 'Пользователь успешно зарегистрирован');
    } catch (e) {
      return AppResponse.serverError(e); //
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);
      if (user!.refreshToken != refreshToken) {
        return Response.unauthorized(body: 'Невалидный токен');
      }
      _updateTokens(id, managedContext);
      return Response.ok(
        ModelResponse(
          data: user.backing.contents,
          message: 'Токен обновлен',
        ),
      );
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  void _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, String> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((element) => element.id).equalTo(id)
      ..values.accesToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTokens.updateOne();
  }

  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';

    final accessCleimSet = JwtClaim(
      maxAge: const Duration(hours: 1),
      otherClaims: {'id': id},
    );

    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessCleimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);

    return tokens;
  }
}
