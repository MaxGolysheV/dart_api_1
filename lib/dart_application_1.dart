import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:dart_application_1/controller/app_auth_controller.dart';
import 'package:dart_application_1/controller/app_token_controller.dart';
import 'package:dart_application_1/controller/app_user_controller.dart';

import 'package:dart_application_1/models/user.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext _managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();
    _managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('post/[:id]')
    ..route('token/[:refresh]').link(
      () => AppAuthController(_managedContext),
    )
    ..route('user')
        .link(AppTokenController.new)!
        .link(() => AppUSerController(_managedContext));



  PersistentStore _initDatabase() {
    final username =
        Platform.environment['DB_USERNAME'] ?? 'postgres'; //свой юзер
    final password = Platform.environment['DB_PASSWORD'] ?? '1'; //свой пароль
    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'postgres';

    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
