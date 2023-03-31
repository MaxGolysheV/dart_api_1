import 'package:conduit/conduit.dart';

import 'package:dart_application_1/models/author.dart';

class Post extends ManagedObject<_Post> implements _Post{}

class _Post{
int? id;
String? content;

@Relate(#postList,isRequired: true, onDelete: DeleteRule.cascade)
 Author? author;

}